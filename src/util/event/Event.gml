///@package io.alkapivo.core.event

///@param {String} _name
///@param {any} [_data]
///@param {?Promise} [_promise]
function Event(_name, _data = null, _promise = null) constructor {

  ///@type {String}
  name = Assert.isType(_name, String)

  ///@type {any}
  data = null
  
  ///@type {?Promise}
  promise = null

  ///@param {any} data
  ///@return {Event}
  setData = function(data) {
    this.data = data
    return this
  }
  this.setData(_data)

  ///@param {?Promise} promise
  ///@return {Event}
  setPromise = function(promise = null) {
    this.promise = Assert.isType(promise, Optional.of(Promise))
    return this
  }
  this.setPromise(_promise)
}

///@static
///@type {Struct}
global.__EVENT_DISPATCHERS = {
  "transform-property": function() {
    return function(event) {
      static fullfillExistingTask = function(task, index, name) {
        if (task.name == name) {
          task.fullfill("New task arrived for name: '{name}'")
        }
      }

      var container = Assert.isType(Struct.get(event.data, "container"), Struct)
      if (!Struct.contains(container, event.name)) {
        throw new PropertyNotFoundException(event.name)
      }

      var task = new Task(event.name)
        .setState(new Map(String, any, {
          container: container,
          source: Assert.isType(Struct.get(container, event.name), Number),
          target: Assert.isType(Struct.get(event.data, "target"), Number),
          factor: Assert.isType(Struct.get(event.data, "factor"), Number),
        }))
        .whenUpdate(function() {
          var source = this.state.get("source")
          var target = this.state.get("target")
          var container = this.state.get("container")
          var dir = source < target ? 1 : -1
          var value = Struct.get(container, this.name) 
            + DeltaTime.apply(this.state.get("factor") * dir)
          value = dir > 0
            ? clamp(value, source, target)
            : clamp(value, target, source)
          Struct.set(container, this.name, value)
          if (value == target) {
            task.fullfill()
          }
        })
      
      var executor = Assert.isType(Struct.get(event.data, "executor"), TaskExecutor)
      executor.tasks.forEach(fullfillExistingTask, event.name)
      executor.add(task)
    }
  },
  "fade-sprite": function() {
    return function(event) {
      static setFadeOut = function(task) {
        if (task.name == "fade-sprite") {
          task.state.set("stage", "fade-out")
        }
      }
    
      var fadeInSpeed = Assert.isType(Struct.getDefault(event.data, "fadeInSpeed", 0.01), Number)
      var fadeOutSpeed = Assert.isType(Struct.getDefault(event.data, "fadeOutSpeed", 0.01), Number)
      var sprite = Assert.isType(Struct.get(event.data, "sprite"), Sprite)
      sprite.alpha = 0.0
      var task = new Task(event.name)
        .setState(new Map(String, any, {
          stage: "fade-in",
          sprite: sprite,
          fadeInSpeed: fadeInSpeed,
          fadeOutSpeed: fadeOutSpeed,
        }))
        .whenUpdate(function() {
          var stage = this.state.get("stage")
          switch (stage) {
            case "idle":
              break
            case "fade-in":
              sprite = this.state.get("sprite")
              var fadeInSpeed = this.state.get("fadeInSpeed")
              sprite.alpha = clamp(sprite.alpha + DeltaTime.apply(fadeInSpeed), 0.0, 1.0)
              if (sprite.alpha >= 1.0) {
                this.state.set("stage", "idle")
              }
              break
            case "fade-out":
              sprite = this.state.get("sprite")
              var fadeOutSpeed = this.state.get("fadeOutSpeed")
              sprite.alpha = clamp(sprite.alpha - DeltaTime.apply(fadeOutSpeed), 0.0, 1.0)
              if (sprite.alpha <= 0.0) {
                this.fullfill()
              }
              break
            default:
              throw new InvalidStatusException($"fade-sprite unkown stage: '{stage}', task.name: '{this.name}'")
              break
          }
        })
      
      var executor = Assert.isType(Struct.get(event.data, "executor"), TaskExecutor)
      executor.tasks.forEach(setFadeOut)
      executor.add(task)

      var collection = Struct.get(event.data, "collection")
      if (Core.isType(collection, Collection)) {
        collection.add(task)
      }
    }
  },
}
#macro EVENT_DISPATCHERS global.__EVENT_DISPATCHERS
