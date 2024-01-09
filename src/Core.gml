///@package io.alkapivo.core

#macro this self
#macro null undefined
#macro any "any"
#macro GAME_FPS 60
#macro FRAME_MS 1 / GAME_FPS
#macro ERROR_VALUE -1
#macro GuiWidth display_get_gui_width
#macro GuiHeight display_get_gui_height
#macro BREAK_LOOP "__BREAK_LOOP__"
#macro Prototype "Prototype"
#macro Matrix "Matrix"
#macro NonNull "NonNull"

///@static
function _Core() constructor {

  ///@private
  ///@final
  ///@type {Map<String, String>}
  typeofMap = new Map(String, String, {
    "array": "GMArray",
    "bool": Boolean,
    "int32": Number,
    "int64": Number,
    "method": "Callable",
    "null": any,
    "number": Number,
    "ptr": Number,
    "ref": Number,
    "string": "String",
    "struct": "Struct",
    "undefined": any,
    "unknown": any,
  })

  ///@param {any} object
  ///@param {any} type
  ///@return {Boolean}
  static isType = function(object, type) {
    try {
      var result = typeof(object)
      switch (type) {
        case any: return true
        case Boolean: return result == "bool" || result == "number"
        case Callable: return result == "method" || result == "ref" 
          && is_callable(object)
        case Collection: return result == "struct" && (is_instanceof(object, Collection) 
          || is_instanceof(object, Array) 
          || is_instanceof(object, Map) 
          || is_instanceof(object, Stack) 
          || is_instanceof(object, Queue))
        case GMArray: return result == "array"
        case GMBuffer: return result == "ref" && buffer_exists(object)
        case GMColor: return result == "number"
        case GMFont: return result == "ref" && font_exists(object)
        case GMKeyboardKey: return typeof(object) == "number"
        case GMMouseButton: return MouseButtonType.contains(object)
        case GMObject: return result == "ref"
        case GMShader: return result == "ref" && shader_is_compiled(object)
        case GMShaderUniform: return result == "number" && object != -1
        case GMSound: return result == "number" && audio_exists(object)
        case GMSurface: return result == "ref" && surface_exists(object)
        ///@description https://github.com/YoYoGames/GameMaker-Bugs/issues/2543
        case GMVideoSurface: return result == "number" && surface_exists(object)
        case NonNull: return object != null
        case Number: return result == "number"
        case Prototype: return result == "number" && is_callable(object)
        case String: return result == "string"
        case Struct: return result == "struct"
        default: 
          if (typeof(type) == "struct" && is_instanceof(type, OptionalType)) {
            return object != null ? Core.isType(object, type.type) : true
          }
          return is_instanceof(object, type)
      }
    } catch (exception) {
      Logger.error("Core.isType", $"Fatal error: {exception.message}")
    }
    return false
  }

  ///@param {any} object
  ///@param {Enum} enumerable
  ///@param {?String} [message]
  ///@return {Boolean}
  static isEnum = function(object, enumerable) {
    try {
      return enumerable.contains(object)
    } catch (exception) { }
    return false
  }

  ///@param {any} object
  ///@param {Enum} enumerable
  ///@param {?String} [message]
  ///@return {Boolean}
  static isEnumKey = function(object, enumerable) {
    try {
      return enumerable.containsKey(object)
    } catch (exception) { }
    return false  
  }

  ///@param {any} object
  ///@return {?String}
  static getTypeName = function(object) {
    var type = null
    try {
      type = Core.hasConstructor(object) 
        ? instanceof(object) 
        : Core.typeofMap.getDefault(typeof(object), null)
    } catch (exception) { }
    return type
  }

  ///@param {String} name
  ///@return {?Callable}
  static getConstructor = function(name) {
    if (!Core.isType(name, String)) {
      return null
    }
    
    var prototype = asset_get_index(name)
    if (!Core.isType(prototype, Callable)) {
      return null
    }

    return prototype
    /*
    var type = null
    try {
      type = Assert.isType(asset_get_index(name), Callable)
    } catch (exception) { }
    return type
    */
  }

  ///@param {any} object
  ///@return {Boolean}
  static hasConstructor = function(object) {
    var type = typeof(object) != "struct" ? null : instanceof(object)
    return type != null && type != "struct"
  }

  ///@param {...any} message
  ///@return {Core}
  static print = function(/*...message*/) {
    var buffer = ""
    try {
      for (var index = 0; index < argument_count; index++) {
        buffer += (index == 0 ? "" : " ") + string(argument[index])
      }
    } catch (exception) {
      buffer = $"'print' fatal error: {exception.message}"
    }
    show_debug_message(buffer)
    return this
  }

  ///@return {Core}
  static printStackTrace = function() {
    var stackTrace = debug_get_callstack();
    for (var index = 0; index < GMArray.size(stackTrace); index++) {
      var line = string(stackTrace[index]);
      if (line != "0") {
        line = "\tat " + line;
        Core.print(line)
      }
    }
    return this
  }
}
global.__Core = new _Core()
#macro Core global.__Core
