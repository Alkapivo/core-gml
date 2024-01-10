///@package io.alkapivo.core.util

///@enum
function _PromiseStatus(): Enum() constructor {
  PENDING = "pending"
  FULLFILLED = "fullfilled"
  REJECTED = "rejected"
}
global.__PromiseStatus = new _PromiseStatus()
#macro PromiseStatus global.__PromiseStatus


///@type {?Struct} [config]
function Promise(config = null) constructor {

  ///@type {any}
  state = null

  ///@type {PromiseStatus}
  status = Assert.isEnum(PromiseStatus.PENDING, PromiseStatus)

  ///@type {any}
  response = null

  ///@private
  ///@type {?Callable}
  onSuccess = method(this, function(data) { return data })

  ///@private
  ///@type {?Callable}
  onFailure = method(this, function(data) { return data })

  ///@return {Boolean}
  isReady = method(this, function() {
    return this.status != PromiseStatus.PENDING
  })

  ///@param {?Callable} resolve
  ///@return {Promise}
  whenSuccess = method(this, function(resolve) {
    this.onSuccess = resolve != null ? method(this, Assert.isType(resolve, Callable)) : null
    return this
  })
  this.whenSuccess(Struct.getDefault(config, "onSuccess", function(data) { return data }))

  ///@param {?Callable} reject
  ///@return {Promise}
  whenFailure = method(this, function(reject) {
    this.onFailure = reject != null ? method(this, Assert.isType(reject, Callable)) : null
    return this
  })
  this.whenFailure(Struct.getDefault(config, "onFailure", function(data) { return data }))

  ///@param {any} state
  ///@return {Promise}
  setState = method(this, function(state) {
    this.state = state
    return this
  })

  ///@param {PromiseStatus} status
  ///@return {Promise}
  setStatus = method(this, function(status) {
    if (PromiseStatus.contains(status)) {
      this.status = status
    }
    return this
  })

  ///@param {any} response
  ///@return {Promise}
  setResponse = method(this, function(response) {
    this.response = response
    return this
  })

  ///@param {any} [data]
  ///@return {Promise}
  fullfill = method(this, function(data = null) {
    return this.status == PromiseStatus.PENDING
      ? this.setStatus(PromiseStatus.FULLFILLED)
        .setResponse(Callable.run(this.onSuccess, data))
      : this
  })

  ///@param {any} [data]
  ///@return {Promise}
  reject = method(this, function(data = null) {
    return this
      .setStatus(PromiseStatus.REJECTED)
      .setResponse(Callable.run(this.onFailure, data))
  })
}
