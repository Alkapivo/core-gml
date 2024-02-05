///@package io.alkapivo.core.service.track

///@enum
function _TrackStatus(): Enum() constructor {
  PLAYING = "playing"
  PAUSED = "paused"
  STOPPED = "stopped"
}
global.__TrackStatus = new _TrackStatus()
#macro TrackStatus global.__TrackStatus

///@param {Struct} json
///@param {?Struct} [config]
function Track(json, config = null) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {Sound}
  audio = Assert.isType(SoundUtil.fetch(Struct.get(json, "audio")), Sound)

  ///@private
  ///@param {Struct} channel
  ///@param {Number} index
  ///@return {TrackChannel}
  parseTrackChannel = method(this, Assert.isType(Struct
    .getDefault(config, "parseTrackChannel", function(channel, index) {
      Logger.debug("Track", $"Parse channel '{channel.name}' at index {index}")
      return new TrackChannel({ 
        name: Assert.isType(Struct.get(channel, "name"), String),
        events: Assert.isType(Struct.get(channel, "events"), GMArray),
        index: index,
      })
    }), Callable))

  ///@type {Map<String, TrackChannel>}
  channels = new Map(String, TrackChannel)
  GMArray.forEach(Struct.get(json, "channels"), function(channel, index, context) {
    var trackChannel = context.parseTrackChannel(channel, index)
    context.channels.add(trackChannel, trackChannel.name)
  }, this)

  ///@private
  ///@param {String} name
  ///@return {TrackChannel}
  injectTrackChannel = method(this, Assert.isType(Struct
    .getDefault(config, "injectTrackChannel", function(name) {
      return this.channels.contains(name)
        ? this.channels.get(name)
        : this.channels.set(name, this.parseTrackChannel({ 
            name: name, 
            events: []
          }, this.channels.size())).get(name)
    }), Callable))

  ///@param {String} name
  ///@param {TrackEvent} event
  ///@return {Track}
  addEvent = method(this, Assert.isType(Struct
    .getDefault(config, "add", function(name, event) {
      this.injectTrackChannel(name).add(event)
      return this
    }), Callable))

  ///@param {String} channelName
  ///@param {TrackEvent} event
  ///@return {Track}
  removeEvent = method(this, Assert.isType(Struct
    .getDefault(config, "remove", function(channelName, event) {
      this.injectTrackChannel(channelName).remove(event)
      return this
    }), Callable))

  ///@param {String} name
  ///@return {Track}
  addChannel = method(this, Assert.isType(Struct
    .getDefault(config, "addChannel", function(name) {
      if (this.channels.contains(name)) {
        return this
      }

      this.injectTrackChannel(name)
      return this
    }), Callable))

  ///@param {String} name
  ///@return {Track}
  removeChannel = method(this, Assert.isType(Struct
    .getDefault(config, "removeChannel", function(name) {
      if (!this.channels.contains(name)) {
        return this
      }

      Logger.info("Track", $"Remove channel '{name}'")
      this.channels.remove(name)
      return this
    }), Callable))
  
  ///@param {Number} timestamp
  ///@return {Track}
  rewind = method(this, Assert.isType(Struct
    .getDefault(config, "rewind", function(timestamp) {
      static rewindChannel = function(channel, name, timestamp) {
        channel.rewind(timestamp)
      }

      this.channels.forEach(rewindChannel, timestamp)
      return this
    }), Callable))

  ///@param {Number} timestamp
  ///@return {Track}
  update = method(this, Assert.isType(Struct
    .getDefault(config, "update", function(timestamp) {
      static updateChannel = function(channel, name, timestamp) {
        channel.update(timestamp)
      }

      this.channels.forEach(updateChannel, timestamp)
      return this
    }), Callable))

  ///@return {TrackStatus}
  getStatus = method(this, Assert.isType(Struct
    .getDefault(config, "getStatus", function() {
      if (!Core.isType(this.audio, Sound)) {
        return TrackStatus.STOPPED
      }

      if (this.audio.isPlaying()) {
        return TrackStatus.PLAYING
      }

      if (this.audio.isPaused()) {
        return TrackStatus.PAUSED
      }

      return TrackStatus.STOPPED     
    }), Callable))

  ///@return {String}
  serialize = method(this, Assert.isType(Struct
    .getDefault(config, "serialize", function() {
      return JSON.stringify({
        "model": "io.alkapivo.core.service.track.Track",
        "data": {
          "name": this.name,
          "audio": this.audio.name,
          "channels": this.channels
            .toArray(function(channel) {
              return channel  
            }, null, any)
            .sort(function(a, b) { 
              return a.index < b.index
            })
            .map(function(channel) { 
              return channel.serialize()
            })
            .getContainer(),
        }
      }, { pretty: true })
    }), Callable))
}

///@param {Struct} json
///@param {?Struct} [config]
function TrackChannel(json, config = null) constructor {

  ///@private
  ///@param {Event}
  ///@return {TrackEvent}
  parseEvent = method(this, Assert.isType(Struct
    .getDefault(config, "parseEvent", function(event) {
      return new TrackEvent(event)
    }), Callable))
  
  ///@private
  ///@param {TrackEvent} a
  ///@param {TrackEvent} b
  ///@return {Boolean}
  compareEvents = method(this, Assert.isType(Struct
    .getDefault(config, "compareEvents", function(a, b) { 
      return a.timestamp < b.timestamp
    }), Callable))

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {Number}
  index = Assert.isType(Struct.get(json, "index"), Number)

  ///@type {Array<TrackEvent>}
  events = GMArray.toArray(Struct
    .getDefault(json, "events", []), TrackEvent, parseEvent)
    .sort(compareEvents)

  ///@private
  ///@type {Number}
  time = 0.0

  ///@private
  ///@type {?Number}
  pointer = null

  ///@private
  ///@type {Number}
  MAX_EXECUTION_PER_FRAME = 99

  ///@param {TrackEvent} event
  ///@return {TrackChannel}
  add = method(this, Assert.isType(Struct
    .getDefault(config, "add", function(event) {
      for (var index = 0; index < events.size(); index++) {
        if (event.timestamp < events.get(index).timestamp) {
          break
        }
      }
      var lastExecutedEvent = this.pointer != null ? events.get(this.pointer) : null
      events.add(event, index)
      if (lastExecutedEvent == null) {
        return this
      }

      for (var index = 0; index < events.size(); index++) {
        if (events.get(index) == lastExecutedEvent) {
          this.pointer = index
          break
        }
      }
      return this
    }), Callable))

  ///@param {TrackEvent} event
  ///@return {TrackChannel}
  remove = method(this, Assert.isType(Struct
    .getDefault(config, "remove", function(event) {
      if (this.events.size() == 0) {
        return this
      }

      for (var index = 0; index < events.size(); index++) {
        if (this.events.get(index) == event) {
          break
        }
        if (index == this.events.size() - 1) {
          return this
        }
      }
      var lastExecutedEvent = this.pointer != null ? this.events.get(this.pointer) : null
      var trackEvent = this.events.get(index)
      this.events.remove(index)
      Logger.debug("Track", $"TrackEvent removed: channel: '{this.name}', timestamp: {trackEvent.timestamp}, callable: '{trackEvent.callableName}'")
      if (this.pointer == null) {
        return this
      }

      if (lastExecutedEvent == event) {
        this.pointer = this.pointer == 0 ? null : this.pointer - 1
      } else {
        for (var index = 0; index < this.events.size(); index++) {
          if (this.events.get(index) == lastExecutedEvent) {
            this.pointer = index
            break
          }
        }
      }
      return this
    }), Callable))

  ///@param {Number} timestamp
  ///@return {TrackChannel}
  rewind = method(this, Assert.isType(Struct
    .getDefault(config, "rewind", function(timestamp) {
      this.pointer = null
      this.time = timestamp
      for (var index = 0; index < events.size(); index++) {
        this.pointer = index
        if (events.get(index).timestamp > timestamp) {
          this.pointer = index == 0 ? null : index - 1
          break
        }
      }
      return this
    }), Callable))

  ///@param {Number} timestamp
  ///@return {TrackChannel}
  update = method(this, Assert.isType(Struct
    .getDefault(config, "update", function(timestamp) {
      if (this.time > timestamp) {
        this.rewind(timestamp)
      }
      this.time = timestamp

      if (events.size() == 0) {
        return this
      }

      for (var index = 0; index < this.MAX_EXECUTION_PER_FRAME; index++) {
        var pointer = this.pointer == null ? 0 : this.pointer + 1
        if (pointer == events.size()) {
          break
        }

        var event = events.get(pointer)
        if (timestamp >= event.timestamp) {
          this.pointer = pointer
          event.callable(event.data)
        } else {
          break
        }
      }
      return this
    }), Callable))

  ///@return {Struct}
  serialize = method(this, Assert.isType(Struct
    .getDefault(config, "toTemplate", function() {
      return {
        "name": this.name,
        "events": this.events.map(function(event) {
          return event.serialize()
        }).getContainer(),
      }
    }), Callable))
}

///@param {Struct} json
///@param {?Struct} [config]
function TrackEvent(json, config = null): Event("TrackEvent") constructor {

  ///@type {Number}
  timestamp = Assert.isType(Struct.get(json, "timestamp"), Number)

  ///@override
  ///@type {Struct}
  data = Assert.isType(Struct.getDefault(json, "data", {}), Struct)

  ///@type {String}
  callableName = Struct.getDefault(json, "callable", "dummy")

  ///@type {Callable}
  callable = Assert.isType(Struct.get(TRACK_EVENT_HANDLERS, this.callableName), Callable)

  ///@todo refactor
  ///@return {Struct}
  serialize = method(this, Assert.isType(Struct
    .getDefault(config, "toTemplate", function() {
      var json = {
        "timestamp": this.timestamp,
        "callable": this.callableName,
      }

      if (Core.isType(this.data, Struct)) {
        Struct.set(json, "data", Struct.map(this.data, function(value, key) {
          var serialize = Struct.get(value, "serialize")
          return Core.isType(serialize, Callable) ? value.serialize() : value
        }))
      }
      
      return json
    }), Callable))
}

///@type {Struct}
global.__TRACK_EVENT_HANDLERS = {
  "dummy": function(data) {
    Core.print("dummy")
  },
  "brush_shader_spawn": function(data) {
    var controller = Beans.get(BeanVisuController)
    var pipeline = Struct.getDefault(data, "shader-spawn_pipeline", "Grid")
    var event = new Event("spawn-shader", {
      template: Struct.get(data, "shader-spawn_template"),
      duration: Struct.get(data, "shader-spawn_duration"),
    })
    
    switch (pipeline) {
      case "Grid": 
        controller.shaderPipeline.send(event)
        break
      case "Background":
        controller.shaderBackgroundPipeline.send(event)
        break
      case "All": 
        controller.shaderPipeline.send(event)
        controller.shaderBackgroundPipeline.send(new Event("spawn-shader", {
          template: Struct.get(data, "shader-spawn_template"),
          duration: Struct.get(data, "shader-spawn_duration"),
        }))
        break
      default: throw new Exception($"Found unsupported pipeline: {pipeline}")
    }
  },
  "brush_shader_overlay": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "shader-overlay_use-render-support-grid") == true) {
      controller.gridService.properties.renderSupportGrid = Struct.get(data, "shader-overlay_render-support-grid")
    }

    if (Struct.get(data, "shader-overlay_use-transform-support-grid-treshold") == true) {
      var transformer = Struct.get(data, "shader-overlay_transform-support-grid-treshold")
      controller.gridService.send(new Event("transform-property", {
        key: "renderSupportGridTreshold",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.renderSupportGridTreshold,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "shader-overlay_use-transform-support-grid-alpha") == true) {
      var transformer = Struct.get(data, "shader-overlay_transform-support-grid-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "renderSupportGridAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.renderSupportGridAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "shader-overlay_use-clear-frame") == true) {
      controller.gridService.properties.shaderClearFrame = Struct.get(data, "shader-overlay_clear-frame")
    }

    if (Struct.get(data, "shader-overlay_use-clear-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "shaderClearColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.shaderClearColor.toHex(true),
          target: Struct.get(data, "shader-overlay_clear-color"),
          factor: 0.01,
        })
      }))
    }

    if (Struct.get(data, "shader-overlay_use-transform-clear-frame-alpha") == true) {
      var transformer = Struct.get(data, "shader-overlay_transform-clear-frame-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "shaderClearFrameAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.shaderClearFrameAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
  },
  "brush_shader_clear": function(data) {
    static fadeOutTask = function(task) {
      var fadeOut = task.state.getDefault("fadeOut", 0.0)
      if (task.timeout.time < task.timeout.duration - fadeOut) {
        task.timeout.time = task.timeout.duration - fadeOut
      }
    }

    static amountTask = function(task, iterator, acc) {
      if (acc.amount <= 0) {
        return BREAK_LOOP
      }

      if (task.timeout.time < task.timeout.duration 
         - task.state.getDefault("fadeOut", 0.0)) {
        acc.handler(task)
        acc.amount = acc.amount - 1
      }
    }

    var controller = Beans.get(BeanVisuController)
    var pipeline = Struct.getDefault(data, "shader-spawn_pipeline", "All")    
    if (Struct.get(data, "shader-clear_use-clear-all-shaders") == true) {
      switch (pipeline) {
        case "Grid":
          controller.shaderPipeline.executor.tasks.forEach(fadeOutTask)
          break
        case "Background":
          controller.shaderBackgroundPipeline.executor.tasks.forEach(fadeOutTask)
          break
        case "All":
          controller.shaderPipeline.executor.tasks.forEach(fadeOutTask)
          controller.shaderBackgroundPipeline.executor.tasks.forEach(fadeOutTask)
          break
      }
    }

    if (Struct.get(data, "shader-clear_use-clear-amount") == true) {
      var amount = Struct.getDefault(data, "shader-clear_clear-amount", 1)
      switch (pipeline) {
        case "Grid":
          controller.shaderPipeline.executor.tasks.forEach(amountTask, {
            amount: amount,
            handler: fadeOutTask,
          })
          break
        case "Background":
          controller.shaderBackgroundPipeline.executor.tasks.forEach(amountTask, {
            amount: amount,
            handler: fadeOutTask,
          })
          break
        case "All":
          controller.shaderPipeline.executor.tasks.forEach(amountTask, {
            amount: amount,
            handler: fadeOutTask,
          })
          controller.shaderBackgroundPipeline.executor.tasks.forEach(amountTask, {
            amount: amount,
            handler: fadeOutTask,
          })
          break
      }
    }
  },
  "brush_shader_config": function(data) {
    if (Struct.get(data, "shader-config_use-render-grid-shaders") == true) {
      controller.gridService.properties.renderGridShaders = Struct.get(data, "shader-config_render-grid-shaders")
    }

    if (Struct.get(data, "shader-config_use-render-background-shaders") == true) {
      controller.gridService.properties.renderBackgroundShaders = Struct.get(data, "shader-config_render-background-shaders")
    }

    /* 
    if (Struct.get(data, "grid-config_use-clear-frame") == true) {
      controller.gridService.properties.gridClearFrame = Struct.get(data, "grid-config_clear-frame")
    }

    if (Struct.get(data, "shader-config_use-transform-shader-alpha") == true) {
      var transformer = Struct.get(data, "shader-config_transform-shader-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "renderSupportGridAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.renderSupportGridAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    */
  },
  "brush_shroom_spawn": function(data) {
    ///@description composition
    var shroom = {
      template: Struct.get(data, "shroom-spawn_template"),
      spawnX: Struct.get(data, "shroom-spawn_spawn-x"),
      spawnY: Struct.get(data, "shroom-spawn_spawn-y"),
      angle: Struct.get(data, "shroom-spawn_angle"),
      speed: Struct.get(data, "shroom-spawn_speed"),
    }
    Beans.get(BeanVisuController).shroomService
      .send(new Event("spawn-shroom", shroom))

    ///@description ecs
    /*
    var controller = Beans.get(BeanVisuController)
    controller.gridSystem.add(new GridEntity({
      type: GridEntityType.ENEMY,
      position: { 
        x: controller.gridService.view.x + Struct.get(data, "shroom-spawn_spawn-x"), 
        y: controller.gridService.view.y + Struct.get(data, "shroom-spawn_spawn-y"),
      },
      velocity: { 
        speed: Struct.get(data, "shroom-spawn_speed") / 1000, 
        angle: Struct.get(data, "shroom-spawn_angle"),
      },
      renderSprite: { name: "texture_baron" },
    }))
    */
  },
  "brush_shroom_clear": function(data) {
    Core.print("todo:", "brush_shroom_clear", "event")
  },
  "brush_shroom_config": function(data) {
    Core.print("todo:", "brush_shroom_config", "event")
  },
  "brush_view_wallpaper": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "view-wallpaper_use-color") == true) {
      controller.gridService.send(new Event("fade-color", {
        color: ColorUtil.fromHex(Struct.get(data, "view-wallpaper_color")),
        collection: Struct.get(data, "view-wallpaper_type") == "Background" 
          ? controller.gridRenderer.overlayRenderer.backgroundColors
          : controller.gridRenderer.overlayRenderer.foregroundColors,
        type: Struct.get(data, "view-wallpaper_type"),
        fadeInSpeed: Struct.get(data, "view-wallpaper_fade-in-speed"),
        fadeOutSpeed: Struct.get(data, "view-wallpaper_fade-out-speed"),
        executor: controller.gridService.executor,
      }))
    }

    if (Struct.get(data, "view-wallpaper_clear-color") == true) {
      controller.gridService.executor.tasks.forEach(function(task, iterator, type) {
        if (task.name == "fade-color" && task.state.get("type") == type) {
          task.state.set("stage", "fade-out")
        }
      }, Struct.get(data, "view-wallpaper_type"))
    }

    if (Struct.get(data, "view-wallpaper_use-texture") == true) {
      var sprite = Struct.get(data, "view-wallpaper_texture")
      var animate = Struct.get(data, "view-wallpaper_use-texture-speed")
      if (animate) {
        Struct.set(sprite, "animate", animate)
        Struct.set(sprite, "speed", Struct.get(data, "view-wallpaper_texture-speed"))
      }
      
      controller.gridService.send(new Event("fade-sprite", {
        sprite: SpriteUtil.parse(sprite),
        collection: Struct.get(data, "view-wallpaper_type") == "Background" 
          ? controller.gridRenderer.overlayRenderer.backgrounds
          : controller.gridRenderer.overlayRenderer.foregrounds,
        type: Struct.get(data, "view-wallpaper_type"),
        fadeInSpeed: Struct.get(data, "view-wallpaper_fade-in-speed"),
        fadeOutSpeed: Struct.get(data, "view-wallpaper_fade-out-speed"),
        executor: controller.gridService.executor,
      }))
    }

    if (Struct.get(data, "view-wallpaper_clear-texture") == true) {
      controller.gridService.executor.tasks.forEach(function(task, iterator, type) {
        if (task.name == "fade-sprite" && task.state.get("type") == type) {
          task.state.set("stage", "fade-out")
        }
      }, Struct.get(data, "view-wallpaper_type"))
    }
  },
  "brush_view_camera": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "view-config_use-lock-target") == true) {
      controller.editor.store
        .get("target-locked")
        .set(Struct.get(data, "view-config_lock-target"))
    }

    if (Struct.get(data, "view-config_use-transform-x") == true) {
      var transformer = Struct.get(data, "view-config_transform-x")
      controller.gridService.send(new Event("transform-property", {
        key: "x",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.x,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "view-config_use-transform-y") == true) {
      var transformer = Struct.get(data, "view-config_transform-y")
      controller.gridService.send(new Event("transform-property", {
        key: "y",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.y,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "view-config_use-transform-z") == true) {
      var transformer = Struct.get(data, "view-config_transform-z")
      controller.gridService.send(new Event("transform-property", {
        key: "z",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.z,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "view-config_use-transform-zoom") == true) {
      var transformer = Struct.get(data, "view-config_transform-zoom")
      controller.gridService.send(new Event("transform-property", {
        key: "zoom",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.zoom,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "view-config_use-transform-angle") == true) {
      var transformer = Struct.get(data, "view-config_transform-angle")
      controller.gridService.send(new Event("transform-property", {
        key: "angle",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.angle,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    
    if (Struct.get(data, "view-config_use-transform-pitch") == true) {
      var transformer = Struct.get(data, "view-config_transform-pitch")
      controller.gridService.send(new Event("transform-property", {
        key: "pitch",
        container: controller.gridRenderer.camera,
        executor: controller.gridRenderer.camera.executor,
        transformer: new NumberTransformer({
          value: controller.gridRenderer.camera.pitch,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
  },
  "brush_view_lyrics": function(data) {
    var controller = Beans.get(BeanVisuController)

    var align = { v: VAlign.TOP, h: HAlign.LEFT }
    var alignV = Struct.get(data, "view-lyrics_align-v")
    var alignH = Struct.get(data, "view-lyrics_align-h")
    if (alignV == "BOTTOM") {
      align.v = VAlign.BOTTOM
    }
    if (alignH == "CENTER") {
      align.h = HAlign.CENTER
    } else if (alignH == "RIGHT") {
      align.h = HAlign.RIGHT
    }

    controller.lyricsService.send(new Event("add")
      .setData({
        template: Struct.get(data, "view-lyrics_template"),
        font: FontUtil.fetch(Struct.get(data, "view-lyrics_font")).asset,
        fontHeight: Struct.get(data, "view-lyrics_font-height"),
        charSpeed: Struct.get(data, "view-lyrics_char-speed"),
        color: ColorUtil.fromHex(Struct.get(data, "view-lyrics_color")).toGMColor(),
        outline: Struct.get(data, "view-lyrics_use-outline")
          ? ColorUtil.fromHex(Struct.get(data, "view-lyrics_outline")).toGMColor()
          : null,
        timeout: Struct.get(data, "view-lyrics_use-timeout")
          ? Struct.get(data, "view-lyrics_timeout")
          : null,
        align: align,
        area: new Rectangle({ 
          x: Struct.get(data, "view-lyrics_x"),
          y: Struct.get(data, "view-lyrics_y"),
          width: Struct.get(data, "view-lyrics_width"),
          height: Struct.get(data, "view-lyrics_height"),
        }),
        lineDelay: Struct.get(data, "view-lyrics_use-line-delay")
          ? new Timer(Struct.get(data, "view-lyrics_line-delay"))
          : null,
        finishDelay: Struct.get(data, "view-lyrics_use-finish-delay")
          ? new Timer(Struct.get(data, "view-lyrics_finish-delay"))
          : null,
      }))
  },
  "brush_view_config": function(data) {
    var controller = Beans.get(BeanVisuController)
    var bktGlitchService = controller.gridRenderer.bktGlitchService
    if (Struct.get(data, "view-config_bkt-trigger") == true) {
      var event = new Event("spawn")
      if (Struct.get(data, "view-config_bkt-use-factor") == true) {
        event.setData({ factor: Struct.get(data, "view-config_bkt-factor")})
      }
      bktGlitchService.send(event)
    }

    if (Struct.get(data, "view-config_bkt-use-config") == true) {
      var config = bktGlitchService.configs.get(Struct.get(data, "view-config_bkt-config"))
      if (Optional.is(config)) {
        bktGlitchService.send(new Event("load-config").setData(config))
      }
    }
  },
  "brush_grid_channel": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "grid-channel_use-transform-amount") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-amount")
      controller.gridService.send(new Event("transform-property", {
        key: "channels",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.channels,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-transform-z") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-z")
      controller.gridService.send(new Event("transform-property", {
        key: "channelZ",
        container: controller.gridService.properties.depths,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.depths.channelZ,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-primary-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "channelsPrimaryColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.gridClearColor.toHex(true),
          target: Struct.get(data, "grid-channel_primary-color"),
          factor: Struct.getDefault(data, "grid-channel_primary-color-speed", 0.01),
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-transform-primary-alpha") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-primary-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "channelsPrimaryAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.channelsPrimaryAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-transform-primary-size") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-primary-size")
      controller.gridService.send(new Event("transform-property", {
        key: "channelsPrimaryThickness",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.channelsPrimaryThickness,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "grid-channel_use-secondary-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "channelsSecondaryColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.gridClearColor.toHex(true),
          target: Struct.get(data, "grid-channel_secondary-color"),
          factor: Struct.getDefault(data, "grid-channel_secondary-color-speed", 0.01),
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-transform-secondary-alpha") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-secondary-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "channelsSecondaryAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.channelsSecondaryAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-channel_use-transform-secondary-size") == true) {
      var transformer = Struct.get(data, "grid-channel_transform-secondary-size")
      controller.gridService.send(new Event("transform-property", {
        key: "channelsSecondaryThickness",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.channelsSecondaryThickness,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
  },
  "brush_grid_config": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "grid-config_use-render-grid") == true) {
      controller.gridService.properties.renderGrid = Struct.get(data, "grid-config_render-grid")
    }
    
    if (Struct.get(data, "grid-config_use-transform-speed") == true) {
      var transformer = Struct.get(data, "grid-config_transform-speed")
      controller.gridService.send(new Event("transform-property", {
        key: "speed",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.speed,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "grid-config_use-clear-frame") == true) {
      controller.gridService.properties.gridClearFrame = Struct.get(data, "grid-config_clear-frame")
    }

    if (Struct.get(data, "grid-config_use-clear-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "gridClearColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.gridClearColor.toHex(true),
          target: Struct.get(data, "grid-config_clear-color"),
          factor: 0.01,
        })
      }))
    }
    
    if (Struct.get(data, "grid-config_use-transform-clear-frame-alpha") == true) {
      var transformer = Struct.get(data, "grid-config_transform-clear-frame-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "gridClearFrameAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.gridClearFrameAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
  },
  "brush_grid_separator": function(data) {
    var controller = Beans.get(BeanVisuController)
    if (Struct.get(data, "grid-separator_use-transform-amount") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-amount")
      controller.gridService.send(new Event("transform-property", {
        key: "separators",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.separators,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-transform-z") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-z")
      controller.gridService.send(new Event("transform-property", {
        key: "separatorZ",
        container: controller.gridService.properties.depths,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.depths.channelZ,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-primary-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsPrimaryColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.gridClearColor.toHex(true),
          target: Struct.get(data, "grid-separator_primary-color"),
          factor: Struct.getDefault(data, "grid-separator_primary-color-speed", 0.01),
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-transform-primary-alpha") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-primary-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsPrimaryAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.separatorsPrimaryAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-transform-primary-size") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-primary-size")
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsPrimaryThickness",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.separatorsPrimaryThickness,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
    
    if (Struct.get(data, "grid-separator_use-secondary-color") == true) {
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsSecondaryColor",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new ColorTransformer({
          value: controller.gridService.properties.gridClearColor.toHex(true),
          target: Struct.get(data, "grid-separator_secondary-color"),
          factor: Struct.getDefault(data, "grid-separator_secondary-color-speed", 0.01),
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-transform-secondary-alpha") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-secondary-alpha")
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsSecondaryAlpha",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.separatorsSecondaryAlpha,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }

    if (Struct.get(data, "grid-separator_use-transform-secondary-size") == true) {
      var transformer = Struct.get(data, "grid-separator_transform-secondary-size")
      controller.gridService.send(new Event("transform-property", {
        key: "separatorsSecondaryThickness",
        container: controller.gridService.properties,
        executor: controller.gridService.executor,
        transformer: new NumberTransformer({
          value: controller.gridService.properties.separatorsSecondaryThickness,
          target: transformer.target,
          factor: transformer.factor,
          increase: transformer.increase,
        })
      }))
    }
  },
}
#macro TRACK_EVENT_HANDLERS global.__TRACK_EVENT_HANDLERS
