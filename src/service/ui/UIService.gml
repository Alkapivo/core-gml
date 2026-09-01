///@package io.alkapivo.core.service.ui
show_debug_message("init UIService.gml")


///@param {?Struct} [config]
function UIService(config = null): Service(config) constructor {

  ///@type {Array<UI>}
  containers = new Array(UI).enableGC(true)

  ///@private
  ///@param {Event} event
  ///@param {EventPump} dispatcher
  mouseEventPump = function(event) {
    for (var index = this.containers.size() - 1; index >= 0; index--) {
      var container = this.containers.get(index)
      if (container.enable && container.dispatch(event)) {
        break
      }
    }
  }

  ///@private
  ///@param {String} name
  ///@param {Number} _x
  ///@param {Number} _y
  ///@param {EventPump} dispatcher
  mouseEventHandler = function(name, _x, _y) {
    var size = this.containers.size()
    for (var index = size - 1; index >= 0; index--) {
      var container = this.containers.get(index)
      if (container.enable && container.dispatchHandler(name, _x, _y)) {
        break
      }
    }
  }

  ///@private
  ///@param {String} name
  removeContainers = function(name) {
    var size = this.containers.size()
    for (var idx = 0; idx < size; idx++) {
      var container = this.containers.get(idx)
      if (container.name == name) {
        containers.addToGC(idx)
        container.free()
        delete container
      }
    }
    this.containers.runGC()
  }

  ///@private
  ///@type {EventPump}
  dispatcher = new EventPump(this, new Map(String, Callable, {
    "add": function(event) {
      var container = Assert.isType(Struct.get(event.data, "container"), UI)
      if (Struct.getDefault(event.data, "replace", true)) {
        this.removeContainers(container.name)
      }
      
      this.containers.add(container)
    },
    "remove": function(event) {
      static removeHandler = function(context, data) {
        context.removeContainers(Assert.isType(Struct.get(data, "name"), String))
      }

      if (Struct.getDefault(event.data, "quiet", false)) {
        try {
          removeHandler(this, event.data)
        } catch (exception) {
          Logger.error("UIService", $"'remove' fatal error: {exception.message}")
          Core.printStackTrace().printException(exception)
        }
      } else {
        removeHandler(this, event.data)
      }
    },
    "MouseHoverOver": mouseEventPump,
    "MouseOnLeft": mouseEventPump,
    "MouseOnRight": mouseEventPump,
    "MousePressedLeft": mouseEventPump,
    "MousePressedRight": mouseEventPump,
    "MouseReleasedLeft": mouseEventPump,
    "MouseReleasedRight": mouseEventPump,
    "MouseDragLeft": mouseEventPump,
    "MouseDropLeft": mouseEventPump,
    "MouseDragRight": mouseEventPump,
    "MouseDropRight": mouseEventPump,
    "MouseWheelUp": mouseEventPump,
    "MouseWheelDown": mouseEventPump,
  }))

  ///@param {String} name
  ///@param {?Callable} [callback]
  ///@return {?UI}
  find = function(name, callback = null) {
    static findContainer = function(container, key, name) {
      return container.name == name
    }

    return this.containers.find((callback != null ? callback : findContainer), name)
  }
  
  ///@param {Event} event
  ///@return {?Promise}
  send = function(event) {
    return this.dispatcher.send(event)
  }

  ///@return {UIService}
  update = function() {
    static updateContainer = function(container) {
      if (!container.enable) {
        return
      }
      container.update()
    }

    this.containers.forEach(updateContainer)
    this.dispatcher.update()
    this.containers.runGC()
    return this
  }

  ///@return {UIService} 
  render = function() {
    static renderContainer = function(container) {
      if (container.enable) {
        container.render()
      }
    }
    
    this.containers.forEach(renderContainer)
    return this
  }

  free = function() {
    this.containers.forEach(function(container) {
      container.free()
    })
  }

  if (Struct.contains(config, "containers")) {
    GMArray.forEach(Struct.get(config, "containers"), function(json, index, service) {
      service.send(new Event("AddContainer", new UI(json)))
    }, this)
  }
}
