///@package io.alkapivo.core.lang

///@static
function _Global() constructor {

  ///@param {?String} name
  ///@param {any} [defaultValue]
  ///@return {any}
  get = function(name, defaultValue = null) {
    return this.exists(name) ? variable_global_get(name) : defaultValue
  }

  ///@param {?String} name
  ///@param {any} value
  ///@return {Global}
  set = function (name, value) {
    if (this.exists(name)) {
      variable_global_set(name, value)
    }
    return this
  }

  ///@param {?String} name
  ///@param {any} [defaultValue]
  ///@return {any}
  inject = function(name, defaultValue) {
    if (!this.exists(name)) {
      this.set(name, defaultValue)
    }
    return this.get(name, defaultValue)
  }

  ///@param {?String} name
  ///@return {Boolean}
  exists = function (name) {
    return Core.isType(name, String) && variable_global_exists(name)
  }
}
global.__Global = new _Global()
#macro Global global.__Global
