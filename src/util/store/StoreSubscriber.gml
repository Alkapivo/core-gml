///@package io.alkapivo.core.util.store

///@param {Struct} json
function StoreSubscriber(json) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {Callable}
  callback = Assert.isType(Struct.get(json, "callback"), Callable)

  ///@type {any}
  data = Struct.get(json, "data")
}