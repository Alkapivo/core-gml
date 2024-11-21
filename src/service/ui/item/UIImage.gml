///@pacakge io.alkapivo.core.service.ui.item

///@param {String} name
///@param {Struct} [json]
///@return {UIItem}
function UIImage(name, json = null) {
  return new UIItem(name, Struct.append(json, {

    ///@param {Callable}
    type: UIImage,
    
    ///@type {?Sprite}
    image: Struct.contains(json, "image") 
      ? Assert.isType(SpriteUtil.parse(json.image), Sprite)
      : null,

    ///@type {?UILabel}
    label: Struct.contains(json, "label") ? new UILabel(json.label) : null,

    ///@type {?Struct}
    enable: Struct.contains(json, "enable") ? Assert.isType(json.enable, Struct) : null,

    ///@type {?String}
    origin: Struct.getIfType(json, "origin", String),

    updateEnable: Assert.isType(Callable.run(UIItemUtils.templates.get("updateEnable")), Callable),

    renderBackgroundColor: new BindIntent(Callable.run(UIItemUtils.templates.get("renderBackgroundColor"))),

    ///@override
    ///@return {UIItem}
    render: Struct.getDefault(json, "render", function() {
      if (Optional.is(this.preRender)) {
        this.preRender()
      }
      this.renderBackgroundColor()

      if (this.image != null) {
        var alpha = this.image.getAlpha()
        var scaleX = this.image.getScaleX()
        var scaleY = this.image.getScaleY()
        this.image
          .setAlpha(alpha * (Struct.get(this.enable, "value") == false ? 0.5 : 1.0))
          .scaleToFit(this.area.getWidth(), this.area.getHeight())
          .render(
            this.context.area.getX() + this.area.getX() + image.texture.offsetX * image.getScaleX() + ((this.area.getWidth() - (image.getWidth() * image.getScaleX())) / 2),
            this.context.area.getY() + this.area.getY() + image.texture.offsetY * image.getScaleY() + ((this.area.getHeight() - (image.getHeight() * image.getScaleY())) / 2)
          )
          .setAlpha(alpha)
          .setScaleX(scaleX)
          .setScaleY(scaleY)

        if (this.origin != null) {
          var textureTemplate = this.store.getStore().getValue(this.origin)
          var originX = textureTemplate.originX
          var originY = textureTemplate.originY
          scaleX = this.image.getScaleX()
          scaleY = this.image.getScaleY()
          this.image.scaleToFit(this.area.getWidth(), this.area.getHeight())
          var _x = this.context.area.getX() 
            + this.area.getX()
            + (this.area.getWidth() / 2.0)
            - ((image.getWidth() * image.getScaleX()) / 2.0)
            + (originX * image.getScaleX())
          var _y = this.context.area.getY() 
            + this.area.getY()
            + (this.area.getHeight() / 2.0)
            - ((image.getHeight() * image.getScaleY()) / 2.0)
            + (originY * image.getScaleY())
          this.image.setScaleX(scaleX).setScaleY(scaleY)

          draw_circle_colour(_x, _y, 6, c_red, c_yellow, false);
          draw_circle_colour(_x, _y, 2, c_white, c_black, true);
        }
      }

      if (this.label != null) {
        this.label.render(
          // todo VALIGN HALIGN
          this.context.area.getX() + this.area.getX() + this.area.getWidth() / 2,
          this.context.area.getY() + this.area.getY() + this.area.getHeight() / 2
        )
      }
      return this
    }),
  }, false))
}
