///@package io.alkapivo.core.uti

///@param {Number} _duration
///@param {Struct} [config]
function Timer(_duration, config = {}) constructor {

  ///@type {Number}
  time = 0

  ///@type {Number}
  loopCounter = 0

  ///@type {Boolean}
  finished = false

  ///@type {Number}
  duration = Assert.isType(_duration, Number)

  ///@type {Number}
  loop = Assert.isType(Struct.getDefault(config, "loop", 1), Number)

  ///@type {Number}
  amount = Assert.isType(Struct.getDefault(config, "amount", FRAME_MS), Number)

  ///@type {Callable}
  callback = Struct.contains(config, "callback")
    ? Assert.isType(config.callback, Callable)
    : null

  if (Struct.getDefault(config, "randomize", false)) {
    this.time = random(this.duration)
  }

  ///@param {any} [callbackData]
  ///@return {Timer}
  update = function(callbackData = null) {
    if (this.finished && (this.loop == Infinity || this.loopCounter < this.loop)) {
      this.finished = false;
    } else if (this.finished) {
      return this;
    }


    this.time += DeltaTime.apply(this.amount)
    if (this.time < this.duration) {
      return this
    }
    
    this.time = this.time - (this.duration * floor(this.time / this.duration))
    this.finished = true
    if (this.callback) {
      this.callback(callbackData, this)
    }

    if (this.loop != Infinity) {
      this.loopCounter++
    }
    return this
  }

  ///@return {Number}
  getProgress = function() {
    return this.finished ? 1.0 : clamp(this.time / this.duration, 0.0, 1.0)
  }

  ///@return {Timer}
  reset = function() {
    this.time = 0
    this.loopCounter = 0
    this.finished = false
    return this
  }
}