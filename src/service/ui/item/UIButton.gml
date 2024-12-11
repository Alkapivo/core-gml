///@pacakge io.alkapivo.core.service.ui.item

///@param {String} name
///@param {Struct} [json]
///@return {UIItem}
function UIButton(name, json = null) {
  return new UIItem(name, Struct.append(json, {

    ///@param {Callable}
    type: UIButton,
    
    ///@type {?Sprite}
    sprite: Struct.contains(json, "sprite") 
      ? Assert.isType(SpriteUtil.parse(json.sprite), Sprite)
      : null,
    
    ///@type {?UILabel}
    label: Struct.contains(json, "label")
      ? new UILabel(json.label)
      : null,

    ///@type {?Margin}
    backgroundMargin: Struct.contains(json, "backgroundMargin")
      ? new Margin(Struct.get(json, "backgroundMargin"))
      : null,

    ///@type {?Struct}
    enable: Struct.contains(json, "enable")
      ? Assert.isType(json.enable, Struct)
      : null,

    updateEnable: Assert.isType(Optional.is(Struct.get(json, "updateEnable"))
      ? json.updateEnable
      : Callable.run(UIItemUtils.templates.get("updateEnable")), Callable),
    
    renderBackgroundColor: new BindIntent(Callable
      .run(UIItemUtils.templates.get("renderBackgroundColor"))),

    ///@override
    ///@return {UIItem}
    render: Struct.getDefault(json, "render", function() {
      if (Optional.is(this.preRender)) {
        this.preRender()
      }

      var enableFactor = (Struct.get(this.enable, "value") == false ? 0.5 : 1.0)
      var _backgroundAlpha = this.backgroundAlpha
      this.backgroundAlpha *= enableFactor
      this.renderBackgroundColor()
      this.backgroundAlpha = _backgroundAlpha

      if (this.sprite != null) {
        var spriteAlpha = this.sprite.getAlpha()
        this.sprite
          .setAlpha(spriteAlpha * enableFactor)
          .scaleToFillStretched(this.area.getWidth(), this.area.getHeight())
          .render(
            this.context.area.getX() + this.area.getX(),
            this.context.area.getY() + this.area.getY())
          .setAlpha(spriteAlpha)
      }

      if (this.label != null) {
        var labelAlpha = this.label.alpha
        this.label.alpha *= enableFactor
        this.label.render(
          // todo VALIGN HALIGN
          this.context.area.getX() + this.area.getX() + (this.area.getWidth() / 2),
          this.context.area.getY() + this.area.getY() + (this.area.getHeight() / 2),
          this.area.getWidth(),
          this.area.getHeight()
        )
        this.label.alpha = labelAlpha
      }
      return this
    }),

    ///@type {?Callable}
    callback: Struct.contains(json, "callback")
      ? new BindIntent(Assert.isType(Struct.get(json, "callback"), Callable))
      : null,
    
    ///@param {Event} event
    onMouseReleasedLeft: Assert.isType(Struct.getDefault(json, "onMouseReleasedLeft", function(event) {
      if (Struct.get(this.enable, "value") == false) {
        return
      }

      if (Optional.is(this.callback)) {
        this.callback()
      }

      if (Core.isType(this.context, UI) 
          && Optional.is(this.context.updateTimer)) {
        this.context.updateTimer.time = clamp(
          this.context.updateTimer.time,
          this.context.updateTimer.duration * 0.9,
          this.context.updateTimer.duration
        )
      }
    }), Callable),
  }, false))
}
