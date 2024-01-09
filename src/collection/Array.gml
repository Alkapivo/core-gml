///@package io.alkapivo.core.collection

///@param {Type} [_type]
///@param {any[]} [_container]
///@param {?Struct} [config]
function Array(_type = any, _container = null, config = { validate: false }) constructor {

  ///@private
  ///@param {Struct.Array} array
  ///@throws {AssertException}
  static validateContainer = function(array) {
    static validateEntry = function(value, index, array) {
      Assert.isType(value, array.type, $"Value '{value}' at index '{index}' must be type of '{array.type}'")
    }

    if (array.type != any) {
      Struct.forEach(array.container, validateEntry, array)
    }
  }

  ///@type {Type}
  type = _type
  
  ///@private
  ///@type {any[]}
  container = _container != null ? _container : []
  ///@description Cannot use Assert.isType due to initialization order
  if (typeof(this.container) != "array") {
    throw new InvalidAssertException($"Invalid 'Array.container' type: '{typeof(this.container)}'")
  }
  if (Struct.get(config, "validate") == true) {
    this.validateContainer(this)
  }

  ///@private
  ///@type {?Stack<Number>}
  gc = null

  ///@override
  ///@return {Number}
  static size = function() {
    return array_length(this.container)
  }

  ///@param {Number} index
  ///@return {Array}
  static remove = function(index) {
    array_delete(this.container, index, 1)
    return this
  }

  ///@param {Number} index
  ///@return {any}
  static get = function(index) {
    return this.container[index]
  }

  ///@param {Number} index
  ///@return {Array}
  static set = function(index, value) {
    Assert.isType(value, this.type)
    this.container[index] = value
    return this
  }
  
  ///@param {any} item
  ///@param {Number} [index]
  ///@return {Array}
  static add = function(item, index = null) {
    if (this.type != null && !Core.isType(item, this.type)) {
      throw new InvalidClassException()
    }
    
    var size = this.size()
    if (size < 32000) { ///@description GML array limitation
      index = index == null ? size : clamp(index, -31999, 31999)
      array_insert(this.container, index, item)
    }
    return this
  }

  ///@override
  ///@return {Array}
  static clear = function() {
    if (Core.isType(this.gc, Stack)) {
      this.gc.clear()
    }
    
    array_delete(this.container, 0, this.size())
    return this
  }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  static find = function(callback, acc = null) {
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      if (callback(item, index, acc)) {
        return item
      }
    }
    return null
  }

  ///@param {any} value
  ///@param {any} [acc]
  ///@return {?Number}
  static findIndex = function(callback, acc = null) {
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      if (callback(item, index, acc)) {
        return index
      }
    }
    return null
  }

  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {Array}
  static forEach = function(callback, acc = null) {
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      var result = callback(item, index, acc)
      if (result == BREAK_LOOP) {
        break
      }
    }
    return this
  }

  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {Array}
  static filter = function(callback, acc = null) {
    var filtered = new Array(this.type)
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      if (callback(item, index, acc)) {
        filtered.add(item)
      }
    }
    return filtered
  }
  
  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@param {?Type} [type]
  ///@return {Array}
  static map = function(callback, acc = null, type = any) {
    var mapped = new Array(type)
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      var result = callback(item, index, acc)
      if (result == BREAK_LOOP) {
        break
      }
      mapped.add(result)
    }
    return mapped
  }

  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  static flat = function(callback, acc = null) {
    var size = this.size()
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      if (callback(item, index, acc) == BREAK_LOOP) {
        break
      }
    }
    return acc
  }

  ///@override
  ///@param {any} searchItem
  ///@param {Callable} [comparator]
  ///@return {Boolean}
  static contains = function(searchItem, comparator = function(a, b) { return a == b }) {
    var size = this.size()
    var found = false
    for (var index = 0; index < size; index++) {
      var item = this.container[index]
      if (comparator(item, searchItem)) {
        found = true
        break
      }
    }
    return found
  }

  ///@param {String} delimiter
  ///@return {String}
  static join = function(delimiter) {
    var size = this.size()
    var buffer = ""
    if (size > 1) {
      for (var index = 0; index < size; index++) {
        var item = this.container[index]
        buffer = index == size - 1
          ? buffer + item
          : buffer + item + delimiter
      }
    } else {
      buffer = size > 0 ? this.container[0] : ""
    }
    return buffer
  }

  ///@return {any[]}
  static getContainer = function() {
    return this.container
  }

  ///@param {any[]} container
  ///@return {Array}
  static setContainer = function(container) {
    this.container = container
    return this
  }

  ///@return {Array}
  static clone = function() {
    return new Array(this.type, Arrays.clone(this.container))
  }

  ///@param {Callable} [comparator]
  ///@return {Array}
  static sort = function(comparator) {
    static quickSort = function(arr, low, high, comparator, quickSortRef) {
      static partition = function(arr, low, high, comparator) {
        var pivot = arr[high]
        var acc = 0
        for (var index = 0; index < high; index++) {
          if (comparator(arr[index], pivot)) {
            var temp = arr[acc]
            arr[@ acc++] = arr[index]
            arr[@ index] = temp
          }
        }
        var temp = arr[acc]
        arr[@ acc] = arr[high]
        arr[@ high] = temp
        return acc
      }

      if (low < high) {
        var _partition = partition(arr, low, high, comparator)
        quickSortRef(arr, low, _partition - 1, comparator, quickSortRef)
        quickSortRef(arr, _partition + 1, high, comparator, quickSortRef)
      }
      return arr
    }

    if (this.size() <= 1) {
      return this
    }
    this.container = quickSort(this.container, 0, this.size() - 1, comparator, quickSort)
    return this
  }

  static toMap = function(keyType = any, valueType = any, valueCallback = null, acc = null, keyCallback = null) {
    return GMArray.toMap(this.container, keyType, valueType, valueCallback, acc, keyCallback)
  }

  static toStruct = function(valueCallback = null, acc = null, keyCallback = null) {
    return GMArray.toStruct(this.container, keyCallback, acc, valueCallback)
  }

  ///@return {Array}
  static enableGC = function() {
    this.gc = !Core.isType(this.gc, Stack) ? new Stack(Number) : this.gc
    return this
  }

  ///@return {Array}
  static disableGC = function() {
    this.gc = null
    return this
  }

  ///@type {Number} key
  ///@return {Array}
  static addToGC = function(key) {
    if (!Core.isType(this.gc, Stack)) {
      this.enableGC()
    }
    this.gc.push(key)
    return this
  }

  ///@return {Array}
  static runGC = function() {
    if (!Core.isType(this.gc, Stack) || this.gc.size() == 0) {
      return this
    }

    this.removeMany(this.gc)
    return this
  }

  ///@return {any}
  static getFirst = function() {
    return this.size() > 0 ? this.get(0) : null
  }

  ///@return {any}
  static getLast = function() {
    var size = this.size()
    return size > 0 ? this.get(size - 1) : null
  }

  ///@param {Collection} keys
  ///@return {Array}
  static removeMany = function(keys) {
    static setToNull = function(index, gcIndex, array) {
      array.set(index, null)
    }

    var size = this.size()
    if (size == 0) {
      return this
    }

    var type = this.type
    this.type = any
    keys.forEach(setToNull, this)
    for (var index = size - 1; index >= 0; index--) {
      if (this.get(index) == null) {
        this.remove(index)
      }
    }
    this.type = type
    return this
  }
}

///@static
function _GMArray() constructor {

  
  ///@param {any[]} arr
  ///@return {Number}
  static size = function(arr) {
    return array_length(arr)
  }

	///@param {Type} [type]
	///@param {Number} [size]
	///@param {any} [value]
	///@return {Array}
	static create = function(type = any, size = 0, value = null) {
		return new Array(type, this.createGMArray(size, value))
	}

  ///@param {Number} size
  ///@param {any} [value]
  ///@return {GMArray}
  static createGMArray = function(size, value = null) {
    return array_create(size, value)
  }

  ///@param {any[]} arr
  ///@param {any} item
  ///@param {Number} [index]
  ///@return {any[]}
  static add = function(arr, item, index = null) {
    var size = this.size(arr)
    if (size < 32000) { ///@description GML array limitation
      index = Core.isType(index, Number)
        ? clamp(index, -31999, 31999)
        : size
      array_insert(arr, index, item)
    }
    return arr
  }

  ///@param {any[]} arr
  ///@param {Number} index
  ///@return {any[]}
  static remove = function(arr, index) {
    array_delete(arr, index, 1)
    return arr
  }

  ///@param {any[]} arr
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any[]}
  static forEach = function(arr, callback, acc = null) {
    var size = this.size(arr)
    for (var index = 0; index < size; index++) {
      var item = arr[index]
      var result = callback(item, index, acc)
      if (result == BREAK_LOOP) {
        break
      }
    }
    return arr
  }

  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any[]}
  static filter = function(arr, callback, acc = null) {
    var filtered = []
    var size = this.size(arr)
    for (var index = 0; index < size; index++) {
      var item = arr[index]
      if (callback(item, index, acc)) {
        this.add(filtered, item)
      }
    }
    return filtered
  }
  
  ///@override
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {Array}
  static map = function(arr, callback, acc = null) {
    var mapped = []
    var size = this.size(arr)
    for (var index = 0; index < size; index++) {
      var item = arr[index]
      var result = callback(item, index, acc)
      if (result == BREAK_LOOP) {
        break
      }
      this.add(mapped, result)
    }
    return mapped
  }

  ///@param {any[]} arr
  ///@param {Type} [type]
  ///@param {Calllable} [callback]
  ///@param {any} [acc]
  ///@return {Array}
  static toArray = function(arr, type = any, callback = null, acc = null) {
    static passthroughCallback = function(item, index, acc) {
      return item 
    }

    return new Array(type, this.map(arr, Core.isType(callback, Callable) 
      ? callback 
      : passthroughCallback, acc))
  }

  ///@param {any[]} arr
  ///@param {Type} [keyType]
  ///@param {Type} [valueType]
  ///@param {?Calllable} [valueCallback]
  ///@param {any} [acc]
  ///@param {?Calllable} [keyCallback]
  ///@return {Map}
  static toMap = function(arr, keyType = any, valueType = any, valueCallback = null, acc = null, keyCallback = null) {
    var map = new Map(keyType, valueType)
    var size = this.size(arr)
    var isValueCallback = Core.isType(valueCallback, Callable)
    if (Core.isType(keyCallback, Callable)) {
      if (isValueCallback) {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          map.set(keyCallback(key, acc), valueCallback(key, acc))
        }
      } else {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          map.set(key, valueCallback(key, acc))
        }
      }
    } else {
      if (isValueCallback) {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          map.set(key, valueCallback(key, acc))
        }
      } else {
        for (var index = 0; index < size; index++) {
          map.set(arr[index], null)
        }
      }
    }
    return map
  }

  ///@param {any[]} arr
  ///@param {Calllable} [keyCallback]
  ///@param {any} [acc]
  ///@param {Calllable} [valueCallback]
  ///@return {Struct}
  static toStruct = function(arr, keyCallback = null, acc = null, valueCallback = null) {
    var struct = {}
    var size = this.size(arr)
    var isValueCallback = Core.isType(valueCallback, Callable)
    if (Core.isType(keyCallback, Callable)) {
      if (isValueCallback) {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          Struct.set(struct, keyCallback(key, acc), valueCallback(key, acc))
        }
      } else {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          Struct.set(struct, key, valueCallback(key, acc))
        }
      }
    } else {
      if (isValueCallback) {
        for (var index = 0; index < size; index++) {
          var key = arr[index]
          Struct.set(struct, key, valueCallback(key, acc))
        }
      } else {
        for (var index = 0; index < size; index++) {
          Struct.set(struct, arr[index], null)
        }
      }
    }
    return struct
  }

  ///@param {any[]} arr
  ///@param {Callable|Boolean} [callback]
  ///@return {any[]}
  static sort = function(arr, callback = true) {
    array_sort(arr, callback)
    return arr
  }
}
global.__GMArray = new _GMArray()
#macro GMArray global.__GMArray
