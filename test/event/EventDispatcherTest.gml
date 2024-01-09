///@package io.alkapivo.test.core.EventDispatcherTest

function EventDispatcherTest(): Test() constructor {
    name = "Test EventDispatcher.gml"
    cases = [
        {
            name: "EventDispatcher.send",
            config: {
                events: [
                    new Event("notify"),
                    new Event("count", "Current size: {0}")
                ],
                dispatchers: new Map(any, any, {
                    notify: function(event) {
                        
                    },
                    count: function(event) {

                    }
                })
            },
            test: function(config) {

                return {
                    message: "passed",
                    config: config
                }
            }
        }
    ]
}