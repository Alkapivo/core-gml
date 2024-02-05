///@package io.alkapivo.core.service.ui

///@param {Struct} _context
///@parms {Struct} [config]
function UIService(_context, config = {}): Service(config) constructor {

  ///@type {Struct}
  context = Assert.isType(_context, Struct)

  ///@type {Array<UI>}
  containers = new Array(UI)

  ///@private
  ///@param {Event} event
  ///@param {EventPump} dispatcher
  mouseEventPump = function(event) {
    this.containers.forEach(function(container, index, event) {
      try {
        if (container.enable && container.dispatch(event)) {
          return BREAK_LOOP
        }
      } catch (exception) {
        Logger.error("UIService", $"Event pump exception: {exception.message}")
      }
    }, event)
  }

  ///@private
  ///@param {String} name
  removeContainers = function(name) {
    var keys = this.containers
      .map(function(container, key, name) {
        var result = container.name == name ? key : null
        if (Optional.is(result)) {
          container.free()
        }
        return result
      }, name)
      .filter(function(key) {
        return Optional.is(key)
      })
    this.containers.removeMany(keys)
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
  ///@return {?UI}
  find = function(name) {
    static findContainer = function(container, key, name) {
      return container.name == name
    }

    return this.containers.find(findContainer, name)
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

    this.dispatcher.update()
    this.containers.forEach(updateContainer)
    return this
  }

  ///@return {UIService} 
  render = function() {
    static renderContainer = function(container) {
      try {
        if (container.enable) {
          container.render()
        }
      } catch (exception) {
        Logger.error("UIService", $"Render exception: {exception.message}")
        GPU.reset.shader() ///@todo remove
        GPU.reset.surface() ///@todo remove
        GPU.reset.blendMode() ///@todo remove
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
