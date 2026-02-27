///@package io.alkapivo.core.util

///@enum
function _LanguageType(): Enum() constructor {
  en_EN = "en_EN"
  pl_PL = "pl_PL"
}
global.__LanguageType = new _LanguageType()
#macro LanguageType global.__LanguageType


///@param {Struct} json
function LanguagePack(json) constructor {

  ///@param {Struct}
  ///@return {Map<String, String>}
  static parseLabels = function(json) {
    static parseLabel = function(value, key, labels) {
      /**///@log.level Logger.debug("LanguagePack", $"Load label {key}")
      labels.set(key, value)
    }

    var labels = new Map(String, String)
    if (Struct.getIfType(json, "labels", Struct) != null) {
      Struct.forEach(json.labels, parseLabel, labels)
    }

    return labels
  }

  ///@type {String}
  code = Assert.isType(Struct.get(json, "code"), String, "LanguagePack::code must be type of String")

  ///@type {Map<String, String>}
  labels = parseLabels(json)
  
  ///@param {String} key
  ///@param {String} value
  ///@return {LanguagePack}
  add = function(key, value) {
    if (this.labels.contains(value)) {
      Logger.warn("LanguagePack", $"Key already exists. \{ \"code\": \"{this.code}\" \"key\": \"{key}\", \"value\": \"{this.labels.get(value)}\", \"overrideValue\": \"{value}\" \}")
    }

    this.labels.set(key, value)
    return this
  }
}


///@param {Struct} json
function LanguageManifest(json) constructor {

  ///@type {Array<String>}
  en_EN = new Array(String, Struct.getIfType(json, "en_EN", GMArray))

  ///@type {Array<String>}
  pl_PL = new Array(String, Struct.getIfType(json, "pl_PL", GMArray))

  ///@param {String} code
  ///@return {Array<String>}
  get = function(code) {
    var result = Struct.getIfType(this, code, Array)
    if (result == null) {
      Logger.warn("LanguageManifest", $"Cannot find language \"{code}\". Return default \"en_EN\"")
      result = this.en_EN
    }

    return result
  }
}


///@static
function _Language() constructor {

  ///@type {?LanguagePack}
  pack = null

  ///@type {?LanguageManifest}
  manifest = null

  ///@param {String} code
  ///@return {Language}
  load = function(code) {
    var root = $"{working_directory}lang/"
    var json = FileUtil.readFileSync(FileUtil.get($"{root}manifest.json")).getData()
    var context = this
    this.manifest = null
    this.pack = null
    JSON.parserTask(json, {
      model: "io.alkapivo.core.lang.LanguageManifest",
      callback: function(prototype, json, index, acc) {
        acc.manifest = Assert.isType(new prototype(json), LanguageManifest, "Language::manifest must be type of LanguageManifest")
      },
      acc: context,
    }).update()

    this.pack = new LanguagePack({ code: code })
    this.manifest.get(code).forEach(function(path, iterator, acc) {
      /**///@log.level Logger.debug("Language", $"Load {path}")
      var json = FileUtil.readFileSync(FileUtil.get($"{acc.root}{path}")).getData()
      JSON.parserTask(json, {
        model: "io.alkapivo.core.lang.LanguagePack",
        callback: function(prototype, json, index, acc) {
          var pack = Assert.isType(new prototype(json), LanguagePack, "Language::pack must be type of LanguagePack")
          pack.labels.forEach(function(value, key, pack) {
            pack.add(key, value)
          }, acc)
        },
        acc: acc.pack,
      }).update()
    }, {
      root: root,
      pack: this.pack,
    })

    return this
  }

  ///@type {String} key
  ///@type {any} [...params]
  ///@return {String}
  get = function(key/*, ...params */) {
    if (!Core.isType(this.pack, LanguagePack)) {
      return ""
    }

    var label = this.pack.labels.get(key)
    if (!Core.isType(label, String)) {
      return key
    }

    if (argument_count > 1) {
      for (var index = 1; index < argument_count; index++) {
        label = String.replaceAll(label, "{" + string(index - 1) + "}", argument[index])
      }
    }

    return label
  }

  ///@return {LanguageType}
  getCode = function() {
    if (!Core.isType(this.pack, LanguagePack)) {
      return LanguageType.en_EN
    }

    return this.pack.code
  }
}
global.__Language = new _Language()
#macro Language global.__Language
