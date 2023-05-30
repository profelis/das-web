options indenting = 2
options strict_smart_pointers
module agent_server_boost shared

require strings

require daslib/ast_boost
require daslib/json

let
  genFnPrefix = "`gen`"


[export, tag_function(send_request_fn), unused_argument(method, params, fn, ctx)]
def send_request(method : string; var params : JsonValue?; var fn : function; var ctx : Context) : void {}


[tag_function(send_request_fn), unused_argument(method, params, fn)]
def send_request(method : string; var params : JsonValue?; var fn : function) : void {}


[tag_function_macro(tag="send_request_fn")]
class SendRequestFn : AstFunctionAnnotation
  [unused_argument(errors)] def override transform(var expr : smart_ptr<ExprCallFunc>; var errors : das_string) : ExpressionPtr
    var inscope exprClone <- clone_expression(expr)
    var newCall = exprClone as ExprCallFunc
    newCall.name := "{newCall.name}_typed"
    var success = false
    for arg in newCall.arguments
      if arg is ExprAddr
        var exprAddr = unsafe(reinterpret<ExprAddr?> arg)
        if !string(exprAddr.target) |> starts_with(genFnPrefix)
          let newName = "{genFnPrefix}{exprAddr.target}"
          var inscope fn <- compiling_module() |> find_unique_function(newName)
          if fn == null
            compiling_program() |> macro_error(newCall.at, "can't find <{newName}> function, annotate function\n[rpc_handler]\ndef {exprAddr.target}...")
            return <- [[ExpressionPtr]]
          else
            exprAddr.target := newName
            success = true
    if success
      return <- exprClone
    return <- [[ExpressionPtr]]
