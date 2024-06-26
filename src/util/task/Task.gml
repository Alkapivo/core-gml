///@package io.alkapivo.core.util.task

///@param {String} _message
function TaskTimeoutException(_message): Exception(_message) constructor { }

///@enum
function _TaskStatus(): Enum() constructor {
  IDLE = "idle"
  RUNNING = "running"
  FULLFILLED = "fullfilled"
  REJECTED = "rejected"
}
global.__TaskStatus = new _TaskStatus()
#macro TaskStatus global.__TaskStatus

///@param {String} _name
///@param {Struct} [config]
function Task(_name, config = {}) constructor {

  ///@type {String}
  name = Assert.isType(_name, String)

  ///@type {TaskStatus}
  status = Assert.isEnum(TaskStatus.IDLE, TaskStatus)

  ///@type {any}
  state = null

  ///@private
  ///@type {?Timer}
  timeout = null

  ///@private
  ///@type {?Callable}
  onTimeout = null

  ///@private
  ///@type {?Timer}
  tick = null

  ///@private
  ///@type {?Callable}
  onUpdate = null

  ///@private
  ///@type {?Callable}
  onStart = null

  ///@private
  ///@type {?Callable}
  onFinish = null

  ///@type {?Promise}
  promise = null

  ///@param {?Callable} onStart
  ///@return {Task}
  whenStart = function(onStart) {
    this.onStart = onStart != null ? method(this, Assert.isType(onStart, Callable)) : null
    return this
  }
  this.whenStart(Core.isType(Struct.get(config, "onStart"), Callable) 
    ? config.onStart
    : null)
  
  ///@param {?Callable} onFinish
  ///@return {Task}
  whenFinish = function(onFinish) {
    this.onFinish = onFinish != null ? method(this, Assert.isType(onFinish, Callable)) : null
    return this
  }
  this.whenFinish(Core.isType(Struct.get(config, "onFinish"), Callable) 
    ? config.onFinish
    : null)

  ///@param {Callable} onUpdate
  ///@return {Task}
  whenUpdate = function(onUpdate) {
    this.onUpdate = method(this, Assert.isType(onUpdate, Callable))
    return this
  }
  this.whenUpdate(Core.isType(Struct.get(config, "onUpdate"), Callable) 
    ? config.onUpdate 
    : method(this, function() {
      Core.print("Dummy onUpdate task", this.name)
    }))

  ///@param {?Callable} onTimeout
  ///@return {Task}
  whenTimeout = function(onTimeout) {
    this.onTimeout = onTimeout != null ? method(this, Assert.isType(onTimeout, Callable)) : null
    return this
  }
  this.whenTimeout(Core.isType(Struct.get(config, "onTimeout"), Callable) 
    ? config.onTimeout
    : null)

  ///@param {?Number} timeout
  ///@return {Task}
  setTimeout = function(timeout) {
    this.timeout = Core.isType(timeout, Number) ? new Timer(timeout) : null
    return this
  }
  this.setTimeout(Struct.get(config, "timeout"))

  ///@param {?Number} tick
  ///@return {Task}
  setTick = function(tick) {
    this.tick = Core.isType(tick, Number) ? new Timer(tick, { loop: Infinity }) : null
    return this
  }
  this.setTick(Struct.get(config, "tick"))

  ///@param {any} state
  ///@return {Task}
  setState = function(state) {
    this.state = state
    return this
  }
  this.setState(Struct.get(config, "state"))

  ///@param {?Promise} promise
  ///@return {Task}
  setPromise = function(promise) {
    this.promise = promise != null ? Assert.isType(promise, Promise) : null
    return this
  }
  this.setPromise(Struct.get(config, "promise"))

  ///@param {any} [data]
  ///@return {Task}
  fullfill = function(data = null) {
    this.status = TaskStatus.FULLFILLED
    if (Core.isType(this.onFinish, Callable)) {
      this.onFinish(data)
    }

    if (Core.isType(this.promise, Promise)) {
      this.promise.fullfill(data)
    }
    return this
  }

  ///@param {any} [data]
  ///@return {Task}
  reject = function(data = null) {
    this.status = TaskStatus.REJECTED
    if (Core.isType(this.onFinish, Callable)) {
      this.onFinish(data)
    }

    if (Core.isType(this.promise, Promise)) {
      this.promise.reject(data)
    }
    return this
  }

  ///@param {TaskExecutor} executor
  ///@return {Task}
  ///@throws {TaskTimeoutException}
  update = function(executor = null) {
    if (this.timeout != null) {
      this.timeout.update()
    }

    if (this.tick != null && !this.tick.update().finished) {
      return this
    }

    this.onUpdate(executor)

    if (this.timeout != null && this.timeout.finished) {
      if (Core.isType(this.onTimeout, Callable)) {
        this.onTimeout(executor)
      } else {
        throw new TaskTimeoutException($"Timer state: {this.timeout.serialize()}")
      }
    }
    return this
  }
}
