///@package io.alkapivo.core.lang

///@param {String} _message
function Exception(_message) constructor {

  ///@type {String}
  message = _message

  ///@private
  print = function() {
    show_debug_message(this.message)
    var stackTrace = debug_get_callstack(50)
    var size = GMArray.size(stackTrace)
    for (var index = 0; index < size; index++) {
      var line = string(stackTrace[index])
      if (line != "0") {
        line = "\tat " + line;
        show_debug_message(line)
      }
    }
  }
  
  this.print()
}

#macro _vscode_bug_empty_string ""

///@param {String} _message
function InvalidClassException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function InvalidAssertException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function AlreadyBindedException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function ParseException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function FileNotFoundException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function TooManyArgumentsException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function VideoOpenException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function PropertyNotFoundException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function InvalidStatusException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }

///@param {String} _message
function CollectionAlreadyContainsException(_message = _vscode_bug_empty_string): Exception(_message) constructor { }
