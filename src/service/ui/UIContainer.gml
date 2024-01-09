///@package io.alkapivo.core.service.ui

///@param {Struct} [config]
function UIContainer(config = {}) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(config, "name"), String)

  ///@type {Rectangle}
  area = new Rectangle(Struct.get(config, "area"))

  ///@type {any}
  state = Struct.get(config, "state")

  ///@type {Boolean}
  enable = Assert.isTrue(Struct.getDefault(config, "enable", true), Boolean)

  ///type {Boolean}
  propagate = Assert.isType(Struct.getDefault(config, "propagate", true), Boolean)

  ///@type {Vector2}
  offset = Assert.isType(Struct.getDefault(config, "offset", new Vector2()), Vector2)

  ///@type {Vector2}
  offsetMax = Assert.isType(Struct.getDefault(config, "offsetMax", new Vector2()), Vector2)

  ///@type {?UILayout}
  layout = Struct.contains(config, "layout")
    ? Assert.isType(config.layout, UILayout)
    : null

  ///@type {?UICollection}
  collection = Struct.contains(config, "collection")
    ? Assert.isType(config.collection, UICollection)
    : null

  ///@private
  ///@type {?Collection}
  items = new Map(String, UIItem)

  ///@type {Margin}
  margin = new Margin(Struct.get(config, "margin"))
  
  ///@return {Number}
  fetchViewWidth = Struct.contains(config, "fetchViewWidth")
    ? Assert.isType(method(this, config.fetchViewWidth), Callable)
    : function() {
      static updateWidthPeak = function(item, name, acc) {
        acc.peak = max(acc.peak, item.area.getX() 
          + item.area.getWidth() + item.margin.right)
      }
      
      var acc = { peak: 0 }
      this.items.forEach(updateWidthPeak, acc)
      return acc.peak
    }

  ///@return {Number}
  fetchViewHeight = Struct.contains(config, "fetchViewHeight")
    ? Assert.isType(method(this, config.fetchViewHeight), Callable)
    : function() {
      static updateHeightPeak = function(item, name, acc) {
        acc.peak = max(acc.peak, item.area.getY() 
          + item.area.getHeight() + item.margin.bottom)
      }
      
      var acc = { peak: 0 }
      this.items.forEach(updateHeightPeak, acc)
      return acc.peak
    } 

  ///@private
  ///@type {?Surface}
  surface = Struct.contains(config, "surface")
    ? Assert.isType(config.surface, Surface)
    : null

  updateArea = Struct.contains(config, "updateArea")
    ? Assert.isType(method(this, config.updateArea), Callable)
    : null

  updateCustom = Struct.contains(config, "updateCustom")
    ? Assert.isType(method(this, config.updateCustom), Callable)
    : null

  ///@param {UIItem} item
  updateItem = Struct.contains(config, "updateItem")
    ? Assert.isType(method(this, config.updateItem), Callable)
    : function(item) {
      item.update()
    }

  updateItems = Struct.contains(config, "updateItems")
    ? Assert.isType(method(this, config.updateItems), Callable)
    : function() {
      this.items.forEach(this.updateItem)
    }

  ///@param {Event} event
  ///@return {Boolean}
  dispatch = Struct.contains(config, "dispatch")
    ? Assert.isType(method(this, config.dispatch), Callable)
    : function(event) {
      static isValidItem = function(item, name, event) {
        return item.support(event) && item.collide(event)
      }

      var _x = Struct.get(event.data, "x")
      var _y = Struct.get(event.data, "y")
      if (!Core.isType(_x, Number) || !Core.isType(_y, Number) || !this.area.collide(_x, _y)) {
        return false
      }

      var item = this.items.find(isValidItem, event)
      if (!Core.isType(item, UIItem)) {
        var containerHandler = Struct.get(this, $"on{event.name}")
        if (!Core.isType(containerHandler, Callable)) {
          return !this.propagate
        }
        Callable.run(containerHandler, event)
        return true
      }

      var dispatcher = item.fetchEventDispatcher(event)
      if (event.name == "MouseHoverOver" && Optional.is(dispatcher)) {
        if (item.isHoverOver) {
          return true
        }
        item.isHoverOver = true
      }
      Callable.run(dispatcher, event)
      return true
    }

  ///@param {UIItem} item
  ///@return {UIContainer} 
  add = Struct.contains(config, "add")
    ? Assert.isType(method(this, config.add), Callable)
    : function(item) {
      item.context = this //@todo item context constructor
      this.items.add(item, item.name)
      return this
    }

  ///@param {String} name
  ///@return {UIContainer}
  remove = Struct.contains(config, "remove")
    ? Assert.isType(method(this, config.remove), Callable)
    : function(name) {
      var item = this.items.get(name)
      if (Optional.is(item)) {
        item.free()
      }
      this.items.remove(name)
      return this
    }

  ///@return {UIContainer}
  update = Struct.contains(config, "update")
    ? Assert.isType(method(this, config.update), Callable)
    : function() {
      if (Optional.is(this.updateArea)) {
        this.updateArea()
      }

      if (Optional.is(this.updateCustom)) {
        this.updateCustom()
      }

      if (Optional.is(this.updateItems)) {
        this.updateItems()
      }
      return this
    }

  ///@return {UIContainer}
  renderSurface = Struct.contains(config, "renderSurface")
    ? Assert.isType(method(this, config.renderSurface), Callable)
    : function() {
      var color = this.state.get("background-color")
      GPU.render.clear(Core.isType(color, GMColor) 
        ? ColorUtil.fromGMColor(color) 
        : ColorUtil.BLACK_TRANSPARENT)

      var areaX = this.area.x
      var areaY = this.area.y
      this.area.x = this.offset.x
      this.area.y = this.offset.y
      this.items.forEach(this.renderItem)
      this.area.x = areaX
      this.area.y = areaY
    }

  ///@param {UIItem} item
  renderItem = Struct.contains(config, "renderItem")
    ? Assert.isType(method(this, config.renderItem), Callable)
    : function(item) {
      item.render()
    }

  ///@return {UIContainer}
  render = Struct.contains(config, "render")
    ? Assert.isType(method(this, config.render), Callable)
    : function() {
      this.items.forEach(this.renderItem)
      return this
    }

  ///@type {Map<String, Callable>}
  freeOperations = Struct.contains(config, "freeOperations")
    ? Assert.isType(config.operations, Map)
    : new Map(String, Callable, {
        "unsubscribe-items": function(context) {
          context.items.forEach(function(item) {
            item.free()
          })
        },
        "free-surface": function(context) {
          if (Core.isType(context.surface, Surface)) {
            context.surface.free()
          }
        },
        "clean-up": function(context) {
          if (Core.isType(context.onDestroy, Callable)) {
            context.onDestroy()
          }
        }
      })
  
  free = Struct.contains(config, "free")
    ? Assert.isType(method(this, config.free), Callable)
    : function() {
    this.freeOperations.forEach(function(operation, key, context) {
      try {
        operation(context)
      } catch (exception) {
        Logger.error("UIContainer", $"Unable to execute free operation '{key}'. {exception.message}")
      }
    }, this)

    return this
  }
  
  ///@param {Array<UIComponents>} components
  ///@param {UILayout} layout
  ///@param {?Struct} [config]
  ///@return {UIContainer}
  addUIComponents = Struct.contains(config, "addUIComponents")
    ? Assert.isType(method(this, config.addUIComponents), Callable)
    : function(components, layout, config = null) {
    static factoryComponent = function(component, index, acc) {
      static add = function(item, index, context) {
        context.add(item, item.name)
        if (Optional.is(item.updateArea())) {
          item.updateArea()
        }
      }

      acc.layout = component
        .toUIItems(acc.layout)
        .forEach(add, acc.context)
        .getLast().layout.context
    }

    var context = this
    components.forEach(
      factoryComponent, 
      Struct.append(
        config,
        {
          layout: layout,
          context: context,
        },
        false
      )
    )
    return this
  }

  ///@type {?Timer}
  timer =  Struct.contains(config, "timer") ? Assert.isType(config.timer, Timer) : null

  ///@type {Struct}
  scrollbarY = Struct.appendRecursive(
    {
      align: HAlign.LEFT,
      width: 10,
      thickness: 3,
      color: ColorUtil.fromHex(VETheme.color.primary).toGMColor(),
      render: function(context) {
        var x1 = 0, y1 = 0, x2 = 0, y2 = 0
        switch (this.align) {
          case HAlign.LEFT:
            x1 = context.area.getX() - this.width + (this.width - this.thickness) / 2.0
            y1 = context.area.getY() + this.thickness
            x2 = x1 + this.thickness
            y2 = y1 + context.area.getHeight() - (this.thickness * 2)
            break
          case HAlign.RIGHT:
            x1 = context.area.getX() + context.area.getWidth() + (this.width - this.thickness) / 2.0
            y1 = context.area.getY()  + this.thickness
            x2 = x1 + this.thickness
            y2 = y1 + context.area.getHeight() - (this.thickness * 2)
            break
        }

        var height = context.area.getHeight() - (this.thickness * 2)
        var length = height + context.offsetMax.y 
        var beginRatio = clamp(clamp(abs(context.offset.y), 0, context.offsetMax.y) / length, 0, 1)

        y1 = y1 + (beginRatio * height)
        y2 = y1 + ((height / length) * height)
        GPU.render.rectangle(x1, y1, x2, y2, false, this.color)
      }
    },
    Struct.getDefault(config, "scrollbarY", {})
  )

  ///@type {?Callable}
  onInit = null

  ///@type {?Callable}
  onDestroy = null

  ///@description apply functions like onMouseWheelUp as struct fields
  Struct.forEach(config, function(value, key, container) {
    if (!String.startsWith(key, "on")) {
      return
    }
    Struct.set(container, key, method(container, Assert.isType(value, Callable)))
  }, this)

  if (Struct.contains(config, "items")) {
    Struct.forEach(Struct.get(config, "items"), function(json, name, container) {
      container.add(json.type(name, json), name)
    }, this)
  }
  
  Struct.appendUnique(this, config)
  
  if (Core.isType(this.onInit, Callable)) {
    this.onInit()
  }

  ///@todo move to method
  if (Optional.is(this.updateArea)) {
    this.updateArea()
  }
  this.items.forEach(function(item) {
    if (Optional.is(item.updateArea)) {
      item.updateArea()
    }
  }) 
}
