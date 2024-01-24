///@package io.alkapivo.core.service.sound

#macro BeanSoundService "SoundService"

function SoundService(): Service() constructor {

  ///@type {Map<String, SoundTemplate>}
  templates = new Map(String, SoundTemplate)

  ///@type {Map<String, GMSound>}
  sounds = new Map(String, any)

  ///@type {EventPump}
  dispatcher = new EventPump(this, new Map(String, Callable, { }))

  ///@override
  ///@return {SoundService}
  free = function() {
    this.sounds.forEach(function(sound, key) {
      try {
        audio_destroy_stream(sound)
      } catch (exception) {
        Logger.error("SoundService", $"Cannot parse key '{key}'. {exception.message}")
      }
    }).clear()
    return this
  }
}

