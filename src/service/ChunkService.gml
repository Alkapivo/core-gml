///@package io.alkapivo.service.chunk

///@interface
///@param {ChunkService} _context
///@param {Struct} config
function Chunk(_context, config) constructor {

  ///@type {ChunkService}
  context = Assert.isType(_context, ChunkService)

  ///@type {String}
  key = Assert.isType(Struct.get(config, "key"), String)

  ///@type {any}
  type = Struct.get(config, "type")

  ///@type {any}
  data = Struct.get(config, "data")

  ///@param {any} item
  ///@return {Chunk}
  add = Struct.contains(config, "add")
    ? method(this, Assert.isType(config.add, Callable))
    : function(item) { return this }

  ///@param {String} name
  ///@return {any}
  get = Struct.contains(config, "get")
    ? method(this, Assert.isType(config.get, Callable))
    : function(name) { return null }

  ///@return {Number}
  size = Struct.contains(config, "size")
    ? method(this, Assert.isType(config.size, Callable))
    : function() { return 0 }

  ///@param {String} name
  ///@return {Boolean}
  contains = Struct.contains(config, "contains")
    ? method(this, Assert.isType(config.contains, Callable))
    : function(name) { return false }

  ///@param {String} name
  ///@return {Chunk}
  remove = Struct.contains(config, "remove")
    ? method(this, Assert.isType(config.remove, Callable))
    : function(name) { return this }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {Chunk}
  forEach = Struct.contains(config, "forEach")
    ? method(this, Assert.isType(config.forEach, Callable))
    : function(callback, acc = null) {  return this }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  filter = Struct.contains(config, "filter")
    ? method(this, Assert.isType(config.filter, Callable))
    : function(callback, acc = null) {  return null }

  
  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  find = Struct.contains(config, "find")
    ? method(this, Assert.isType(config.find, Callable))
    : function(callback, acc = null) {  return null }
}

///@param {Struct} _context
///@param {Struct} config
function ChunkService(_context, config): Service(config) constructor {

  ///@type {Struct}
  context = Assert.isType(_context, Struct)

  ///@type {Map<String, Chunk>}
  chunks = new Map(String, Chunk)

  ///@type {Struct}
  activeChunks = Assert.isType(Struct.get(config, "activeChunks"), Struct)
  Struct.set(this.activeChunks, "service", this)
  
  ///@type {any}
  step = Struct.get(config, "step")

  ///@param {any} item
  ///@param {any} key
  ///@return {ChunkService}
  add = Struct.contains(config, "add")
    ? method(this, Assert.isType(config.add, Callable))
    : function(item, key) {
      this.chunks.add(item, key)
      return this
    }

  ///@param {any} key
  ///@return {Boolean}
  contains = Struct.contains(config, "contains")
    ? method(this, Assert.isType(config.contains, Callable))
    : function(key) {
      return this.chunks.contains(key)
    }

  ///@param {any} key
  ///@return {any}
  fetch = Struct.contains(config, "fetch")
    ? method(this, Assert.isType(config.fetch, Callable))
    : function(key) {
      if (!this.contains(key)) {
        this.add(this.factoryChunk(key), key)
      }
      return this.chunks.get(key)
    }

  ///@param {any} key
  ///@return {ChunkService} 
  remove = Struct.contains(config, "remove")
    ? method(this, Assert.isType(config.remove, Callable))
    : function(key) {
      this.chunks.remove(key)
      return this
    }

  ///@param {any} data
  ///@return {any}
  fetchKey = Struct.contains(config, "fetchKey")
    ? method(this, Assert.isType(config.fetchKey, Callable))
    : function(data) { return null }
  
  ///@param {any} key
  ///@return {Chunk}
  factoryChunk = Struct.contains(config, "factoryChunk")
    ? method(this, Assert.isType(config.factoryChunk, Callable))
    : function(data) { return null }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  forEach = Struct.contains(config, "forEach")
    ? method(this, Assert.isType(config.forEach, Callable))
    : function(callback, acc = null) { 
      this.chunks.forEach(function(chunk, key, acc) {
        chunk.forEach(function(item, key, acc) {
          return acc.callback(item, key, acc.acc)
        }, acc)
      }, {
        callback: callback,
        acc: acc,
      })
      return this
    }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  filter = Struct.contains(config, "filter")
    ? method(this, Assert.isType(config.filter, Callable))
    : function(callback, acc = null) { 
      var data = {
        filtered: new Map(),
        callback: callback,
        acc: acc,
      }

      this.chunks.forEach(function(chunk, key, data) {
        chunk.forEach(function(item, _key, acc) {
          if (acc.callback(item, _key, acc.acc)) {
            acc.filtered.add(item, _key)
          }
        }, data) 
      }, data)

      return data.filtered
    }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  map = Struct.contains(config, "map")
    ? method(this, Assert.isType(config.map, Callable))
    : function(callback, acc = null) { 
      var data = {
        mapped: new Map(),
        callback: callback,
        acc: acc,
      }

      this.chunks.forEach(function(chunk, key, data) {
        chunk.forEach(function(item, _key, acc) {
          acc.mapped.add(acc.callback(item, _key, acc.acc), _key)
        }, data) 
      }, data)

      return data.mapped
    }

  ///@param {Callable} callback
  ///@param {any} [acc]
  ///@return {any}
  find = Struct.contains(config, "find")
    ? method(this, Assert.isType(config.find, Callable))
    : function(callback, acc = null) { 
      return this.chunks.find(function(chunk, key, acc) {
        return acc.callback(chunk, key, acc.acc)
      }, {
        callback: callback,
        acc: acc,
      })
    }

  ///@return {ChunkService}
  update = Struct.contains(config, "update")
    ? method(this, Assert.isType(config.update, Callable))
    : function() { return this }
}
