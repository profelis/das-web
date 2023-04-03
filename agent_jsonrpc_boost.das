options indenting = 2
module agent_jsonrpc_boost shared

require debugapi public

require daslib/ast_boost
require daslib/templates_boost
require jsonrpc_boost_common

require agent_server public
require jsonrpc_handler public
require jsonrpc_args public
require agent_server_boost public

def private add_call_reg_func(at; call_fn_name; call_fn_alias)
  let fn_name = "register_{call_fn_name}_{call_fn_alias}"
  var fn <- new [[Function() at = at, atDecl = at, name := fn_name]]
  fn.flags |= FunctionFlags generated
  fn.flags |= FunctionFlags privateFunction
  fn.flags |= FunctionFlags init
  fn.moreFlags |= MoreFunctionFlags lateInit
  fn.result <- new [[TypeDecl() baseType=Type autoinfer, at=at]]

  var qblock <- quote() <|
    if not_in_web_context()
      add_call(func_name, func)

  var rules : Template
  rules |> replaceVariable("func_name") <| new [[ExprConstString() at = at, value := call_fn_alias]]
  rules |> replaceVariable("func") <| new [[ExprAddr() at = at, target := call_fn_name, funcType := typeinfo(ast_typedecl type<function<(var params: JsonValue?; id: uint64): void>>)]]
  apply_template(rules, at, qblock)
  delete rules
  unsafe
    var blk <- move_unquote_block(qblock)
    blk.blockFlags ^= ExprBlockFlags isClosure
    fn.body <- blk

  compiling_module() |> add_function(fn)

def private add_notification_reg_func(at; call_fn_name; call_fn_alias)
  let fn_name = "register_{call_fn_name}_{call_fn_alias}"
  var fn <- new [[Function() at = at, atDecl = at, name := fn_name]]
  fn.flags |= FunctionFlags generated
  fn.flags |= FunctionFlags privateFunction
  fn.flags |= FunctionFlags init
  fn.moreFlags |= MoreFunctionFlags lateInit
  fn.result <- new [[TypeDecl() baseType=Type autoinfer, at=at]]

  var qblock <- quote() <|
    if not_in_web_context()
      add_notification(func_name, func)

  var rules : Template
  rules |> replaceVariable("func_name") <| new [[ExprConstString() at = at, value := call_fn_alias]]
  rules |> replaceVariable("func") <| new [[ExprAddr() at = at, target := call_fn_name, funcType := typeinfo(ast_typedecl type<function<(var params: JsonValue?): void>>)]]
  apply_template(rules, at, qblock)
  delete rules
  unsafe
    var blk <- move_unquote_block(qblock)
    blk.blockFlags ^= ExprBlockFlags isClosure
    fn.body <- blk

  compiling_module() |> add_function(fn)


def private validate_name_annotation(name_arg; var errors: das_string): bool
  if name_arg is nothing
    errors := "name is not defined"
    return false
  if !(name_arg is tString)
    errors := "name should be string value"
    return false
  return true


[function_macro(name="auto_rpc_call_raw")]
class AutoRpcCallRawAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func: FunctionPtr; var group: ModuleGroup; args: AnnotationArgumentList; var errors: das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false

    keep_func_and_args(func)
    add_call_reg_func(func.at, func.name, nameArg as tString)
    return true


[function_macro(name="auto_rpc_notification_raw")]
class AutoRpcNotificationRawAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func: FunctionPtr; var group: ModuleGroup; args: AnnotationArgumentList; var errors: das_string): bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false

    keep_func_and_args(func)
    add_notification_reg_func(func.at, func.name, nameArg as tString)
    return true


[function_macro(name="auto_rpc_call")]
class AutoRpcCallAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override patch(var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool&): bool
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
      return true // already patched
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    astChanged = true
    keep_args(func)
    add_call_reg_func(func.at, "{func.name}", nameArg as tString)
    return true


[function_macro(name="auto_rpc_notification")]
class AutoRpcNotificationAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override patch(var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool&): bool
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
      return true // already patched
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false
    if !transform_args(func, /*is_call*/false, errors)
      return false
    astChanged = true
    keep_args(func)
    add_notification_reg_func(func.at, "{func.name}", nameArg as tString)
    return true


[function_macro(name="auto_rpc_handler")]
class AutoRpcHandlerAnnotation : AstFunctionAnnotation
  [unused_argument(group,args)] def override patch(var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool&): bool
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    astChanged = true
    keep_args(func)
    return true
