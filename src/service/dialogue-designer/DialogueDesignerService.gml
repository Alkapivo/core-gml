///@package io.alkapivo.core.service.dialogue-designer

///@type {String}
#macro BeanDialogueDesignerService "DialogueDesignerService"

///@param {?Struct} [config]
function DialogueDesignerService(config = null): Service(config) constructor {

  ///@type {Map<String, String>}
  templates = new Map(String, String)

  ///@type {?DDDialogue}
  dialog = null

  ///@type {Map<String, Boolean>}
  facts = new Map(String, Boolean)

  ///@type {Map<String, Callable>}
  handlers = Core.isType(Struct.get(config, "handlers"), Map)
    ? config.handlers
    : new Map(String, Callable)

  ///@param {?DDCondition} condition
  ///@return {DialogueDesignerService}
  conditionHandler = method(this, Struct.getIfType(config, "conditionHandler", Callable) == null
    ? function(condition) {
      Assert.isType(this.dialog, DDDialogue, "DialogueDesignerService::dialog must be type of DDDialogue")
      Assert.isType(condition, DDCondition, "DialogueDesignerService::conditionHandler(condition) condition must be type of DDCondition")

      var next = this.facts.get(condition.statement) ? condition.onTrue : condition.onFalse
      var node = Assert.isType(this.dialog.get(next), DDNode, "DialogueDesignerService::conditionHandler(condition) next must be type of DDNode")
      this.dialog.current = node

      return this
    }
    : Struct.get(config, "conditionHandler"))

  ///@param {String} name
  ///@return {DialogueDesignerService}
  open = function(name) {
    var template = templates.get(name)
    if (Core.isType(template, String)) {
      this.dialog = new DDDialogue(JSON.parse(template))
    }
    return this
  }

  ///@return {DialogueDesignerService}
  close = function() {
    this.dialog = null
    return this
  }

  ///@return {DialogueDesignerService}
  update = function() {
    if (Core.isType(this.dialog, DDDialogue)) {
      this.dialog.update(this.handlers, this.conditionHandler)
    }
    
    return this
  }
}