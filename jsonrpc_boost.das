options indenting = 2
module jsonrpc_boost shared

require daslib/ast_boost
require jsonrpc_boost_common

require jsonrpc_handler public
require jsonrpc_args public


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
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
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
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !transform_args(func, /*is_call*/false, errors)
      return false
    astChanged = true
    keep_args(func)
    return true


[function_macro(name="rpc_handler")]
class RpcHandlerAnnotation : AstFunctionAnnotation
  [unused_argument(group,args,progArgs)] def override patch ( var func:FunctionPtr; var group:ModuleGroup; args,progArgs:AnnotationArgumentList; var errors : das_string; var astChanged:bool& ) : bool
    if length(func.arguments) > 0 && func.arguments[0].name == paramsName
      return true // already patched
    if !validate_req_id_arg(func.arguments, errors)
      return false
    if !transform_args(func, /*is_call*/true, errors)
      return false
    astChanged = true
    keep_args(func)
    return true
