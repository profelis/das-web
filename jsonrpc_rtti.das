options indenting = 4
options remove_unused_symbols = false
module jsonrpc_rtti

require jsonrpc
require rtti
require debugapi

class ScopedRpcCall : RpcCall
    ctx: rtti::Context?
    def ScopedRpcCall()
        unsafe
            ctx = addr(this_context())

class ScopedFunctionRpcCall : ScopedRpcCall
    fn: function<(var params: RpcParams; id: double):void>
    def ScopedFunctionRpcCall(var f: function<(var params: RpcParams; id: double):void>)
        ScopedRpcCall`ScopedRpcCall(self)
        fn <- f

    def override call(var params: RpcParams; id:double): void
        unsafe
            ctx |> invoke_in_context(fn, params, id)


class ScopedFunctionRpcNotification : ScopedRpcCall
    fn: function<(var params: RpcParams):void>
    def ScopedFunctionRpcNotification(var f: function<(var params: RpcParams):void>)
        ScopedRpcCall`ScopedRpcCall(self)
        fn <- f

    [unused_argument(id)] def override call(var params: RpcParams; id:double): void
        unsafe
            ctx |> invoke_in_context(fn, params)