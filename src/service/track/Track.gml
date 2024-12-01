///@package io.alkapivo.core.service.track

///@static
///@type {Map<String, Callable>}
global.__DEFAULT_TRACK_EVENT_HANDLERS = new Map(String, Callable, {
  "dummy": function(data) {
    Core.print("Dummy track event, data:", data)
  },
})
#macro DEFAULT_TRACK_EVENT_HANDLERS global.__DEFAULT_TRACK_EVENT_HANDLERS


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
  audio = Assert.isType(SoundUtil.fetch(Struct.get(json, "audio"), { loop: false }), Sound)

  ///@private
  ///@param {Struct} channel
  ///@param {Number} index
  ///@param {?Struct} [config]
  ///@return {TrackChannel}
  parseTrackChannel = Core.isType(Struct.get(config, "parseTrackChannel"), Callable)
    ? method(this, config.parseTrackChannel)
    : function(channel, index, config = null) {
        //Logger.debug("Track", $"Parse channel '{channel.name}' at index {index}")
        return new TrackChannel({ 
          name: Assert.isType(Struct.get(channel, "name"), String),
          events: Assert.isType(Struct.get(channel, "events"), GMArray),
          index: index,
        }, config)
      }

  ///@type {Map<String, TrackChannel>}
  channels = new Map(String, TrackChannel)
  var context = this
  GMArray.forEach(Struct.get(json, "channels"), function(channel, index, acc) {
    var trackChannel = acc.context.parseTrackChannel(channel, index, acc.config)
    acc.context.channels.add(trackChannel, trackChannel.name)
  }, {
    context: context,
    config: config,
  })

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
  removeChannel = Core.isType(Struct.get(config, "removeChannel"), Callable)
    ? method(this, config.removeChannel)
    : function(name) {
      if (!this.channels.contains(name)) {
        return this
      }

      Logger.info("Track", $"Remove channel '{name}'")
      var index = this.channels.get(name).index
      this.channels.remove(name).forEach(function(channel, name, index) {
        if (channel.index > index) {
          channel.index = channel.index - 1
        }
      }, index)

      return this
    }
  
  ///@param {Number} timestamp
  ///@return {Track}
  rewind = method(this, Assert.isType(Struct
    .getDefault(config, "rewind", function(timestamp) {
      static rewindChannel = function(channel, name, timestamp) {
        channel.rewind(timestamp)
      }

      this.audio.rewind(timestamp)
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

      if (this.getStatus() == TrackStatus.PLAYING) {
        this.channels.forEach(updateChannel, timestamp)
      }

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
        "version": "1",
        "data": {
          "name": this.name,
          "audio": this.audio.name,
          "channels": this.channels
            .toArray(function(channel) {
              return channel  
            }, null, any)
            .sort(function(a, b) { 
              return a.index <= b.index
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

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {Number}
  index = Assert.isType(Struct.get(json, "index"), Number)

  ///@type {Boolean}
  muted = false

  ///@private
  ///@type {Number}
  time = 0.0

  ///@private
  ///@type {?Number}
  pointer = null

  ///@private
  ///@type {Number}
  MAX_EXECUTION_PER_FRAME = 99

  ///@private
  ///@param {Event}
  ///@param {Number} index
  ///@param {?Struct} [config]
  ///@return {TrackEvent}
  parseEvent = Optional.is(Struct.getIfType(config, "parseEvent", Callable))
    ? method(this, config.parseEvent)
    : function(event, index, config = null) {
      ///@description migration
      if (Core.getProperty("visu.editor.migrate", false)) {
        var icon = Struct.get(event.data, "icon")
        switch (Struct.get(event, "callable")) {
          case VEBrushType.SHADER_SPAWN:
            event.callable = VEBrushType.EFFECT_SHADER
            event.data = migrateShaderSpawnEvent(event.data)
            break
          case VEBrushType.VIEW_OLD_GLITCH:
            event.callable = VEBrushType.EFFECT_GLITCH
            event.data = migrateViewOldGlitchEvent(event.data)
            break
          case VEBrushType.GRID_OLD_PARTICLE:
            event.callable = VEBrushType.EFFECT_PARTICLE
            event.data = migrateGridOldParticleEvent(event.data)
            break
          case VEBrushType.SHADER_CONFIG:
            event.callable = VEBrushType.EFFECT_CONFIG
            event.data = migrateShaderConfigEvent(event.data)
            break
          case VEBrushType.SHROOM_SPAWN:
            event.callable = VEBrushType.ENTITY_SHROOM
            event.data = migrateShroomSpawnEvent(event.data)
            break
          case VEBrushType.GRID_OLD_COIN:
            event.callable = VEBrushType.ENTITY_COIN
            event.data = migrateGridOldCoinEvent(event.data)
            break
          case VEBrushType.GRID_OLD_PLAYER:
            event.callable = VEBrushType.ENTITY_PLAYER
            event.data = migrateGridOldPlayerEvent(event.data)
            break
        }
        Struct.set(event.data, "icon", icon)
      }
      
      return new TrackEvent(event, config)
    }
  
  ///@private
  ///@param {TrackEvent} a
  ///@param {TrackEvent} b
  ///@return {Boolean}
  compareEvents = Optional.is(Struct.getIfType(config, "compareEvents", Callable))
    ? method(this, config.compareEvents)
    : function(a, b) {
      return a.timestamp <= b.timestamp
    }

  ///@private
  ///@type {Array<TrackEvent>}
  events = GMArray.toArray(Struct
    .getDefault(json, "events", []), TrackEvent, this.parseEvent, config)
    .sort(compareEvents)

  ///@param {TrackEvent} event
  ///@return {TrackChannel}
  add = Optional.is(Struct.getIfType(config, "add", Callable))
    ? method(this, config.add)
    : function(event) {
      var size = this.events.size()
      for (var index = 0; index < size; index++) {
        if (event.timestamp < this.events.get(index).timestamp) {
          break
        }
      }
      
      var lastExecutedEvent = this.pointer != null ? this.events.get(this.pointer) : null
      this.events.add(event, index)
      if (lastExecutedEvent == null) {
        return this
      }

      size = this.events.size()
      for (var index = 0; index < size; index++) {
        if (this.events.get(index) == lastExecutedEvent) {
          this.pointer = index
          break
        }
      }

      return this
    }

  ///@param {TrackEvent} event
  ///@return {TrackChannel}
  remove = Optional.is(Struct.getIfType(config, "remove", Callable))
    ? method(this, config.remove)
    : function(event) {
      if (this.events.size() == 0) {
        return this
      }

      var size = this.events.size()
      for (var index = 0; index < size; index++) {
        if (this.events.get(index) == event) {
          break
        }

        if (index == this.events.size() - 1) {
          Logger.warn("TrackChannel", $"TrackEvent wasn't found. channel: '{this.name}'")
          return this
        }
      }

      var lastExecutedEvent = this.pointer != null ? this.events.get(this.pointer) : null
      var trackEvent = this.events.get(index)
      this.events.remove(index)
      Logger.debug("TrackChannel", $"TrackEvent removed: channel: '{this.name}', timestamp: {trackEvent.timestamp}, callable: '{trackEvent.callableName}'")
      if (this.pointer == null) {
        return this
      }

      if (lastExecutedEvent == event) {
        this.pointer = this.pointer == 0 ? null : this.pointer - 1
      } else {
        size = this.events.size()
        for (var index = 0; index < size; index++) {
          if (this.events.get(index) == lastExecutedEvent) {
            this.pointer = index
            break
          }
        }
      }
      return this
    }

  ///@param {Number} timestamp
  ///@return {TrackChannel}
  rewind = Optional.is(Struct.getIfType(config, "rewind", Callable))
    ? method(this, config.rewind)
    : function(timestamp) {
      var size = this.events.size()
      this.pointer = null
      this.time = timestamp
      for (var index = 0; index < size; index++) {
        this.pointer = index
        if (this.events.get(index).timestamp >= timestamp) {
          this.pointer = index == 0 ? null : index - 1
          break
        }
      }

      return this
    }

  ///@param {Number} timestamp
  ///@return {TrackChannel}
  update = Optional.is(Struct.getIfType(config, "update", Callable))
    ? method(this, config.update)
    : function(timestamp) {
      if (this.time > timestamp) {
        this.rewind(timestamp)
      }
      this.time = timestamp

      if (this.muted || events.size() == 0) {
        return this
      }

      for (var index = 0; index < this.MAX_EXECUTION_PER_FRAME; index++) {
        var pointer = this.pointer == null ? 0 : (this.pointer + 1)
        if (pointer == events.size()) {
          break
        }

        var event = events.get(pointer)
        if (timestamp >= event.timestamp) {
          this.pointer = pointer
          event.callable(event.data)
        } else {
          ///@todo execute events based on some dictionary
          break
        }
      }
      return this
    }

  ///@return {Struct}
  serialize = Optional.is(Struct.getIfType(config, "serialize", Callable))
    ? method(this, config.serialize)
    : function() {
      return {
        "name": this.name,
        "events": this.events.map(function(event) {
          return event.serialize()
        }).getContainer(),
      }
    }
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
  callable = Assert.isType((Struct.contains(config, "handlers") 
      ? Assert.isType(config.handlers, Map)
      : DEFAULT_TRACK_EVENT_HANDLERS)
    .get(this.callableName), Callable)

  ///@todo refactor
  ///@return {Struct}
  serialize = method(this, Assert.isType(Struct
    .getDefault(config, "serialize", function() {
      var json = {
        "timestamp": this.timestamp,
        "callable": this.callableName,
      }

      if (Core.isType(this.data, Struct)) {
        Struct.set(json, "data", Struct.map(this.data, function(value, key) {
          var serialize = Struct.get(value, "serialize")
          return Core.isType(serialize, Callable) 
            ? value.serialize() 
            : value
        }))
      }
      
      return json
    }), Callable))
}
