///@package io.alkapivo.core.service.sound

function SoundService(): Service() constructor {

  ///@type {Map<String, AssetSound>}
  templates = new Map(String, String)

  ///@type {Map<String, Sound>}
  sounds = new Map(String, Sound)

  ///@type {EventDispatcher}
  dispatcher = new EventDispatcher(this, new Map(String, Callable, { }))
}

