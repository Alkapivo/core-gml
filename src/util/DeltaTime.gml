///@package io.alkapivo.core.DeltaTime

function _DeltaTime() constructor {
    
    ///@param {Number} value
    ///@return {Number}
    static apply = function(value) {
        return value
    }
}
global.__DeltaTime = new _DeltaTime()

#macro DeltaTime global.__DeltaTime
