///@package io.alkapivo.core.service.file

///@param {Struct} _controller
///@param {Struct} [config]
function FileService(_controller, config = {}): Service() constructor {

  ///@type {Controller}
  controller = Assert.isType(_controller, Struct)

  ///@type {EventDispatcher}
  dispatcher = new EventDispatcher(this, new Map(String, Callable, {
    "fetch-file": function(event) {
      var task = new Task("fetch-file-buffer")
        .setPromise(event.promise) // pass promise to TaskExecutor
        .setState(new Map(String, any, { 
          path: Assert.isType(event.data.path, String)
        }))
        .whenUpdate(function(executor) {
          var path = this.state.get("path")
          var buffer = BufferUtil.loadAsTextBuffer(path)
          var data = buffer.get()
          buffer.free()
          Logger.info("FileService", $"FetchFileBuffer successfully: {path}")
          this.fullfill({
            path: path,
            data: data,
          })
        })
      
      this.executor.add(task)
      event.setPromise() // disable promise in EventDispatcher, the promise will be resolved within TaskExecutor
    },
    "fetch-file-dialog": function(event) {
      this.send(new Event("fetch-file")
        .setPromise(event.promise)
        .setData({ path: FileUtil.getPathToOpenWithDialog(event.data) }))
      event.setPromise() // disable promise in EventDispatcher, the promise will be resolved within TaskExecutor
    },
    "fetch-file-sync": function(event) {
      var path = Assert.isType(event.data.path, String)
      var file = file_text_open_read(path)
      if (file == -1) {
        throw new FileNotFoundException(path)
      }

      var data = "";
      while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        data = data + line + "\n"
        file_text_readln(file);
      }
      file_text_close(file)
      Logger.info("FileService", $"fetch-file-sync successfully: {path}")
      return {
        path: path,
        data: data,
      }
    },
    "fetch-file-sync-dialog": function(event) {
      this.send(new Event("fetch-file-sync")
        .setPromise(event.promise)
        .setData({ path: FileUtil.getPathToOpenWithDialog(event.data) }))
      event.setPromise() // disable promise in EventDispatcher, the promise will be resolved within TaskExecutor
    },
    "save-file-sync": function(event) {
      var path = Assert.isType(event.data.path, String)
      var data = Assert.isType(event.data.data, String)
      var file = file_text_open_write(event.data.path);
      if (file == -1) {
        throw new FileNotFoundException(path)
      }

      file_text_write_string(file, data);
      file_text_close(file);
      Logger.info("FileService", $"save-file-sync successfully: {path}")
    },
  }))

  ///@type {TaskExecutor}
  executor = new TaskExecutor(this)

  ///@param {Event} event
  ///@return {?Promise}
  send = method(this, function(event) {
    Struct.set(event.data, "fileService", this)
    return this.dispatcher.send(event)
  })

  ///@return {FileService}
  update = method(this, function() {
    this.dispatcher.update()
    this.executor.update()
    return this
  })
}
