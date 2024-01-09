///@package io.alkapivo.core.service.TrackService

///@param {?Struct} _context
///@param {Struct} [config]
function TrackService(_context, config = {}): Service() constructor {

  ///@type {Struct}
  context = Assert.isType(_context, Struct, "context")

  ///@type {?Track}
  track = null

  ///@type {Number}
  time = 0.0

  ///@type {Number}
  duration = 0.0

  ///@type {EventDispatcher}
  dispatcher = new EventDispatcher(this, new Map(String, Callable, {
    "load-track": function(event) {
      return this.applyTrack(Struct.get(event.data, "track")).track
    },
    "rewind-track": function(event) {
      return this.rewind(event.data.timestamp).track
    },
    "pause-track": function(event) {
      return this.pause().track
    },
    "resume-track": function(event) {
      this.resume()
      return this.track
    }
  }))

  ///@param {Event} event
  ///@return {TrackService}
  send = method(this, function(event) {
    if (!Core.isType(event.promise, Promise)) {
      event.promise = new Promise()
    }
    return this.dispatcher.send(event)
  })

  ///@param {Track} track
  ///@return {TrackService}
  ///@throws {InvalidAssertException}
  applyTrack = method(this, function(track) {
    this.stop()
    this.track = Assert.isType(track, Track)
    this.duration = this.track.audio.getLength()
    return this
  })

  ///@return {TrackService}
  removeTrack = method(this, function() {
    this.stop()
    this.track = null
    return this
  })

  ///@return {Boolean}
  isTrackLoaded = method(this, function() {
    return Core.isType(this.track, Track)
  })

  ///@return {TrackService}
  resume = method(this, function() {
    if (this.isTrackLoaded()) {
      this.track.audio.resume().setVolume(0.1, 1)
    }
    return this
  })

  ///@return {TrackService}
  pause = method(this, function() {
    if (this.isTrackLoaded()) {
      this.track.audio.pause()
    }
    return this
  })

  ///@return {TrackService}
  stop = method(this, function() {
    if (this.isTrackLoaded()) {
      this.track.audio.stop()
    }
    return this
  })

  ///@param {Number} timestamp
  ///@return {TrackService}
  rewind = method(this, function(timestamp) {
    if (this.isTrackLoaded) {
      this.track.rewind(timestamp)
      this.track.audio.rewind(timestamp)
    }
    return this
  })

  ///@return {TrackService}
  update = method(this, function() {
    this.dispatcher.update()
    if (this.isTrackLoaded()) {
      this.time = this.track.audio.getPosition()
      this.track.update(this.time)
    }
    return this
  })

  ///@return {Number}
  countEvents = function() {
    static sumChannelEvents = function(channel, name, counter) {
      counter.size += channel.events.size()
    }

    if (!this.isTrackLoaded()) {
      return 0
    }
    
    var counter = { size: 0 }
    this.track.channels.forEach(sumChannelEvents, counter)
    return counter.size
  }
}

