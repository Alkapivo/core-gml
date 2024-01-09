///@package io.alkapivo.core.lang.Bean

///@param {String} _message
function BeanAlreadyExistsException(_message): Exception(_message) constructor { }

///@param {Prototype} _prototype
///@param {GMObject<GMInstance>} gmInstance
function Bean(_prototype, gmInstance) constructor {

  ///@type {Prototype}
  prototype = Assert.isType(_prototype, Prototype)

  ///@type {GMObject<GMInstance>}
  object = Assert.isType(gmInstance, GMObject)
  Assert.isType(GMObjectUtil.get(this.object, "__context"), this.prototype)

  ///@return {?Struct}
  get = function() {
    if (Core.isType(this.object, GMObject)) {
      var context = GMObjectUtil.get(this.object, "__context")
      return Core.isType(context, this.prototype) ? context : null
    }
    return null
  }
}


///@static
function _Beans() constructor {

  ///@type {Map<String, Bean>} 
  beans = new Map(String, Bean)

  ///@type {Stack<String>}
  gc = new Stack(String)

  ///@return {Beans}
  static healthcheck = function() {
    static checkBeanHealth = function(bean, name, gc) {
      if (!Core.isType(bean, Bean) || !Core.isType(bean.asset, bean.prototype)) {
        gc.push(name)
      }
    }

    static gcBean = function(name, index, beans) {
      Logger.info("Beans", $"delete `{name}`")
      beans.remove(name)
    }

    this.beans.forEach(checkBeanHealth, this.gc)
    if (this.gc.size() > 0) {
      Logger.info("Beans", $"Healthcheck detected corrupted beans: {this.gc.size()}")
      this.gc.forEach(gcBean, this.beans)
    }

    return this
  }
  
  ///@type {Timer}
  timer = new Timer(0.3, { 
    loop: Infinity,
    callback: this.healthcheck
  })

  ///@return {Beans}
  static update = function() {
    this.timer.update()
    return this
  }

  ///@param {String} name
  ///@return {Boolean}
  static exists = function(name) {
    if (this.beans.contains(name)) {
      var bean = this.beans.get(name)
      if (!Core.isType(bean, Bean)) {
        Logger.error("Beans", $"Found non-bean entity in beans?: {name}")
        this.beans.remove(name)
        return false
      }

      if (bean.get() == null) {
        Logger.error("Beans", $"Found corrupted bean: {name}")
        this.beans.remove(name)
        return false
      }
      return true
    }

    return false
  }

  ///@param {String} name
  ///@return {?Struct}
  static get = function(name) {
    if (this.exists(name)) {
      return this.beans.get(name).get()
    }
    
    //Logger.debug("Beans", $"Trying to get non-existing bean '{name}'")
    return null
  }

  ///@param {Bean} bean
  ///@return {Beans}
  ///@throws {BeanAlreadyExistsException}
  static add = function(name, bean) {
    if (this.exists(name)) {
      throw new BeanAlreadyExistsException($"Bean already exists: '{name}'")
    }

    if (this.beans.contains(name)) {
      Logger.info("Beans", $"Update existing bean: {name}")
    } else {
      Logger.info("Beans", $"Set new bean: {name}")
    }
    this.beans.set(name, bean)
    return this
  }

  ///@param {String} name
  static remove = function(name) {
    var bean = this.beans.get(name)
    Core.dereference(bean, $"Bean `{name}` dereferenced successfully")
    this.beans.remove(name)
  }
}

global.__Beans = new _Beans()
#macro Beans global.__Beans


