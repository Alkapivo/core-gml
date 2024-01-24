///@package io.alkapivo.core.DeltaTime

///@static
function _DeltaTime() constructor {
	
	///@type {Number}
  deltaTime = 0
	
	///@type {Number}
  fpsMin = 2
	
	///@type {Number}
	deltaTimePrecision = 1000000.0
	
	///@type {Number}
	deltaTimePrevious = 0.0
	
	///@type {Boolean}
	deltaTimeRestored = false
  
  ///@param {Number} value
  ///@return {Number}
  static apply = function(value) {
    return this.deltaTime * value
  }

  ///@return {DeltaTime}
  static update = function() {
    this.deltaTimePrevious = this.deltaTime;
    this.deltaTime = delta_time / this.deltaTimePrecision;
    if (this.deltaTime > 1 / this.fpsMin) {
      if (this.deltaTimeRestored) {
        this.deltaTime = 1 / this.fpsMin;	
      } else {
        this.deltaTime = this.deltaTimePrevious;
        this.deltaTimeRestored = true;
      }
    } else {
      this.deltaTimeRestored = false;	
    }
    this.deltaTime = clamp(this.deltaTime * GAME_FPS, 1.0, 5.0);
    return this
  }
}
global.__DeltaTime = new _DeltaTime()
#macro DeltaTime global.__DeltaTime
