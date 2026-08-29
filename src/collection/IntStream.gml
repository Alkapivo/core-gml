///@package io.alkapivo.core.collection
show_debug_message("init IntStream.gml")


///@static
function _IntStream() constructor {
  
  ///@param {Number} from
  ///@param {Number} to
  ///@param {Callable} callback
  ///@param {Number} [acc]
  ///@return {NumberUtil}
  static forEach = function(from, to, callback, acc = null) {
    if (from - to > 0) {
      for (var index = from; index >= to; index--) {
        callback(index, from - index, acc)
      }
    } else {
      for (var index = from; index < to; index++) {
        callback(index, index - from, acc)
      }
    }
    return this
  }

  ///@param {Number} from
  ///@param {Number} to
  ///@param {Callable} callback
  ///@param {Number} [acc]
  ///@return {Array}
  static map = function(from, to, callback, acc = null) {
    var size = abs(from - to)
    var mapped = new Array(any, GMArray.createGMArray(size))
    if (from - to > 0) {
      for (var index = from; index >= to; index--) {
        var result = callback(index, from - index, acc)
        mapped.set(from - index, result)
      }
    } else {
      for (var index = from; index < to; index++) {
        var result = callback(index, index - from, acc)
        mapped.set(index - from, result)
      }
    }
    return mapped
  }

  ///@param {Number} from
  ///@param {Number} to
  ///@param {Callable} callback
  ///@param {Number} [acc]
  ///@return {Array}
  static filter = function(from, to, callback, acc = null) {
    var filtered = new Array()
    if (from - to > 0) {
      for (var index = from; index >= to; index--) {
        if (callback(index, from - index, acc)) {
          filtered.add(index)
        }
      }
    } else {
      for (var index = from; index < to; index++) {
        if (callback(index, index - from, acc)) {
          filtered.add(index)
        }
      }
    }
    return filtered
  }
}

global.__IntStream = new _IntStream()
#macro IntStream global.__IntStream
