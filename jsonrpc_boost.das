options indenting = 2
module jsonrpc_boost shared

require ast
require strings
require debugapi public

require daslib/ast_boost
require daslib/templates_boost
require jsonrpc_boost_common
require agent_jsonrpc_boost

require jsonrpc_handler public
require jsonrpc_args public


[function_macro(name="rpc_call_raw")]
class RpcCallRawAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false

    keep_func_and_args(func)
    add_call_reg_func(func.at, func.name, nameArg as tString)
    return true


[function_macro(name="rpc_notification_raw")]
class RpcNotificationRawAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false

    keep_func_and_args(func)
    add_notification_reg_func(func.at, func.name, nameArg as tString)
    return true


[function_macro(name="rpc_call")]
class RpcCallAnnotation : AstFunctionAnnotation
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


[function_macro(name="rpc_notification")]
class RpcNotificationAnnotation : AstFunctionAnnotation
  [unused_argument(group)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    let nameArg = find_arg(args, "name")
    if !validate_name_annotation(nameArg, errors)
      return false
    if !transform_args(func, /*is_call*/false, errors)
      return false
    keep_args(func)
    add_notification_reg_func(func.at, "{genFnPrefix}{func.name}", nameArg as tString)
    return true


[function_macro(name="rpc_handler")]
class RpcHandlerAnnotation : AstFunctionAnnotation
  [unused_argument(group, args)] def override apply(var func : FunctionPtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    keep_args(func)
    return true
