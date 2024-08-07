///@io.alkapivo.core.service.particle

///@enum
function _ParticleEmitterShape(): Enum() constructor {
  RECTANGLE = ps_shape_rectangle
  ELLIPSE = ps_shape_ellipse
  DIAMOND = ps_shape_diamond
  LINE = ps_shape_line
}
global.__ParticleEmitterShape = new _ParticleEmitterShape()
#macro ParticleEmitterShape global.__ParticleEmitterShape

///@enum
function _ParticleEmitterDistribution(): Enum() constructor {
  LINEAR = ps_distr_linear
  GAUSSIAN = ps_distr_gaussian
  INVERTEDGAUSSIAN = ps_distr_invgaussian
}
global.__ParticleEmitterDistribution = new _ParticleEmitterDistribution()
#macro ParticleEmitterDistribution global.__ParticleEmitterDistribution


///@param {String} _layerName
function ParticleSystem(_layerName) constructor {

  ///@type {String}
  layerName = Assert.isType(_layerName, String)

  ///@type {GMParticleSystem}
  asset = part_system_create_layer(this.layerName, false)
  part_system_automatic_draw(this.asset, false)

  ///@type {GMEmitter}
  emitter = part_emitter_create(this.asset)

  ///@private
  ///@type {TaskExecutor}
  executor = new TaskExecutor(this)

  ///@return {ParticleSystem}
  update = function() {
    if (!part_system_exists(this.asset)) {
      this.asset = part_system_create_layer(this.layerName, false)
      part_system_automatic_draw(this.asset, false)
    }

    if (!part_emitter_exists(this.asset, this.emitter)) {
      this.emitter = part_emitter_create(this.asset)
    }

    this.executor.update()
    return this
  }

  render = function() {
    part_system_drawit(this.asset);
  }
    
  free = function() {
    if (part_system_exists(this.asset)) {
      part_system_destroy(this.asset)
    }
  }
}


///@param {Controller} _controller
///@param {Struct} [config]
function ParticleService(_controller, config = {}): Service() constructor {

  ///@type {Controller}
  controller = Assert.isType(_controller, Struct)

  ///@type {Map<String, ParticleTemplate>}
  templates = new Map(String, ParticleTemplate)

  ///@type {Map<String, ParticleSystem}
  systems = Struct.getDefault(config, "systems", new Map(String, ParticleSystem, {
    main: new ParticleSystem(Struct.get(config, "layerName")),
  }))

  ///@type {EventPump}
  dispatcher = new EventPump(this, new Map(String, Callable, {
    "spawn-particle-emitter": function(event) {
      var task = new Task("emmit-particle")
        .setTimeout(Struct.getDefault(event.data, "duration", FRAME_MS))
        .setTick(Struct.getDefault(event.data, "interval", FRAME_MS))
        .setState(new Map(String, any, {
          particle: event.data.particle,
          system: event.data.system,
          shape: event.data.shape,
          amount: event.data.amount,
          coords: event.data.coords,
          distribution: event.data.distribution,
        }))
        .whenTimeout(function() {
          this.fullfill()
        })
        .whenUpdate(function(executor) {
          var system = this.state.get("system")
          var coords = this.state.get("coords")
          var shape = this.state.get("shape")
          var distribution = this.state.get("distribution")
          part_emitter_region(
            system.asset, system.emitter,
            coords.x, coords.z, coords.y, coords.a,
            shape, distribution
          )

          var particle = this.state.get("particle")
          var amount = this.state.get("amount")
          part_emitter_burst(system.asset, system.emitter, particle.asset, amount)
        })
      event.data.system.executor.add(task)
    },
    "clear-particles": function(event) {
      this.templates.clear()
    },
    "reset-templates": function(event) {
      this.templates.clear().set("particle-default", new ParticleTemplate("particle-default", {
        "color":{
          "start":"#ffffff",
          "halfway":"#ffffff",
          "finish":"#ffffff"
        },
        "alpha":{
          "start":1.0,
          "halfway":0.0,
          "finish":0.0
        },
        "speed":{
          "wiggle":0.0,
          "increase":0.001,
          "minValue":0.01,
          "maxValue":5.0
        },
        "shape":"CIRCLE",
        "gravity":{
          "angle":0.0,
          "amount":0.0
        },
        "orientation":{
          "wiggle":0.0,
          "relative":0.0,
          "increase":0.001,
          "minValue":0.0,
          "maxValue":360.0
        },
        "angle":{
          "wiggle":0.0,
          "increase":0.01,
          "minValue":0.0,
          "maxValue":360.0
        },
        "life":{
          "minValue":80.0,
          "maxValue":120.0
        },
        "sprite":{
          "name":"texture_particle",
          "stretch":0.0,
          "randomValue":0.0,
          "animate":0.0
        },
        "scale":{
          "x":1.0,
          "y":1.0
        },
        "blend":0.0,
        "size":{
          "wiggle":0.0,
          "increase":0.0,
          "minValue":1.0,
          "maxValue":32.0
        }
      }))
    },
  }))

  ///@param {String} name
  ///@return {?Particle}
  factoryParticle = function(name) {
    var template = this.templates.get(name)
    return template != null ? new Particle(template) : null
  }

  ///@param {Struct} [config]
  ///@return {Event}
  factoryEventSpawnParticleEmitter = function(config = {}) {
    return new Event("spawn-particle-emitter", {
      particle: this.factoryParticle(Struct.getDefault(config, "particleName", "particle_default")),
      system: this.systems.get(Struct.getDefault(config, "systemName", "main")),
      coords: new Vector4(
        Struct.get(config, "beginX"),
        Struct.get(config, "beginY"),
        Struct.get(config, "endX"),
        Struct.get(config, "endY")
      ),
      shape: Struct.getDefault(config, "shape", ParticleEmitterShape.ELLIPSE),
      duration: Struct.getDefault(config, "duration", 0.0),
      interval: Struct.getDefault(config, "interval", FRAME_MS),
      amount: Struct.getDefault(config, "amount", 100),
      distribution: Struct.getDefault(config, "distribution", ParticleEmitterDistribution.LINEAR),
    })
  }

  ///@param {Event} event
  ///@return {?Promise}
  send = function(event) {
    return this.dispatcher.send(event)
  }

  ///@override
  ///@return {ParticleService}
  update = function() {
    this.dispatcher.update()
    this.systems.forEach(function(system) {
      system.update()
    })
    return this
  }

  this.send(new Event("reset-templates"))
}
