///@package io.alkapivo.shader.screen.shader_dissolve
show_debug_message("init ShaderDissolve.gml")


///@static
///@type {Struct}
global.__ShaderDissolve = {
  template: function() {
    return {
      type: "GLSL_ES",
      uniforms: {
        u_time: "TIME",
      },
    }
  },
  config: function() {
    return {
      u_time: {
        store: { value: 1.0 },
        components: { }
      },
    }
  },
  install: function(shaders, config) {
    Struct.set(shaders, "shader_dissolve", ShaderDissolve.template())
    Struct.set(config, "shader_dissolve", ShaderDissolve.config())
  },
}

#macro ShaderDissolve global.__ShaderDissolve
