///@package io.alkapivo.core.service.texture

#macro AssetTexture "AssetTexture"

///@param {AssetTexture} _asset
///@param {Struct} [config]
function Texture(_asset, config = {}) constructor {

  ///@final
  ///@type {AssetTexture}
  asset = _asset

  ///@final
  ///@type {String}
  name = sprite_get_name(this.asset)

  ///@final
  ///@type {Number}
  width = sprite_get_width(this.asset)

  ///@final
  ///@type {Number}
  height = sprite_get_height(this.asset)
  
  ///@final
  ///@type {Number}
  frames = sprite_get_number(this.asset)

  ///@type {Number}
  speed = Struct.getDefault(config, "speed", sprite_get_speed(this.asset))

  ///@type {Number}
  offsetX = Struct.getDefault(config, "offsetX", sprite_get_xoffset(this.asset))

  ///@type {Number}
  offsetY = Struct.getDefault(config, "offsetY", sprite_get_yoffset(this.asset))

  ///@param {Number} x
  ///@param {Number} y
  ///@param {Number} [frame]
  ///@param {Number} [scaleX]
  ///@param {Number} [scaleY]
  ///@param {Number} [alpha]
  ///@param {Number} [angle]
  ///@param {Color} [blend]
  ///@return {Texture}
  static render = method(this, function(x, y, frame = 0, scaleX = 1, scaleY = 1, alpha = 1, angle = 0, blend = c_white) {
    draw_sprite_ext(
      this.asset, frame, 
      x, y, 
      scaleX, scaleY, 
      angle, blend, alpha
    )
    return this
  })
}

///@param {?String} _name
///@param {Struct} json
function TextureTemplate(_name, json) constructor {
  
  ///@type {?String}
  name = Struct.get(json, "asset")

  ///@type {?String}
  asset = _name
  
  ///@type {?Number}
  offsetX = Struct.get(json, "offsetX")
  
  ///@type {?Number}
  offsetY = Struct.get(json, "offsetY")
  
  ///@type {any}
  frame = Struct.get(json, "frame")
  
  ///@type {?Number}
  speed = Struct.get(json, "speed")
  
  ///@type {?Number}
  scaleX = Struct.get(json, "scaleX")
  
  ///@type {?Number}
  scaleY = Struct.get(json, "scaleY")
  
  ///@type {?Number}
  alpha = Struct.get(json, "alpha")
  
  ///@type {?Number}
  angle = Struct.get(json, "angle")
  
  ///@type {?GMColor}
  blend = Struct.get(json, "blend")
  
  ///@type {?Boolean}
  animate = Struct.get(json, "animate")
}


///@static
function _TextureUtil() constructor {

  ///@param {?String} name
  ///@return {Boolean}
  exists = function(name) {
    return Core.isType(name, String) && asset_get_index(name) != -1
  }

  ///@param {String} name
  ///@param {Struct} [config]
  ///@return {?Texture}
  fetch = function(name, config = {}) {
    var texture = null 
    var textureService = Beans.get(BeanTextureService)
    if (textureService != null) {
      var template = textureService.templates.get(name)
      if (template != null && sprite_exists(template.asset)) {
        texture = textureService.factoryTexture(template)
      }
    }

    if (texture == null) {
      var asset = asset_get_index(name)
      if (sprite_exists(asset)) {
        texture = new Texture(asset, config)
      }
    }

    if (texture == null) {
      Logger.warn("TextureUtil", $"Missing texture {name}")
    }
    return texture
  }
}
global.__TextureUtil = new _TextureUtil()
#macro TextureUtil global.__TextureUtil
