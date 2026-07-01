///@package io.alkapivo.core.util.store
show_debug_message("init StoreItemSubscriber.gml")


///@param {Struct} json
function StoreItemSubscriber(json) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {Callable}
  callback = Assert.isType(Struct.get(json, "callback"), Callable)

  ///@type {any}
  data = Struct.get(json, "data")
}
