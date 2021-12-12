options indenting = 2
module jsonrpc_boost shared

require ast
require debugapi public

require daslib/ast_boost
require daslib/templates_boost

require jsonrpc_handler public
require jsonrpc_args public


def private keep_args(var func)
  for arg in func.arguments
    arg.flags |= VariableFlags marked_used

def private keep_func_and_args(var func)
  func.flags |= FunctionFlags exports
  keep_args(func)

def private validate_req_id_arg(arguments; var errors: das_string)
  let argsNum = arguments.length
  if argsNum < 1
    errors := "at least one argument with request id is required (req_id: uint64)"
    return false
  if arguments[argsNum - 1]._type.baseType != Type tUInt64
    errors := "the last argument should be of uint64 type (req_id: uint64)"
    return false
  return true


let private paramsName = "__params__"

def private transform_args(var fn; is_call; var errors: das_string): bool
  let at = fn.at
  var blk: ExprBlock?
  unsafe
    blk = reinterpret<ExprBlock?> fn.body

  let argsNum = fn.arguments.length
  let processArgsNum = argsNum - (is_call ? 1 : 0)
  for i in range(processArgsNum)
    var argi <- new [[ExprCall() at = at, name := "get_arg" ]]
    argi.arguments |> emplace_new(new [[ExprVar() at = at, name := paramsName]])
    argi.arguments |> emplace_new(new [[ExprConstInt() at = at, value = i ]])

    var baseArg & = unsafe(fn.arguments[i])
    var baseArgType & = unsafe(baseArg._type)
    if baseArgType.baseType == Type tInt
      var toValue <- new [[ExprCall() at = at, name := "as_int" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif baseArgType.baseType == Type tUInt
      var toValue <- new [[ExprCall() at = at, name := "as_uint" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif baseArgType.baseType == Type tFloat
      var toValue <- new [[ExprCall() at = at, name := "as_float" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif baseArgType.baseType == Type tDouble
      var toValue <- new [[ExprCall() at = at, name := "as_double" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif baseArgType.baseType == Type tBool
      var toValue <- new [[ExprCall() at = at, name := "as_bool" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif baseArgType.baseType == Type tString
      var toValue <- new [[ExprCall() at = at, name := "as_string" ]]
      toValue.arguments |> emplace(argi)
      argi <- toValue
    elif (baseArgType.baseType == Type tPointer && baseArgType.firstType != null && baseArgType.firstType.baseType == Type tStructure
          && string(baseArgType.firstType.structType.name) == "JsonValue" && string(baseArgType.firstType.structType._module.name) == "json")
      pass // JsonValue
    else
      errors := "{baseArg.name}: {describe(baseArgType)} - unsupported argument type"
      return false

    var vlet <- new [[ExprLet() at = at, atInit = at ]]
    vlet.variables |> emplace_new() <| new [[Variable() at = at,
            name := baseArg.name,
            _type := baseArgType,
            init <- argi
        ]]
    blk.list |> emplace(vlet, i)

  for i in range(processArgsNum) // cleanup all arguments
    fn.arguments |> erase(0)

  var paramsArg <- new [[Variable()
    at = at,
    name := paramsName,
    _type := typeinfo(ast_typedecl type<json::JsonValue? -const>)
  ]]
  fn.arguments |> emplace(paramsArg, 0)

  keep_func_and_args(fn)
  return true


[function_macro(name="rpc_call_raw")]
class RpcCallRawAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,errors)] def override apply(var func: FunctionPtr; var group: ModuleGroup; args: AnnotationArgumentList; var errors: das_string) : bool
    keep_func_and_args(func)
    return true


[function_macro(name="rpc_notification_raw")]
class RpcNotificationRawAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,errors)] def override apply(var func: FunctionPtr; var group: ModuleGroup; args: AnnotationArgumentList; var errors: das_string): bool
    keep_func_and_args(func)
    return true


[function_macro(name="rpc_call")]
class RpcCallAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,progArgs)] def override patch(var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool&): bool
    if func.arguments.length > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    astChanged = true
    keep_args(func)
    return true


[function_macro(name="rpc_notification")]
class RpcNotificationAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,progArgs)] def override patch ( var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool& ) : bool
    if func.arguments.length > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !transform_args(func, /*is_call*/false, errors)
      return false
    astChanged = true
    keep_args(func)
    return true


[function_macro(name="rpc_handler")]
class RpcHandlerAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,progArgs)] def override patch ( var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool& ) : bool
    if func.arguments.length > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    astChanged = true
    keep_args(func)
    return true
