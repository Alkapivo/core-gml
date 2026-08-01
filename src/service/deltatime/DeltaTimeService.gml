///@package io.alkapivo.core.service.deltatime
show_debug_message("init DeltaTimeService.gml")


///@type {String}
#macro BeanDeltaTimeService "DeltaTimeService"

///@param {?Struct} [config]
function DeltaTimeService(config = null): Service(config) constructor {

  ///@return {Number}
  get = function() { 
    gml_pragma("forceinline")
    return DeltaTime.get()
  }

  ///@param {Number} value
  ///@return {Number}
  apply = function(value) {
    gml_pragma("forceinline")
    return DeltaTime.apply(value)
  }

  ///@param {DeltaTimeMode} mode
  ///@return {DeltaTimeService}
  setMode = function(mode) {
    DeltaTime.mode = Core.isEnum(mode, DeltaTimeMode) ? mode : DeltaTime.mode
    return this
  }

  ///@override
  ///@return {DeltaTimeService}
  updateBegin = function() {
    DeltaTime.update()
    return this
  }
}
