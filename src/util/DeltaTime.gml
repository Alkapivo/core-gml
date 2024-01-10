///@package io.alkapivo.core.DeltaTime

///@static
function _DeltaTime() constructor {
  
  ///@param {Number} value
  ///@return {Number}
  static apply = function(value) {
    return value
  }

  ///@return {DeltaTime}
  static update = function() {
    return this
  }
}
global.__DeltaTime = new _DeltaTime()
#macro DeltaTime global.__DeltaTime
