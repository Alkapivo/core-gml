///@package io.alkapivo.core.service

///@param {Controller} _controller
///@param {Struct} [config]
function DisplayService(_controller, config = {}): Service() constructor {

  ///@type {Controller}
  controller = Assert.isType(_controller, Struct)

  ///@private
	///@type {Number}
	previousWidth = 0;
	
  ///@private
	///@type {Number}
	previousHeight = 0;

  ///@private
  ///@type {String}
	state = "idle"

  ///@private
  ///@type {Timer}
  timer = new Timer(FRAME_MS * 20)

  ///@return {Number}
  getWidth = function() {
    return window_get_width()
  }

  ///@return {Number}
  getHeight = function() {
    return window_get_height()
  }

  ///@return {Number}
  getDisplayWidth = function() {
    return display_get_width()
  }

  ///@return {Number}
  getDisplayHeight = function() {
    return display_get_height()
  }

  ///@return {Boolean}
  getFullscreen = function() {
    return window_get_fullscreen()
  }

  ///@return {DisplayService}
  setFullscreen = function(enable) {
    if (this.getFullscreen() != enable) {
      window_set_fullscreen(enable)
    }
    return this
  }

  ///@param {Number} width
  ///@param {Number} height
  ///@return {DisplayService}
  resize = function(width, height) {
    try {
      if (width < 2 || height < 2) {
        throw new Exception($"Cannot resize to: \{ \"width\": {width}, \"height\": {height} \}")
      }
      display_set_gui_size(width, height)
      window_set_size(width, height)
      surface_resize(application_surface, width, height)
    } catch (exception) {
      Logger.error("[ResizeEvent]", exception.message)
    }
    return this
  }

  ///@return {DisplayService}
  update = function() {
    static isResizeRequired = function(context) {
      return context.previousWidth != display_get_gui_width()
        || context.previousHeight != display_get_gui_height()
    }

    if (this.state == "idle") {
      this.state = isResizeRequired(this)
        ? "required"
        : "idle"
    }

    if (this.state == "required") {
      if (this.timer.update().finished) {
        var width = window_get_width()
        var height = window_get_height()
        Logger.debug("DisplayService", $"Resize from {this.previousWidth}x{this.previousHeight} to {width}x{height}.")
        this.resize(width, height)
        this.timer.reset()
        this.state = "idle"
      }
    }

    if (this.state == "idle") {
      this.previousWidth = window_get_width()
      this.previousHeight = window_get_height()
    }
    return this
  }
}
