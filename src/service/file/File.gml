///@package io.alkapivo.core.service.file

///@param {Struct} json
function File(json) constructor {

  ///@type {String}
  name = Assert.isType(json.name, String)

  ///@type {String}
  path = Assert.isType(json.path, String)

  ///@type {any}
  data = Struct.getDefault(json, "data", null)

  ///@return {String}
  static getName = function() {
    return this.name
  }

  ///@param {String} name
  ///@return {File}
  static setName = function(name) {
    this.name = Assert.isType(name, String)
    return this
  }

  ///@return {String}
  static getPath = function() {
    return this.path
  }

  ///@param {String} path
  ///@return {File}
  static setPath = function(path) {
    this.path = Assert.isType(path, String)
    return this
  }

  ///@return {any}
  static getData = function() {
    return this.data
  }

  ///@param {any} data
  ///@return {File}
  static setData = function(data) {
    this.data = data
    return this
  }
}
