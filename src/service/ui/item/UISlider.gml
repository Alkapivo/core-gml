///@pacakge io.alkapivo.core.service.ui.item

///@param {String} name
///@param {Struct} [json]
///@return {UIItem}
function UISliderHorizontal(name, json = null) {
  var minValue = Struct.getIfType(json, "minValue", Number, 0.0)
  var maxValue = Struct.getIfType(json, "maxValue", Number, 1.0)
  if (minValue > maxValue) {
    var _value = minValue
    minValue = maxValue
    maxValue = _value
  }
  return new UIItem(name, Struct.append(json, {

    ///@param {Callable}
    type: UISliderHorizontal,

    ///@type {Number}
    value: Struct.getIfType(json, "value", Number, 0.0),

    ///@type {Number}
    minValue: minValue,

    ///@type {Number}
    maxValue: maxValue,

    ///@type {Number}
    snapValue: abs(Struct.getIfType(json, "snapValue", Number, 0.0)),

    ///@type {Sprite}
    pointer: Assert.isType(SpriteUtil.parse(Struct.getDefault(json, "pointer", {
      name: "texture_slider_pointer_default",
      scaleX: 0.6,
      scaleY: 0.6,
    })), Sprite),

    ///@type {TexturedLine}
    progress: new TexturedLine(Struct.getDefault(json, "progress", { 
      thickness: 0.75,
      blend: "#ff0000",
    })),

    ///@type {TexturedLine}
    background: new TexturedLine(Struct.getDefault(json, "background", {
      thickness: 0.75,
      blend: "#000000",
    })),

    ///@type {?Struct}
    enable: Struct.contains(json, "enable") ? Assert.isType(json.enable, Struct) : null,

    ///@param {Number} mouseX
    updateValue: new BindIntent(Assert.isType(Struct.getDefault(json, "updateValue", function(mouseX) {
      var position = clamp((this.context.area.getX() + mouseX - this.context.area.getX() - this.area.getX()) / this.area.getWidth(), 0.0, 1.0)
      if (this.snapValue > 0.0) {
        position = (floor(position / this.snapValue) * this.snapValue)
      }

      var length = abs(this.minValue - this.maxValue) * position
      this.value = clamp(this.minValue + length, this.minValue, this.maxValue)
      if (Core.isType(this.store, UIStore)) {
        this.store.set(this.value)
      }

      this.updatePosition(mouseX)
    }), Callable)),

    ///@param {Number} mouseX
    updatePosition: new BindIntent(Assert.isType(Struct.getDefault(json, "updatePosition", function(mouseX) { }), Callable)),

    updateEnable: Assert.isType(Callable.run(UIItemUtils.templates.get("updateEnable")), Callable),

    ///@override
    ///@param {Boolean} [_updateArea]
    ///@return {UIItem}
    update: function(_updateArea = true) {
      if (_updateArea && Optional.is(this.updateArea)) {
        this.updateArea()
      }

      if (Optional.is(this.updateEnable)) {
        this.updateEnable()
      }

      if (Optional.is(this.updateCustom)) {
        this.updateCustom()
      }

      if (this.isHoverOver) {
        this.updateHover()
      }

      if (!storeSubscribed && Optional.is(this.store)) {
        this.store.subscribe()
        this.storeSubscribed = true
      }

      if (Core.isType(this.enable, Struct)) {
        var factor = Struct.get(this.enable, "value") == false ? 0.5 : 1.0
        if (Core.isType(this.pointer, Sprite)) {
          this.pointer.setAlpha(factor
            * Struct.inject(this.enable, "pointer-alpha", this.pointer.getAlpha()))
        }
        if (Core.isType(this.progress, TexturedLine)) {
          this.progress.alpha = factor
            * Struct.inject(this.enable, "progress-alpha", this.progress.alpha)
        }
      }

      return this
    },

    renderBackgroundColor: new BindIntent(Callable.run(UIItemUtils.templates.get("renderBackgroundColor"))),

    ///@return {UIItem}
    render: Struct.getDefault(json, "render", function() {
      var promise = MouseUtil.getClipboard()
      if (Struct.get(Struct.get(promise, "state"), "context") == this) {
        var offsetX = Core.isType(Struct.get(this.context, "layout"), UILayout)
          ? this.context.layout.x() 
          : 0
        this.updateValue(MouseUtil.getMouseX() - offsetX)
      }
      
      if (Optional.is(this.preRender)) {
        this.preRender()
      }
      this.renderBackgroundColor()
      
      var fromX = this.context.area.getX() + this.area.getX()
      var fromY = this.context.area.getY() + this.area.getY() + (this.area.getHeight() / 2)
      var widthMax = this.area.getWidth()
      var width = ((this.value - this.minValue) / abs(this.minValue - this.maxValue)) * widthMax
      this.background.render(fromX, fromY, fromX + widthMax, fromY)
      this.progress.render(fromX, fromY, fromX + width, fromY)
      this.pointer.render(fromX + width, fromY)
      return this
    }),

    ///@type {Callable}
    callback: new BindIntent(Assert.isType(Struct.getDefault(json, "callback", function() { }), Callable)),
    
    ///@param {Event} event
    onMouseReleasedLeft: Assert.isType(Struct.getDefault(json, "onMouseReleasedLeft", function(event) {
      if (Struct.get(this.enable, "value") == false) {
        return
      }

      var offsetX = Core.isType(Struct.get(this.context, "layout"), UILayout) 
        ? this.context.layout.x() 
        : 0
      this.updateValue(MouseUtil.getMouseX() - offsetX)
    }), Callable),

    ///@param {Event} event
    onMouseDragLeft: Assert.isType(Struct.getDefault(json, "onMouseDragLeft", function(event) {
      if (Struct.get(this.enable, "value") == false) {
        return
      }

      var context = this
      MouseUtil.setClipboard(new Promise()
        .setState({
          context: context,
          callback: context.callback,
        })
        .whenSuccess(function() {
          Callable.run(Struct.get(this.state, "callback"))
        })
      )
    }), Callable),
  }, false))
}
