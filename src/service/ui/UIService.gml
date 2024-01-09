///@package io.alkapivo.core.service.ui

///@param {Struct} _context
///@parms {Struct} [config]
function UIService(_context, config = {}): Service(config) constructor {

  ///@type {Struct}
  context = Assert.isType(_context, Struct)

  ///@type {Array<UIContainer>}
  containers = new Array(UIContainer)

  ///@private
  ///@param {Event} event
  ///@param {EventDispatcher} dispatcher
  mouseEventDispatcher = method(this, function(event) {
    this.containers.forEach(function(container, index, event) {
      if (container.enable && container.dispatch(event)) {
        return BREAK_LOOP
      }
    }, event)
  })

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
      var container = Assert.isType(Struct.get(event.data, "container"), UIContainer)
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
  ///@return {?UIContainer}
  find = function(name) {
    static findContainer = function(container, key, name) {
      return container.name == name
    }

    return this.containers.find(findContainer, name)
  }
  
  ///@param {Event} event
  ///@return {?Promise}
  send = method(this, function(event) {
    return this.dispatcher.send(event)
  })

  ///@return {UIService}
  update = method(this, function() {
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
  })

  ///@return {UIService} 
  render = method(this, function() {
    static renderContainer = function(container) {
      if (container.enable) {
        container.render()
      }
    }

    this.containers.forEach(renderContainer)
    return this
  })

  free = function() {
    this.containers.forEach(function(container) {
      container.free()
    })
  }

  if (Struct.contains(config, "containers")) {
    GMArray.forEach(Struct.get(config, "containers"), function(json, index, service) {
      service.send(new Event("AddContainer", new UIContainer(json)))
    }, this)
  }
}


///@static
function _UIUtil() constructor {

  ///@param {Struct} context
  ///@param {String} name
  ///@param {?UIContainer} [container] 
  ///@return {Struct}
  static setUIContainer = function(context, name, container = null) {
    var field = Struct.get(context, name)
    if (Core.isType(field, UIContainer)) {
      field.free()
    }

    Struct.set(context, name, Assert.isType(container, Optional.of(UIContainer)))
    return context
  }

  ///@param {Map<String, ?UIContainer} containers
  ///@param {String} name
  ///@param {?UIContainer} [container]
  ///@return {?UIContainer}
  static setUIContainerInMap = function(containers, name, container = null) {
    var field = containers.get(name)
    if (Core.isType(field, UIContainer)) {
      field.free()
    }

    containers.set(name, container)
    return containers.get(name)
  }

  ///@deprecated
  ///@param {Struct} style
  ///@param {String} name
  ///@param {Struct} appendStyle
  ///@return {Struct}
  static appendStyle = function(style, name, appendStyle) {
    Struct.forEach(appendStyle, function(callable, name, data) {
      if (!Core.isType(callable, Callable)) {
        return
      }
      Struct.set(data.style, name, method(data.context, callable))
    }, { style: appendStyle, context: style })
    Struct.set(style, name, appendStyle)
    return style
  }

  ///@deprecated
  ///@param {Struct} style
  ///@param {?Collection} [styles]
  ///@return {Struct}
  static appendStyles = function(style, styles = null) {
    if (Core.isType(styles, Collection)) {
      styles.forEach(function(appendStyle, name, style) {
        UIUtil.appendStyle(style, name, appendStyle)
      }, style)
    }
    return style
  }

  ///@deprecated
  ///@param {Collection} names
  ///@param {?Callable} [callback]
  ///@return {Map<String, ?UIContainer>}
  static initContainers = function(names, callback = null) {
    var containers = new Map(String, Optional.of(UIContainer))
    names.forEach(function(name, key, data) {
      data.containers.set(data.callback != null ? data.callback(name) : name, null)
    }, { containers: containers, names: names, callback: callback })
    return containers
  }

  templates = new Map(String, Callable, {
    "removeUIItemfromUICollection": function() {
      return function() {
        this.context.collection.remove(this.component.index)
      }
    },
    "scrollable": function() {
      return function() {
        var viewWidth = this.fetchViewWidth()
        this.offsetMax.x = viewWidth >= this.area.getWidth()
            ? abs(this.area.getWidth() - viewWidth)
            : 0.0
        this.offset.x = clamp(this.offset.x, -1 * this.offsetMax.x, 0.0)
        
        var viewHeight = this.fetchViewHeight()
        this.offsetMax.y = viewHeight >= this.area.getHeight()
            ? abs(this.area.getHeight() - viewHeight)
            : 0.0
        this.offset.y = clamp(this.offset.y, -1 * this.offsetMax.y, 0.0)
      }
    },
    "scrollableX": function() {
      return function() {
        var viewWidth = this.fetchViewWidth()
        this.offsetMax.x = viewWidth >= this.area.getWidth()
            ? abs(this.area.getWidth() - viewWidth)
            : 0.0
        this.offset.x = clamp(this.offset.x, -1 * this.offsetMax.x, 0.0)
      }
    },
    "scrollableY": function() {
      return function() {
        var viewHeight = this.fetchViewHeight()
        this.offsetMax.y = viewHeight >= this.area.getHeight()
            ? abs(this.area.getHeight() - viewHeight)
            : 0.0
        this.offset.y = clamp(this.offset.y, -1 * this.offsetMax.y, 0.0)
      }
    },
  })
  
  ///@type {Map<String, Callable>}
  updateAreaTemplates = new Map(String, Callable, {
    "applyLayout": function() {
      return function() {
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())
      }
    },
    "applyLayoutTextField": function() {
      return function() {
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())

        this.textField.style.w = this.area.getWidth()
        this.textField.style.h = this.area.getHeight()
        this.textField.update_style()
      }
    },
    "applyCollectionLayout": function() {
      return function() {
        this.layout.collection.setIndex(this.component.index)
        this.layout.collection.setSize(this.context.collection.size())
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())
      }
    },
    "applyMargin": function() {
      return function() {
        this.area.setX(this.margin.left)
        this.area.setY(this.margin.top)
        this.area.setWidth(this.context.area.getWidth() 
          - this.margin.left - this.margin.right)
        this.area.setHeight(this.context.area.getHeight() 
          - this.margin.top - this.margin.bottom)
      }
    },
    "groupByX": function() {
      return function() {
        ///@todo group.align support
        ///@todo group.amount support
        ///@todo group.width() support
        ///@todo group.height() support
        this.area.setWidth(this.context.area.getHeight()
          - this.margin.left - this.margin.right)
        this.area.setHeight(this.context.area.getHeight()
          - this.margin.top - this.margin.bottom)
        this.area.setX(this.context.area.getWidth() 
          - (this.area.getWidth() * (this.group.index + 1)))
        this.area.setY(this.margin.top)
      }
    },

    ///@deprecated
    "layout": function() {
      return function() {
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())
      }
    },
    "scrollable": function() {
      return function() {
        var viewWidth = this.fetchViewWidth()
        this.offsetMax.x = viewWidth >= this.area.getWidth()
            ? abs(this.area.getWidth() - viewWidth) + this.margin.right
            : 0.0
        this.offset.x = clamp(this.offset.x, -1 * this.offsetMax.x, 0.0)

        var viewHeight = this.fetchViewHeight()
        this.offsetMax.y = viewHeight >= this.area.getHeight()
            ? abs(this.area.getHeight() - viewHeight) + this.margin.bottom
            : 0.0
        this.offset.y = clamp(this.offset.y, -1 * this.offsetMax.y, 0.0)
      }
    },
    "scrollableX": function() {
      return function() {
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())

        var viewWidth = this.fetchViewWidth()
        this.offsetMax.x = viewWidth >= this.area.getWidth()
            ? abs(this.area.getWidth() - viewWidth) + this.margin.right
            : 0.0
        this.offset.x = clamp(this.offset.x, -1 * this.offsetMax.x, 0.0)
      }
    },
    "scrollableY": function() {
      return function() {
        this.area.setX(this.layout.x())
        this.area.setY(this.layout.y())
        this.area.setWidth(this.layout.width())
        this.area.setHeight(this.layout.height())

        var viewHeight = this.fetchViewHeight()
        this.offsetMax.y = viewHeight >= this.area.getHeight()
            ? abs(this.area.getHeight() - viewHeight) + this.margin.bottom
            : 0.0
        this.offset.y = clamp(this.offset.y, -1 * this.offsetMax.y, 0.0)
      }
    },
  })

  ///@type {Map<String, Callable>}
  renderTemplates = new Map(String, Callable, {
    "renderDefault": function() {
      return function() {
        var color = this.state.get("background-color")
        if (Core.isType(color, GMColor)) {
          GPU.render.rectangle(
            this.area.x, this.area.y, 
            this.area.x + this.area.getWidth(), this.area.y + this.area.getHeight(), 
            false,
            color, color, color, color, 
            this.state.get("background-alpha")
          )
        }
        
        this.items.forEach(this.renderItem)
      }
    },
    "renderDefaultScrollable": function() {
       return function() {
        if (!Optional.is(this.surface)) {
          this.surface = new Surface()
        }

        this.surface.update(this.area.getWidth(), this.area.getHeight())
          .renderOn(this.renderSurface)
        GPU.set.blendEnable(false)
        this.surface.render(this.area.getX(), this.area.getY())
        GPU.set.blendEnable(true)

        if (!Optional.is(this.scrollbarY)) {
          return
        }
        this.scrollbarY.render(this)
      }
    },
  })

  ///@type {Map<String, Callable>}
  mouseEventTemplates = new Map(String, Callable, {
    "scrollableOnMouseWheelUpX": function() {
      return function(event) {
        this.offset.y = clamp(this.offset.x + this.state.getDefault("offset-x", 20), 
          -1 * this.offsetMax.x, 0)
      }
    },
    "scrollableOnMouseWheelDownX": function() {
      return function(event) {
        this.offset.y = clamp(this.offset.x - this.state.getDefault("offset-x", 20), 
          -1 * this.offsetMax.x, 0)
      }
    },
    "scrollableOnMouseWheelUpY": function() {
      return function(event) {
        this.offset.y = clamp(this.offset.y + this.state.getDefault("offset-y", 20), 
          -1 * this.offsetMax.y, 0)
      }
    },
    "scrollableOnMouseWheelDownY": function() {
      return function(event) {
        this.offset.y = clamp(this.offset.y - this.state.getDefault("offset-y", 20), 
          -1 * this.offsetMax.y, 0)
      }
    },
  })

  ///@type {Map<String, Callable>}
  itemUpdateTemplates = new Map(String, Callable, {
    "updateScrollableXItem": function() {
      if (!this.state.contains("index")) {
        throw new Exception($"updateScrollableXItem require 'state.index' to be initialized")
      }

      var width = this.context.area.getWidth() / this.context.items.size()
      this.area.setX(this.state.get("index") * width)
      this.area.setY(0)
      this.area.setWidth(width)
      this.area.setHeight(this.context.area.getHeight())
    },
    "updateScrollableYItem": function() {
      if (!this.state.contains("index")) {
        throw new Exception($"updateScrollableYItem require 'state.index' to be initialized")
      }

      var height = this.context.area.getHeight() / this.context.items.size()
      this.area.setX(0)
      this.area.setY(this.state.get("index") * height)
      this.area.setWidth(this.context.area.getWidth())
      this.area.setHeight(height)
    },
  })
}
global.__UIUtil = new _UIUtil()
#macro UIUtil global.__UIUtil
