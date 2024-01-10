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
  ///@param {EventDispatcher} dispatcher
  mouseEventDispatcher = function(event) {
    this.containers.forEach(function(container, index, event) {
      if (container.enable && container.dispatch(event)) {
        return BREAK_LOOP
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
  ///@type {EventDispatcher}
  dispatcher = new EventDispatcher(this, new Map(String, Callable, {
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
    "MouseHoverOver": mouseEventDispatcher,
    "MouseOnLeft": mouseEventDispatcher,
    "MouseOnRight": mouseEventDispatcher,
    "MousePressedLeft": mouseEventDispatcher,
    "MousePressedRight": mouseEventDispatcher,
    "MouseReleasedLeft": mouseEventDispatcher,
    "MouseReleasedRight": mouseEventDispatcher,
    "MouseDragLeft": mouseEventDispatcher,
    "MouseDropLeft": mouseEventDispatcher,
    "MouseDragRight": mouseEventDispatcher,
    "MouseDropRight": mouseEventDispatcher,
    "MouseWheelUp": mouseEventDispatcher,
    "MouseWheelDown": mouseEventDispatcher,
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
      if (!container.enable) 
        || (Core.isType(container.timer, Timer) 
        && container.timer.update().finished == false) {

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
