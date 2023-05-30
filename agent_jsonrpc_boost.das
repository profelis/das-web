options indenting = 2
options strict_smart_pointers
module agent_jsonrpc_boost shared

require debugapi public

require daslib/ast_boost
require daslib/templates_boost
require jsonrpc_boost_common

require agent_server public
require jsonrpc_handler public
require jsonrpc_args public
require agent_server_boost public

[macro_function]
def add_call_reg_func(at; call_fn_name; call_fn_alias)
  let fn_name = "register_{call_fn_name}_{call_fn_alias}"
  var inscope fn <- new [[Function() at = at, atDecl = at, name := fn_name]]
  fn.flags |= FunctionFlags generated
  fn.flags |= FunctionFlags privateFunction
  fn.flags |= FunctionFlags init
  fn.moreFlags |= MoreFunctionFlags lateInit
  fn.result |> move_new() <| new [[TypeDecl() baseType=Type autoinfer, at=at]]

  var inscope qblock <- quote() <|
    unsafe
      lock_debug_agent() <| $()
        start_agent()
        if not_in_web_context()
          add_call(func_name, func, this_context())

  var inscope rules : Template
  rules |> replaceVariable("func_name") <| new [[ExprConstString() at = at, value := call_fn_alias]]
  rules |> replaceVariable("func") <| new [[ExprAddr() at = at, target := call_fn_name, funcType := typeinfo(ast_typedecl type<function<(var params: JsonValue?; id: uint64): void>>)]]
  apply_template(rules, at, qblock)
  unsafe
    var blk <- move_unquote_block(qblock)
    blk.blockFlags ^= ExprBlockFlags isClosure
    fn.body <- blk

  compiling_module() |> add_function(fn)

[macro_function]
def add_notification_reg_func(at; call_fn_name; call_fn_alias)
  let fn_name = "register_{call_fn_name}_{call_fn_alias}"
  var inscope fn <- new [[Function() at = at, atDecl = at, name := fn_name]]
  fn.flags |= FunctionFlags generated
  fn.flags |= FunctionFlags privateFunction
  fn.flags |= FunctionFlags init
  fn.moreFlags |= MoreFunctionFlags lateInit
  fn.result |> move_new() <| new [[TypeDecl() baseType=Type autoinfer, at=at]]

  var inscope qblock <- quote() <|
    unsafe
      lock_debug_agent() <| $()
        start_agent()
        if not_in_web_context()
          add_notification(func_name, func, this_context())

  var inscope rules : Template
  rules |> replaceVariable("func_name") <| new [[ExprConstString() at = at, value := call_fn_alias]]
  rules |> replaceVariable("func") <| new [[ExprAddr() at = at, target := call_fn_name, funcType := typeinfo(ast_typedecl type<function<(var params: JsonValue?): void>>)]]
  apply_template(rules, at, qblock)
  unsafe
    var blk <- move_unquote_block(qblock)
    blk.blockFlags ^= ExprBlockFlags isClosure
    fn.body <- blk

  compiling_module() |> add_function(fn)


[macro_function]
def validate_name_annotation(name_arg; var errors : das_string) : bool
  if name_arg is nothing
    errors := "name is not defined"
    return false
  if !(name_arg is tString)
    errors := "name should be string value"
    return false
  if empty(name_arg as tString)
    errors := "name string is empty"
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
  [unused_argument(group)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    keep_args(func)
    add_call_reg_func(func.at, "{genFnPrefix}{func.name}", nameArg as tString)
    return true


[function_macro(name="auto_rpc_notification")]
class AutoRpcNotificationAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false
    if !transform_args(func, /*is_call*/false, errors)
      return false
    keep_args(func)
    add_notification_reg_func(func.at, "{genFnPrefix}{func.name}", nameArg as tString)
    return true


[function_macro(name="auto_rpc_handler")]
class AutoRpcHandlerAnnotation : AstFunctionAnnotation
  [unused_argument(group, args)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    keep_args(func)
    return true
