///@package io.alkapivo.core.lang
show_debug_message("init Assert.gml")

///@static
function _Assert() constructor {
  
  ///@param {any} a
  ///@param {any} b
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {Boolean}
  areEqual = function(a, b, message = null) {
    if (a != b) {
      var msg = !Core.isType(message, String)
        ? $"'areEqual' assert error: \{ a: {a}, b: {b} \}"
        : message
      Logger.error("Assert", msg)
      throw new InvalidAssertException(msg)
    }
    return true
  }

  ///@param {any} object
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {Boolean}
  isTrue = function(object, message = null) {
    if (object != true) {
      var msg = !Core.isType(message, String)
        ? $"'isTrue' assert error: \{ \"object\": \"{object}\" \}"
        : message
      Logger.error("Assert", msg)
      throw new InvalidAssertException(msg)
    }
    return true
  }

  ///@param {any} object
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {Boolean}
  isFalse = function(object, message = null) {
    if (object != false) {
      var msg = !Core.isType(message, String)
        ? $"'isFalse' assert error: \{ \"object\": \"{object}\" \}"
        : message
      Logger.error("Assert", msg)
      throw new InvalidAssertException(msg)
    }
    return true
  }

  ///@param {any} object
  ///@param {Type} type
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {any}
  isType = method(this, function(object, type, message = null) {
    if (!Core.isType(object, type)) {
      Core.print($"todo: Assert.isType message")
      throw new InvalidAssertException()
    }
    return object
  })

  ///@param {any} object
  ///@param {Enum} enumerable
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {Enum}
  isEnum = function(object, enumerable, message = null) {
    if (!Core.isEnum(object, enumerable)) {
      Core.print("todo: Assert.isEnum message")
      throw new InvalidAssertException()
    }
    return object
  }

  ///@param {any} object
  ///@param {Enum} enumerable
  ///@param {?String} [message]
  ///@throws {InvalidAssertException}
  ///@return {Enum}
  isEnumKey = function(object, enumerable, message = null) {
    if (!Core.isEnumKey(object, enumerable)) {
      Core.print("todo: Assert.isEnumKey message")
      throw new InvalidAssertException()
    }
    return object
  }

  ///@param {String} path
  ///@throws {InvalidAssertException}
  ///@param {?String} [message]
  ///@return {String}
  fileExists = function(path, message = null) {
    if (!Core.isType(path, String) && !file_exists(path)) {
      Core.print("todo: Assert.fileExists message")
      throw new InvalidAssertException()
    }
    return path
  }
}
global.__Assert = new _Assert()
#macro Assert global.__Assert
