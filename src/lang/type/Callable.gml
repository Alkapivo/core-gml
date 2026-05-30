///@package io.alkapivo.core.lang.type

///@static
function _Callable() constructor {

  ///@param {String} name
  ///@return {?Callable}
  get = function(name) {
    if (!Core.isType(name, String)) {
      return null
    }
    
    var callable = asset_get_index(name)
    return Core.isType(callable, Callable) ? callable : null
  }

  ///@param {?Struct|?GMObject} context
  ///@param {?Callable} callable
  ///@return {?Callable}
  bind = function(context, callback) {
    return callback != null && (Core.isType(context, Struct) || Core.isType(context, GMObject))
      ? method(context, callback)
      : null
  }

  ///@param {String|Callable} _callback
  ///@param {...any} [params]
  ///@return {any}
  run = function(_callback/*, params = null*/) {
    var callback = Core.isType(_callback, String) 
      ? Callable.get(_callback) 
      : _callback
    if (!Core.isType(callback, Callable)) {
      return null
    }

    #region Inline spread operator for argument[] xD
    switch (argument_count) {
      case 1:
        return callback()
      case 2:
        return callback(argument[1])
      case 3:
        return callback(argument[1], argument[2])
      case 4:
        return callback(argument[1], argument[2], argument[3])
      case 5:
        return callback(argument[1], argument[2], argument[3], argument[4])
      case 6:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5])
      case 7:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6])
      case 8:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7])
      case 9:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8])
      case 10:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9])
      case 11:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10])
      case 12:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11])
      case 13:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11], argument[12])
      case 14:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11], argument[12], argument[13])
      case 15:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11], argument[12], argument[13], argument[14])
      case 16:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11], argument[12], argument[13], argument[14], argument[15])
      case 17:
        return callback(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8], argument[9], argument[10], argument[11], argument[12], argument[13], argument[14], argument[15], argument[16])
      default:
        throw new TooManyArgumentsException($"\{ \"argument_count\": {argument_count} \}")
    }
    #endregion
  }
}
global.__Callable = new _Callable()
#macro Callable global.__Callable


///@param {Callable} _callback
function BindIntent(_callback) constructor {

  ///@type {Callable}
  callback = Assert.isType(_callback, Callable,
    "BindIntent::callback must be type of Callable")

  ///@param {?Struct|?GMObject} context
  ///@return {?Callable}
  static bind = function(context) {
    return Callable.bind(context, this.callback)
  }
}

