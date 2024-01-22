///@package io.alkapivo.core.service.sound

function SoundService(): Service() constructor {

  ///@type {Map<String, AssetSound>}
  templates = new Map(String, String)

  ///@type {Map<String, Sound>}
  sounds = new Map(String, Sound)

  ///@type {EventPump}
  dispatcher = new EventPump(this, new Map(String, Callable, { }))
}

