///@package io.alkapivo.core.util
show_debug_message("init VersionConfig.gml")


///@param {?Struct} [config]
function VersionConfig(config = null) constructor {

  ///@type {Map<String, Struct>}
  current = new Map(String, Struct, Struct.getIfType(config, "current", Struct))
}
