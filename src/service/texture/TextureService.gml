///@package io.alkapivo.core.service.texture

#macro BeanTextureService "TextureService"

function TextureService(): Service() constructor {

  ///@type {Map<String, TextureTemplate>}
  templates = new Map(String, TextureTemplate)

  ///@private
  ///@type {EventDispatcher}
  dispatcher = new EventDispatcher(this, new Map(String, Callable, { }))

  ///@private
  ///@type {TaskExecutor}
  executor = new TaskExecutor(this)

  ///@param {Event} event
  ///@return {?Promise}
  send = method(this, function(event) {
    return this.dispatcher.send(event)
  })

  ///@param {String} name
  ///@return {?Texture}
  factoryTexture = method(this, function(name) {
    if (!this.templates.contains(name)) {
      return null
    }

    var config = this.templates.get(name)
    var asset = Struct.get(config, "asset")
    if (!Core.isType(asset, String)) {
      Logger.warn("TextureService", $"Missing texture asset in json {name}")
      return null
    }

    asset = asset_get_index(name)
    if (!sprite_exists(asset)) {
      Logger.warn("TextureService", $"Missing texture {name}")
      return null
    }

    return new Texture(asset, config)
  })

  ///@param {String} name
  ///@return {?Sprite}
  factorySprite = method(this, function(name) {
    if (!this.templates.contains(name)) {
      return null
    }

    return SpriteUtil.parse(this.templates.get(name) )
  })

  ///@override
  ///@return {TextureService}
  update = method(this, function() {
    this.dispatcher.update()
    this.executor.update()
    return this
  })
}
