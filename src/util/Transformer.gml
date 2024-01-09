///@packager com.alkapivo.core.util.Transformer

///@interface
///@param {Struct} [json]
function Transformer(json = {}) constructor {

  ///@type {any}
  value = Struct.get(json, "value")

  ///@type {any}
  startValue = Struct.get(json, "value")

  ///@type {Boolean}
  finished = false

  ///@return {any}
  static get = function() {
    return this.value
  }

  ///@param {any} value
  ///@return {Transformer}
  static set = function(value) {
    this.value = value 
    return this
  }

  ///@return {Transformer}
  static update = function() { return this }

  ///@return {Transformer}
  static reset = function() {
    this.finished = false 
    this.value = this.startValue
    return this
  }
}


///@param {Struct} [json]
function ColorTransformer(json = { value: "#ffffff" }): Transformer(json) constructor {

  ///@override
  ///@type {Color}
  this.value = ColorUtil.fromHex(Struct.get(json, "value"))
  Assert.isType(this.value, Color, "value")

  ///@override
  ///@type {Color}
  this.startValue = ColorUtil.fromHex(Struct.get(json, "value"))
  Assert.isType(this.startValue, Color, "startValue")

  ///@type {Color}
  target = ColorUtil.fromHex(Struct.get(json, "target"))
  Assert.isType(this.target, Color, "target")

  ///@type {Number}
  factor = Struct.getDefault(json, "factor", 1)
  Assert.isType(this.factor, Number, "factor")

  ///@override
  ///@return {ColorTransformer}
  static update = function() {
    if (this.finished) {
      return this
    }

    this.value.red = Math.transformNumber(this.value.red, this.target.red, this.factor)
    this.value.green = Math.transformNumber(this.value.green, this.target.green, this.factor)
    this.value.blue = Math.transformNumber(this.value.blue, this.target.blue, this.factor)
    this.value.alpha = Math.transformNumber(this.value.alpha, this.target.alpha, this.factor)
    if (ColorUtil.areEqual(this.value, this.target)) {
      this.finished = true
    }
    return this
  }
}


///@param {Struct} [json]
function NumberTransformer(json = { value: 0 }): Transformer(json) constructor {

  Assert.isType(this.value, Number)

  ///@type {Number}
  target = Assert.isType(Struct.getDefault(json, "target", this.value), Number)

  ///@type {Number}
  factor = Assert.isType(Struct.getDefault(json, "factor", 1), Number)

  ///@type {Number}
  increase = Assert.isType(Struct.getDefault(json, "increase", 0), Number)

  ///@override
  ///@return {NumberTransformer}
  static update = function() {
    if (this.finished) {
      return this
    }

    this.factor = (this.value < this.target ? 1 : -1) 
      * this.factor + DeltaTime.apply(this.increase)
    this.value = Math.transformNumber(this.value, this.target, this.factor)
    if (this.value == this.target) {
      this.finished = true
    }
    return this
  }
}


///@param {Struct} [json]
function Vector2Transformer(json = {}): Transformer(json) constructor {

  ///@type {NumberTransformer}
  x = new NumberTransformer(Struct.get(json, "x"))
  Assert.isType(this.x, NumberTransformer, "x")

  ///@type {NumberTransformer}
  y = new NumberTransformer(Struct.get(json, "y"))
  Assert.isType(this.y, NumberTransformer, "y")

  ///@override
  ///@type {Vector2}
  value = new Vector2(x.value, y.value)
  Assert.isType(this.value, Vector2, "value")

  ///@override
  ///@return {Vector2Transformer}
  static update = function() {
    if (this.finished) {
      return this
    }

    this.x.factor = (this.value.x < this.x.target ? 1 : -1) 
      * this.x.factor + DeltaTime.apply(this.x.increase)
    this.value.x = this.x.update().get()

    this.y.factor = (this.value.y < this.y.target ? 1 : -1) 
      * this.y.factor + DeltaTime.apply(this.y.increase)
    this.value.y = this.y.update().get()

    if (this.value.x == this.x.target && this.value.y == this.y.target) {
      this.finished = true
    }
    return this
  }

  ///@override
  ///@return {Vector2Transformer}
  static reset = function() {
    this.finished = false 
    this.x.reset()
    this.y.reset()
    return this
  }
}


///@param {Struct} [json]
function Vector3Transformer(json = {}): Transformer(json) constructor {

  ///@type {NumberTransformer}
  x = new NumberTransformer(Struct.get(json, "x"))
  Assert.isType(this.x, NumberTransformer, "x")

  ///@type {NumberTransformer}
  y = new NumberTransformer(Struct.get(json, "y"))
  Assert.isType(this.y, NumberTransformer, "y")

  ///@type {NumberTransformer}
  z = new NumberTransformer(Struct.get(json, "z"))
  Assert.isType(this.z, NumberTransformer, "z")

  ///@override
  ///@type {Vector3}
  value = new Vector3(x.value, y.value, z.value)
  Assert.isType(this.value, Vector3, "value")

  ///@override
  ///@return {Vector3Transformer}
  static update = function() {
    if (this.finished) {
      return this
    }

    this.x.factor = (this.value.x < this.x.target ? 1 : -1) 
      * this.x.factor + DeltaTime.apply(this.x.increase)
    this.value.x = this.x.update().get()

    this.y.factor = (this.value.y < this.y.target ? 1 : -1) 
      * this.y.factor + DeltaTime.apply(this.y.increase)
    this.value.y = this.y.update().get()

    this.z.factor = (this.value.z < this.z.target ? 1 : -1) 
      * this.z.factor + DeltaTime.apply(this.z.increase)
    this.value.z = this.z.update().get()

    if (this.value.x == this.x.target 
      && this.value.y == this.y.target
      && this.value.z == this.z.target) {

      this.finished = true
    }
    return this
  }

  ///@override
  ///@return {Vector3Transformer}
  static reset = function() {
    this.finished = false 
    this.x.reset()
    this.y.reset()
    this.z.reset()
    return this
  }
}


///@param {Struct} [json]
function Vector4Transformer(json = {}): Transformer(json) constructor {

  ///@type {NumberTransformer}
  x = new NumberTransformer(Struct.get(json, "x"))
  Assert.isType(this.x, NumberTransformer, "x")

  ///@type {NumberTransformer}
  y = new NumberTransformer(Struct.get(json, "y"))
  Assert.isType(this.y, NumberTransformer, "y")

  ///@type {NumberTransformer}
  z = new NumberTransformer(Struct.get(json, "z"))
  Assert.isType(this.z, NumberTransformer, "z")

  ///@type {NumberTransformer}
  a = new NumberTransformer(Struct.get(json, "a"))
  Assert.isType(this.z, NumberTransformer, "a")

  ///@override
  ///@type {Vector4}
  value = new Vector4(x.value, y.value, z.value, a.value)
  Assert.isType(this.value, Vector4, "value")

  ///@override
  ///@return {Vector4Transformer}
  static update = function() {
    if (this.finished) {
      return this
    }

    this.x.factor = (this.value.x < this.x.target ? 1 : -1) 
      * this.x.factor + DeltaTime.apply(this.x.increase)
    this.value.x = this.x.update().get()

    this.y.factor = (this.value.y < this.y.target ? 1 : -1) 
      * this.y.factor + DeltaTime.apply(this.y.increase)
    this.value.y = this.y.update().get()

    this.z.factor = (this.value.z < this.z.target ? 1 : -1) 
      * this.z.factor + DeltaTime.apply(this.z.increase)
    this.value.z = this.z.update().get()

    this.a.factor = (this.value.a < this.a.target ? 1 : -1) 
      * this.a.factor + DeltaTime.apply(this.a.increase)
    this.value.a = this.a.update().get()

    if (this.value.x == this.x.target 
      && this.value.y == this.y.target
      && this.value.z == this.z.target
      && this.value.a == this.a.target) {

      this.finished = true
    }
    return this
  }

  ///@override
  ///@return {Vector4Transformer}
  static reset = function() {
    this.finished = false 
    this.x.reset()
    this.y.reset()
    this.z.reset()
    this.a.reset()
    return this
  }
}


///@param {Struct} [json]
function ResolutionTransformer(json = {}): Transformer(json) constructor {

  ///@type {NumberTransformer}
  scale = new NumberTransformer(Struct.getDefault(json, "scale", { value: 1 }))
  Assert.isType(this.scale, NumberTransformer, "scale")

  ///@override
  ///@type {Vector2}
  value = new Vector2(GuiWidth() / this.scale.value, GuiHeight() / this.scale.value)
  Assert.isType(this.value, Vector2, "value")

  ///@override
  ///@return {Vector2}
  static update = function() {
    this.scale.factor = (this.scale.value < this.scale.target ? 1 : -1) 
      * this.scale.factor + DeltaTime.apply(this.scale.increase)
    this.scale.value = this.scale.update().get()

    this.value.x = GuiWidth() / this.scale.value
    this.value.y = GuiHeight() / this.scale.value
    return this
  }
}
