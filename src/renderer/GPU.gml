///@package io.alkapivo.core.renderer.GPU

///@type {Texture}
global.__GPU_DEFAULT_LINE_TEXTURE = new Texture(texture_grid_line_default)
#macro GPU_DEFAULT_LINE_TEXTURE global.__GPU_DEFAULT_LINE_TEXTURE


///@type {Texture}
global.__GPU_DEFAULT_LINE_TEXTURE_CORNER = new Texture(texture_grid_line_corner_default)
#macro GPU_DEFAULT_LINE_TEXTURE_CORNER global.__GPU_DEFAULT_LINE_TEXTURE_CORNER


///@enum
function _BlendMode(): Enum() constructor {
  ADD = bm_add
  NORMAL = bm_normal
}
global.__BlendMode = new _BlendMode()
#macro BlendMode global.__BlendMode


///@enum
function _VAlign(): Enum() constructor {
  TOP = fa_top
  CENTER = fa_middle
  BOTTOM = fa_bottom
}
global.__VAlign = new _VAlign()
#macro VAlign global.__VAlign


///@enum
function _HAlign(): Enum() constructor {
  LEFT = fa_left
  CENTER = fa_center
  RIGHT = fa_right
}
global.__HAlign = new _HAlign()
#macro HAlign global.__HAlign



///@static
function _GPU() constructor {
  render = {
    ///@param {Number} beginX
    ///@param {Number} beginY
    ///@param {Number} endX
    ///@param {Number} endY
    ///@param {Number} [thickness]
    ///@param {Number} [alpha]
    ///@param {GMColor} [blend]
    ///@param {Texture} [line]
    ///@param {Texture} [corner]
    texturedLine: function(beginX, beginY, endX, endY, 
        thickness = 1.0, alpha = 1.0, blend = c_white, 
        line = GPU_DEFAULT_LINE_TEXTURE, 
        corner = GPU_DEFAULT_LINE_TEXTURE_CORNER) {

      var angle = point_direction(beginX, beginY, endX, endY)
      var length = point_distance(beginX, beginY, endX, endY)
      var scale = length / line.width
      corner.render(beginX, beginY, 0, thickness, thickness, alpha, angle, blend)
      corner.render(endX, endY, 0, thickness, thickness, alpha, angle + 180.0, blend)
      line.render(beginX, beginY, 0, scale, thickness, alpha, angle, blend)
    },

    ///@param {Color} color
    clear: function(color) {
      draw_clear_alpha(color.toGMColor(), color.alpha)
    },

    ///@param {Number} beginX
    ///@param {Number} beginY
    ///@param {Number} endX
    ///@param {Number} endY
    ///@param {Boolean} [outline]
    ///@param {?GMColor} [color1]
    ///@param {?GMColor} [color2]
    ///@param {?GMColor} [color3]
    ///@param {?GMColor} [color4]
    ///@param {?Number} [alpha]
    rectangle: function(beginX, beginY, endX, endY, outline = false, color1 = null, color2 = null, color3 = null, color4 = null, alpha = null) {
      var c1 = color1 == null ? c_black : color1
      var c2 = color2 == null ? c1 : color2
      var c3 = color3 == null ? c1 : color3
      var c4 = color4 == null ? c2 : color4
      if (alpha == null) {
        draw_rectangle_color(beginX, beginY, endX, endY, c1, c2, c3, c4, outline)
      } else {
        var _alpha = draw_get_alpha()
        if (_alpha == alpha) {
          draw_rectangle_color(beginX, beginY, endX, endY, c1, c2, c3, c4, outline)
        } else {
          draw_set_alpha(alpha)
          draw_rectangle_color(beginX, beginY, endX, endY, c1, c2, c3, c4, outline)
          draw_set_alpha(_alpha)
        }
      }
    },
  }

  set = {
    ///@param {Shader}
    ///@return {Struct}
    shader: function(shader) {
      shader_set(shader.asset) 
      return GPU.set
    },

    ///@param {Surface}
    ///@return {Struct}
    surface: function(surface) {
      surface_set_target(surface.asset)
      return GPU.set
    },

    ///@param {BlendMode} mode
    ///@return {Struct}
    blendMode: function(mode) {
      gpu_set_blendmode(mode)
      return GPU.set
    },

    ///@param {Boolean} enable
    ///@return {Struct}
    blendEnable: function(enable) {
      gpu_set_blendenable(enable)
      return GPU.set
    },
  }

  get = {
    surface: function() {
      return surface_get_target()
    },
  }

  reset = {
    shader: function() {
      shader_reset()
    },
    surface: function() {
      surface_reset_target()
    },
    blendMode: function() {
      gpu_set_blendmode(BlendMode.NORMAL)
    },
  }
}
global.__GPU = new _GPU()
#macro GPU global.__GPU
