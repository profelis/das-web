options indenting = 2
options no_unused_function_arguments = false
module agent_server_boost shared

require strings

require daslib/ast_boost
require daslib/json
require agent_server public


[export,tag_function(send_request_fn)]
def send_request(method: string; var params: JsonValue?; var fn: function; var ctx: Context): bool
  unsafe
    return send_request_typed(method, params, reinterpret<function<(var params: JsonValue?; id: uint64): void>> fn, ctx)


[export,tag_function(send_request_fn)]
def send_request(method: string; var params: JsonValue?; var fn: function): bool
  unsafe
    return send_request_typed(method, params, reinterpret<function<(var params: JsonValue?; id: uint64): void>> fn, this_context())


[tag_function_macro(tag="send_request_fn")]
class SendRequestFn : AstFunctionAnnotation
  def override transform(var expr: smart_ptr<ExprCallFunc>; var errors: das_string): ExpressionPtr
    var calledFuncName = "n/a"
    for arg in expr.arguments
      if arg is ExprAddr
        unsafe
          var exprAddr = reinterpret<ExprAddr?> arg
          calledFuncName = "{exprAddr.target}"
          var fn <- compiling_module() |> find_unique_function(calledFuncName)
          if fn == null
            compiling_program() |> macro_error(expr.at, "can't find <{exprAddr.target}> function, annotate function\n[rpc_handler]\ndef {exprAddr.target}...")
            return [[ExpressionPtr]]

          for ann in fn.annotations
            if ann.annotation.name == "auto_rpc_handler" || ann.annotation.name == "rpc_handler"
              return [[ExpressionPtr]]

    compiling_program() |> macro_error(expr.at, "called function <{calledFuncName}> without annotation. Annotate function with [auto_rpc_handler]")
    return [[ExpressionPtr]]
