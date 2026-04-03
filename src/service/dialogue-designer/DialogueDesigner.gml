///@package io.alkapivo.core.service.dialogue-designer

///@enum
function _DDNodeType(): Enum() constructor {
  START = "start"
  MESSAGE = "show_message"
  EXECUTE = "execute"
  CONDITION = "condition_branch"
}
global.__DDNodeType = new _DDNodeType()
#macro DDNodeType global.__DDNodeType


///@param {Array} array
function DDDialogue(array) constructor {

  Assert.isType(array, Array, 
    $"DDDialogue(array) must be type of Array.\nRAW: {array}")

  ///@type {Struct}
  var json = Assert.isType(array.getFirst(), Struct,
    $"DDDialogue::json must be type of Struct.\nJSON: {array.getFirst()}")

  ///@type {Array<DDNode>}
  nodes = new Array(DDNode, GMArray.map(Assert.isType(Struct.get(json, "nodes"), GMArray, $"DDDialogue::nodes must be type of Array.\nJSON: {json}"), function(node) {
    var type = Struct.get(node, "node_type")
    switch (type) {
      case DDNodeType.START: return new DDNode(node)
      case DDNodeType.MESSAGE: return new DDMessage(node)
      case DDNodeType.EXECUTE: return new DDExecute(node)
      case DDNodeType.CONDITION: return new DDCondition(node)
      default: throw new Exception($"Unsupported type {type}")
    }
  }))

  ///@param {String} name
  ///@return {?DDNode}
  get = function(name) {
    return this.nodes.find(function(node, index, name) {
      return node.name == name
    }, name)
  }

  ///@type {DDNode}
  current = Assert.isType(this.get(this.nodes.find(function(node) {
    return node.type == DDNodeType.START
  }).next), DDNode)

  ///@return {DDDialogue}
  print = function() {
    Core.print("current", this.current.name, "text", this.current.getText("ENG"))
    return this
  }

  ///@param {?Number} [index]
  ///@return {DDDialogue}
  select = function(index = null) {
    if (Core.isType(index, Number)) {
      if (this.current.type == DDNodeType.MESSAGE
          && index < this.current.choices.size()) {
        var choice = this.current.choices.get(index)
        var node = this.get(choice.next)
        if (Core.isType(node, DDNode)) {
          this.current = node
        } else {
          Logger.error(BeanDialogueDesignerService , $"node does not exists. index: {index}, next: {this.current.next}")
        }
      }
    } else {
      if (this.current.type == DDNodeType.MESSAGE) {
        var node = this.get(this.current.next)
        if (Core.isType(node, DDNode)) {
          this.current = node
        } else {
          Logger.error(BeanDialogueDesignerService , $"node does not exists. index: {index}, next: {this.current.next}")
        }
      }
    }

    return this
  }
  
  ///@param {Map<String, Callable>} handlers
  ///@param {Callable} conditionHandler
  ///@return {DDDialogue}
  update = function(handlers, conditionHandler) {
    switch (this.current.type) {
      case DDNodeType.START:
        var node = this.get(this.current.next)
        if (Core.isType(node, DDNode)) {
          this.current = node
        }
        break
      case DDNodeType.MESSAGE:
        break
      case DDNodeType.EXECUTE:
        var wait = this.current.action.run(handlers)
        if (wait == true) {
          break
        }

        var node = this.get(this.current.next)
        if (Core.isType(node, DDNode)) {
          this.current = node
        }
        break
      case DDNodeType.CONDITION:
        conditionHandler(this.current)
        break
    }  
    
    return this
  }
}


///@param {Struct} json
function DDNode(json) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(json, "node_name"), String,
    $"DDNode::name must be type of String.\nJSON: {json}")

  ///@type {DDNodeType}
  type = Assert.isEnum(Struct.get(json, "node_type"), DDNodeType,
    $"DDNode::name must be type of String.\nJSON: {json}")

  ///@type {?String}
  next = Struct.getIfType(json, "next", String)

  ///@type {String}
  title = Struct.getIfType(json, "title", String, "")

  ///@param {String} lang
  ///@return {String}
  getText = function(lang) {
    var map = Struct.get(this, "text")
    if (!Core.isType(map, Map)) {
      return ""
    }

    var text = map.get(lang)
    return Core.isType(text, String) ? text : ""
  }

  ///@param {String} lang
  ///@return {?Array<String>}
  getChoicesText = function(lang) {
    var choices = Struct.get(this, "choices")
    if (!Core.isType(choices, Array)) {
      return null
    }

    return choices.map(function(choice, index, lang) {
      return choice.getText(lang)
    }, lang, String)
  }
}


///@param {Struct} json
function DDExecute(json): DDNode(json) constructor {

  ///@type {DDAction}
  action = Assert.isType(new DDAction(JSON.parse(Struct.get(json, "text"))), DDAction,
    $"DDExecute::action must be type of DDAction.\nJSON: {json}")
}


///@param {Struct} json
function DDMessage(json): DDNode(json) constructor {

  ///@type {Map<String, String>}
  text = new Map(String, String)
  if (Core.isType(Struct.get(json ,"text"), Struct)) {
    Struct.forEach(json.text, function(label, lang, text) {
      text.set(lang, label)
    }, this.text)
  }

  ///@type {Array<DDChoice>}
  choices = new Array(DDChoice)
  if (Core.isType(Struct.get(json, "choices"), GMArray)) {
    GMArray.forEach(json.choices, function(choice, index, choices) {
      choices.add(new DDChoice(choice))
    }, this.choices)
  }
}


///@param {Struct} json
function DDCondition(json): DDNode(json) constructor {

  ///@type {String}
  statement = Assert.isType(Struct.get(json, "text"), String,
    $"DDCondition::statement must be type of String.\nJSON: {json}")

  ///@type {String}
  onTrue = Assert.isType(Struct.get(Struct.get(json, "branches"), "True"), String,
    $"DDCondition::onTrue must be type of String.\nJSON: {json}")

  ///@type {String}
  onFalse = Assert.isType(Struct.get(Struct.get(json, "branches"), "False"), String,
    $"DDCondition::onFalse must be type of String.\nJSON: {json}")
}

///@param {Struct} json
function DDChoice(json) constructor {

  ///@type {?String}
  condition = Struct.get(json, "is_condition")
    ? Assert.isType(Struct.get(json, "condition"), String,
      $"DDChoice::condition must be type of String.\nJSON: {json}")
    : null

  ///@type {String}
  next = Assert.isType(Struct.get(json, "next"), String,
    $"DDChoice::next must be type of String.\nJSON: {json}")

  ///@type {Map<String, String>}
  text = new Map(String, String)
  if (Core.isType(Struct.get(json, "text"), Struct)) {
    Struct.forEach(json.text, function(label, lang, text) {
      text.set(lang, label)
    }, this.text)
  }

  ///@param {String} lang
  ///@return {String}
  getText = function(lang) {
    var text = this.text.get(lang)
    return Core.isType(text, String) ? text : ""
  }
}


///@param {Struct} json
function DDAction(json) constructor {

  ///@type {String}
  action = Assert.isType(Struct.get(json, "action"), String, 
    $"DDAction::action must be type of String.\nJSON: {json}")

  ///@type {?Struct}
  data = Struct.getIfType(json, "data", Struct, {})

  ///@param {Map<String, Callable>} handlers
  ///@throws {Exception}
  ///@return {?Boolean}
  run = function(handlers) {
    var handler = handlers.get(this.action)
    if (!Core.isType(handler, Callable)) {
      throw new Exception($"Handler for action '{this.action}' was not found")
    }

    return handler(this.data)
  }
}