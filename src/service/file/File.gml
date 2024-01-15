///@package io.alkapivo.core.service.file

///@param {Struct} json
function File(json) constructor {

  ///@type {String}
  name = Assert.isType(json.name, String)

  ///@type {String}
  path = Assert.isType(json.path, String)

  ///@type {any}
  data = Struct.getDefault(json, "data", null)

  ///@return {String}
  static getName = function() {
    return this.name
  }

  ///@param {String} name
  ///@return {File}
  static setName = function(name) {
    this.name = Assert.isType(name, String)
    return this
  }

  ///@return {String}
  static getPath = function() {
    return this.path
  }

  ///@param {String} path
  ///@return {File}
  static setPath = function(path) {
    this.path = Assert.isType(path, String)
    return this
  }

  ///@return {any}
  static getData = function() {
    return this.data
  }

  ///@param {any} data
  ///@return {File}
  static setData = function(data) {
    this.data = data
    return this
  }
}


///@enum
function _PathType(): Enum() constructor {
  FILE = "file"
  DIRECTORY = "directory"
}
global.__PathType = new _PathType()
#macro PathType global.__PathType


///@todo improve API
///@static
function _FileUtil() constructor {

  ///@param {?String} path
  ///@return {?String}
  static get = function(path) {
    var posixPath = Core.isType(path, String) 
      ? String.replaceAll(String.replaceAll(path, "\\", "/"), "//", "/") 
      : null
    var type = FileUtil.getPathType(posixPath)
    switch (type) {
      case PathType.FILE: return posixPath
      case PathType.DIRECTORY: 
        return String.getLastChar(posixPath) != "/" 
          ? $"{posixPath}/" 
          : posixPath
      default: return null
    }
  }

  ///@param {?String} path
  ///@return {?String}
  static getDirectoryFromPath = function(path) {
    var posixPath = FileUtil.get(path)
    if (!Optional.is(FileUtil.getPathType(posixPath))) {
      return null
    } 

    var array = String.split(FileUtil.get(posixPath), "/")
    return array.remove(array.size() - 1).join("/") + "/"
  }

  ///@param {?String} path
  ///@return {?String}
  static getFilenameFromPath = function(path) {
    var posixPath = FileUtil.get(path)
    if (!Optional.is(FileUtil.getPathType(posixPath))) {
      return null
    }   

    var array = String.split(FileUtil.get(posixPath), "/")
    return array.get(array.size() - 1)
  }

  ///@param {?Struct} [config]
  ///@return {?String}
  static getPathToOpenWithDialog = function(config = null) {
    var extension = Assert.isType(Struct.getDefault(config, "extension", ""), String)
    var filename = Assert.isType(Struct.getDefault(config, "filename", ""), String)
    var path = get_open_filename($"|*.{extension}", $"{filename}")
    return FileUtil.get(path)
  }

  ///@param {?Struct} [config]
  ///@return {?String}
  static getPathToSaveWithDialog = function(config = null) {
    var extension = Assert.isType(Struct.getDefault(config, "extension", ""), String)
    var filename = Assert.isType(Struct.getDefault(config, "filename", ""), String)
    var path = get_save_filename($"|*.{extension}", $"{filename}")
    return FileUtil.get(path)
  }

  ///@param {?String} path
  ///@return {?PathType}
  static getPathType = function(path) {
    if (!Core.isType(path, String)) {
      return null
    }

    if (FileUtil.directoryExists(path)) {
      return PathType.DIRECTORY
    }

    return PathType.FILE
  }

  ///@param {?String} path
  ///@return {Boolean}
  static fileExists = function(path) {
    return Core.isType(path, String) && file_exists(path)
  }

  ///@param {?String} path
  ///@return {Boolean}
  static directoryExists = function(path) {
    return Core.isType(path, String) && directory_exists(path)
  }

  ///@param {?String} path
  ///@return {FileUtil}
  static createDirectory = function(path) {
    var posixPath = FileUtil.get(path)
    if (Core.isType(posixPath, String) && !this.directoryExists(posixPath)) {
      Logger.info("FileUtil", $"Create directory '{posixPath }'")
      directory_create(posixPath)
    }
    return this
  }

  ///@param {?String} file - path to file
  ///@param {?String} path - path to new file or target directory
  ///@return {FileUtil}
  static copyFile = function(file, path) {
    var type = FileUtil.getPathType(path)
    if (!Optional.is(type)) {
      return this
    }

    var target = FileUtil.get(path)
    switch (type) {
      case PathType.FILE: break
      case PathType.DIRECTORY:
        target = String.getLastChar(target) == "/" ? target : $"{target}/"
        target = $"{target}{FileUtil.getFilenameFromPath(file)}"
        break
      default:
        Logger.error("FileUtil", $"Found unsupported PathType: '{type}'")
        return this
    }

    Logger.info("FileUtil", $"Copy file '{file}' to '{target}'")
    file_copy(file, target)
    return this
  }
}
global.__FileUtil = new _FileUtil()
#macro FileUtil global.__FileUtil