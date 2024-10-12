///@package io.alkapivo.core.util
show_debug_message("init Scene.gml")

///@static
function _Scene() constructor {

  ///@private
  ///@type {any}
  intent = null

  ///@return {any}
  getIntent = function() {
    return this.intent
  }

  ///@param {any} intent
  ///@return {Scene}
  setIntent = function(intent) {
    this.intent = intent
    return this
  }

  ///@param {String} name
  ///@param {any} [intent]
  ///@return {Scene}
  open = function(name, intent = null) {
    var scene = Assert.isType(asset_get_index(name), GMScene)
    this.setIntent(intent)
    room_goto(scene)
    return this
  }

  ///@param {String} name
  ///@return {?GMLayer}
  getLayer = function(name) {
    var layerId = layer_get_id(name)
    return layerId != -1 ? layerId : null
  }

  ///@param {String} name
  ///@param {Number} [defaultDepth]
  ///@return {GMLayer}
  factoryLayer = function(name, defaultDepth = 0.0) {
    return layer_create(Core.getIfType(defaultDepth, Number, 0.0), name)
  }

  ///@param {String} name
  ///@param {Number} [defaultDepth]
  ///@return {GMLayer}
  fetchLayer = function(name, defaultDepth = 0.0) {
    var layerId = this.getLayer(name)
    return layerId != -1 ? layerId : this.factoryLayer(name, defaultDepth)
  }
}
global.__Scene = new _Scene()
#macro Scene global.__Scene
