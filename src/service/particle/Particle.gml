///@io.alkapivo.core.service.particle

#macro GMParticle "GMParticle"

///@enum
function _ParticleShape(): Enum() constructor {
  PIXEL = pt_shape_pixel
  DISK = pt_shape_disk	
  SQUARE = pt_shape_square	
  LINE = pt_shape_line	
  STAR = pt_shape_star	
  CIRCLE = pt_shape_circle	
  RING = pt_shape_ring	
  SPHERE = pt_shape_sphere	
  FLARE = pt_shape_flare	
  SPARK = pt_shape_spark	
  EXPLOSION = pt_shape_explosion	
  CLOUD = pt_shape_cloud	
  SMOKE = pt_shape_smoke	
  SNOW = pt_shape_snow
}
global.__ParticleShape = new _ParticleShape()
#macro ParticleShape global.__ParticleShape


///@param {Struct} json
function ParticlePropertyNumeric(json) constructor {

  ///@type {Number}
  minValue = Assert.isType(Struct.get(json, "minValue"), Number)

  ///@type {Number}
  maxValue = Assert.isType(Struct.get(json, "maxValue"), Number)
}


///@param {Struct} json
function ParticlePropertyNumericTransform(json): ParticlePropertyNumeric(json) constructor {

  ///@type {Number}
  increase = Assert.isType(Struct.get(json, "increase"), Number)

  ///@type {Number}
  wiggle = Assert.isType(Struct.get(json, "wiggle"), Number)
}


///@param {Struct} json
function ParticlePropertyOrientation(json): ParticlePropertyNumericTransform(json) constructor {

  ///@type {Boolean}
  relative = Assert.isType(Struct.get(json, "relative"), Boolean)
}


///@param {Struct} json
function ParticlePropertyColor(json) constructor {

  ///@type {GMColor}
  start = ColorUtil.fromHex(Struct.get(json, "start")).toGMColor()
  Assert.isType(this.start, GMColor, "start")

  ///@type {GMColor}
  halfway = ColorUtil.fromHex(Struct.get(json, "halfway")).toGMColor()
  Assert.isType(this.halfway, GMColor, "halfway")

  ///@type {GMColor}
  finish = ColorUtil.fromHex(Struct.get(json, "finish")).toGMColor()
  Assert.isType(this.finish, GMColor, "finish")
}


///@param {Struct} json
function ParticlePropertyAlpha(json) constructor {

  ///@type {Number}
  start = Assert.isType(Struct.get(json, "start"), Number)

  ///@type {Number}
  halfway = Assert.isType(Struct.get(json, "halfway"), Number)

  ///@type {Number}
  finish = Assert.isType(Struct.get(json, "finish"), Number)
}


///@param {Struct} json
function ParticlePropertyGravity(json) constructor {

  ///@type {Number}
  amount = Assert.isType(Struct.get(json, "amount"), Number)

  ///@type {Number}
  angle = Assert.isType(Struct.get(json, "angle"), Number)
}


///@param {Struct} json
function ParticlePropertySprite(json) constructor {
  
  ///@type {Texture}
  texture = Assert.isType(TextureUtil.fetch(Struct.get(json, "name")), Texture)
  
  ///@type {Boolean}
  animate = Assert.isType(Struct.getDefault(json, "animate", false), Boolean)

  ///@type {Boolean}
  stretch = Assert.isType(Struct.getDefault(json, "stretch", false), Boolean)

  ///@type {Boolean}
  randomValue = Assert.isType(Struct.getDefault(json, "randomValue", false), Boolean)
}


///@param {String} _name
///@param {Struct} json
function ParticleTemplate(_name, json) constructor {

  ///@type {String}
  name = Assert.isType(_name, String)

  ///@type {String}
  shape = Struct.getDefault(json, "shape", "CIRCLE")

  ///@type {Struct}
  size = Struct.get(json, "size")

  ///@type {Struct}
  scale = Struct.get(json, "scale")

  ///@type {Struct}
  orientation = Struct.get(json, "orientation")

  ///@type {Struct}
  color = Struct.get(json, "color")

  ///@type {Struct}
  alpha = Struct.get(json, "alpha")

  ///@type {Boolean}
  blend = Struct.get(json, "blend")

  ///@type {Struct}
  life = Struct.get(json, "life")

  ///@type {Struct}
  speed = Struct.get(json, "speed")

  ///@type {Struct}
  angle = Struct.get(json, "angle")

  ///@type {Struct}
  gravity = Struct.get(json, "gravity")

  ///@type {?Struct}
  sprite = Struct.contains(json, "sprite") ? Struct.get(json, "sprite") : null
}


///@param {Struct|ParticleTemplate} json
function Particle(json) constructor {

  ///@type {String}
  name = Assert.isType(Struct.get(json, "name"), String)

  ///@type {ParticleShape}
  shape = Assert.isEnum(ParticleShape.get(Struct.getDefault(json, "shape", "CIRCLE")), ParticleShape)

  ///@type {ParticlePropertyNumeric}
  size = new ParticlePropertyNumericTransform(Struct.get(json, "size"))

  ///@type {Vector2}
  scale = Vector.parse(Struct.get(json, "scale"), Vector2)

  ///@type {ParticlePropertyOrientation}
  orientation = new ParticlePropertyOrientation(Struct.get(json, "orientation"))

  ///@type {ParticlePropertyColor}
  color = new ParticlePropertyColor(Struct.get(json, "color"))

  ///@type {ParticlePropertyAlpha}
  alpha = new ParticlePropertyAlpha(Struct.get(json, "alpha")) 

  ///@type {Boolean}
  blend = Assert.isType(Struct.get(json, "blend"), "Boolean")

  ///@type {ParticlePropertyNumeric}
  life = new ParticlePropertyNumeric(Struct.get(json, "life"))

  ///@type {ParticlePropertyNumericTransform}
  speed = new ParticlePropertyNumericTransform(Struct.get(json, "speed"))

  ///@type {ParticlePropertyNumericTransform}
  angle = new ParticlePropertyNumericTransform(Struct.get(json, "angle"))

  ///@type {Struct}
  gravity = new ParticlePropertyGravity(Struct.get(json, "gravity"))

  ///@type {?ParticlePropertySprite}
  sprite = Struct.contains(json, "sprite") 
    ? new ParticlePropertySprite(Struct.get(json, "sprite"))
    : null

  ///@type {?GMParticle}
  asset = part_type_create()
  
  part_type_shape(this.asset, this.shape);
	part_type_size(this.asset, this.size.minValue, this.size.maxValue, this.size.increase, this.size.wiggle)
	part_type_scale(this.asset, this.scale.x, this.scale.y)
	part_type_orientation(this.asset, this.orientation.minValue, this.orientation.maxValue, this.orientation.increase, this.orientation.wiggle, this.orientation.relative)
	part_type_color3(this.asset, this.color.start, this.color.halfway, this.color.finish)
	part_type_alpha3(this.asset, this.alpha.start, this.alpha.halfway, this.alpha.finish)
	part_type_blend(this.asset, this.blend)
	part_type_life(this.asset, this.life.minValue, this.life.maxValue)
	part_type_speed(this.asset, this.speed.minValue, this.speed.maxValue, this.speed.increase, this.speed.wiggle)
	part_type_direction(this.asset, this.angle.minValue, this.angle.maxValue, this.angle.increase, this.angle.wiggle)
	part_type_gravity(this.asset, this.gravity.amount, this.gravity.angle)
  if (Core.isType(this.sprite, ParticlePropertySprite)) {
	  part_type_sprite(this.asset, this.sprite.texture.asset, this.sprite.animate, this.sprite.stretch, this.sprite.randomValue)
  }
}
