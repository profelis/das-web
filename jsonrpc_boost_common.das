options indenting = 2
module jsonrpc_boost_common shared

require daslib/ast_boost


let paramsName = "__params__"


[macro_function]
def keep_args(var func)
  for arg in func.arguments
    arg.flags |= VariableFlags marked_used


[macro_function]
def keep_func_and_args(var func)
  func.flags |= FunctionFlags exports
  keep_args(func)


[macro_function]
def validate_req_id_arg(arguments; var errors: das_string)
  let argsNum = arguments.length
  if argsNum < 1
    errors := "at least one argument with request id is required (req_id: uint64)"
    return false
  if arguments[argsNum - 1]._type.baseType != Type tUInt64
    errors := "the last argument should be of uint64 type (req_id: uint64)"
    return false
  return true


[macro_function]
def transform_args(var fn; is_call; var errors: das_string): bool
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
