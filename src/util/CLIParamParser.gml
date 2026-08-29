///@package io.alkapivo.core.util
show_debug_message("init CLIParamParser.gml")


///@param {Struct} json
function CLIParam(json) constructor {

  ///@type {String}
  name = Assert.isType(json.name, String)

  ///@type {?String}
  fullName = Struct.contains(json, "fullName") 
    ? Assert.isType(json.fullName, String) 
    : null

  ///@type {?String}
  description = Struct.contains(json, "description") 
    ? Assert.isType(json.description, String) 
    : null

  ///@type {Array<CLIParamArg>}
  args = Core.isType(Struct.get(json, "args"), GMArray)
    ? GMArray.toArray(json.args, Struct, function(arg) {
      return new CLIParamArg(arg)
    })
    : new Array(Struct)

  ///@type {Callable}
  handler = Assert.isType(method(this, json.handler), Callable)

  ///@param {String} [intend]
  ///@return {CLIParam}
  print = function(intend = "") {
    var descriptionText = this.description == null ? "" : $": {this.description}"
    Core.print($"{intend}{this.name}, {this.fullName}{descriptionText}")
    this.args.forEach(function(arg, idx, intend) { 
      arg.print($"{intend}argument[{idx}] ")
    }, $"{intend}  ")
    return this
  }
}


///@param {Struct} json
function CLIParamArg(json) constructor {
  
  ///@type {String}
  name = Assert.isType(json.name, String)

  ///@type {String}
  type = Assert.isType(json.type, String)

  ///@type {?String}
  description = Struct.contains(json, "description") 
    ? Assert.isType(json.description, String) 
    : null

  ///@param {String} [intend]
  ///@return {CLIParamArg}
  print = function(intend = "") {
    var descriptionText = this.description == null ? "" : $": {this.description}"
    Core.print($"{intend}{this.name}<{this.type}>{descriptionText}")
    return this
  }
}

///@param {Struct} json
function CLIParamParser(json) constructor {

  ///@type {Boolean}
  parsed = false

  ///@type {Array<CLIParam>}
  cliParams = Assert.isType(json.cliParams, Array)

  ///@private
  ///@type {Queue<String>} params
  ///@throws {Exception}
  dispatchParam = function(params) {
    Logger.debug("CLIParamParser", $"DispatchParam, total: {params.size()}")
    if (params.size() == 0) {
      return
    }
  
    var param = params.pop()
    var cliParam = this.cliParams.find(function(cliParam, index, param) {
      return param == cliParam.name || param == cliParam.fullName
    }, param)
  
    if (!Core.isType(cliParam, CLIParam)) {
      Logger.warn("CLIParamParser", $"Cannot parse parameter '{param}'")
      this.dispatchParam(params)
      return
    }
  
    if (cliParam.args.size() > params.size()) {
      throw new Exception($"param '{cliParam.fullName}' require '{cliParam.args.size()}' options while '{params.size()} were provided'")
    }
  
    var args = IntStream.map(0, cliParam.args.size(), function(num, idx, params) {
      return params.pop()
    }, params)

    var argsText = args.join(" ")
    Logger.debug("CLIParamParser", $"Run {cliParam.fullName} {argsText}")
    cliParam.handler(args)
  
    this.dispatchParam(params)
  }

  ///@param {Boolean} [ignoreAlreadyParsed]
  ///@return {CLIParamParser}
  parse = function(ignoreAlreadyParsed = false) {
    if (!ignoreAlreadyParsed && this.parsed) {
      Logger.debug("CLIParamParser", "CLIParamParser.parse already parsed")
      return this
    }

    var count = parameter_count()
    var params = new Queue(any)
    Logger.debug("CLIParamParser", $"Parameters count: {count}")
    for (var index = 1; index < count; index++) {
      var param = parameter_string(index)
      if (!String.isEmpty(param)) {
        params.push(param)
        Logger.debug("CLIParamParser", $"{index} Adding param: '{param}'")
      }
    }
    Logger.debug("CLIParamParser", $"Parameters parsed: {params.size()}")

    this.dispatchParam(params)
    this.parsed = true
    return this
  }

  ///@param {String} [intend]
  ///@return {CLIParamParser}
  print = function(intend = "") {
    if (this.cliParams.size() == 0) {
      return this
    }

    Core.print($"{intend}Available CLIParams:")
    Core.print($"{intend}  -output: Write logs to file\n{intend}    argument[0] file<String> File name")
    this.cliParams.forEach(function(cliParam, idx, intend) {
      cliParam.print(intend)
    }, $"{intend}  ")
    Core.print("")

    return this
  }
}
