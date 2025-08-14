///@package io.alkapivo.core.test

///@param {Struct} [json]
function TestSuite(json = {}) constructor {
  
  ///@type {String}
  name = Assert.isType(Struct.getDefault(json, "name", "Undefined test suite"), String)

  ///@type {Boolean}
  finished = false

  ///@type {Array<Test>}
  tests = new Array(Test, GMArray.map(
    (Core.isType(Struct.get(json, "tests"), GMArray) 
      ? json.tests 
      : []),
    function(json) {
      return new Test(json)
    }))

  ///@type {Array<Struct>}
  report = new Array(Struct)

  ///@type {Boolean}
  stopAfterFailure = Struct.getDefault(json, "stopAfterFailure", false)

  ///@type {FPSMeasure}
  measure = new FPSMeasure()

  ///@private
  ///@type {Number}
  pointer = 0

  ///@param {TaskExecutor}
  ///@return {TestSuite}
  update = function(executor) {
    if (this.finished) {
      return this
    }

    //this.measure.update()

    if (this.pointer >= this.tests.size()) {
      this.finished = true
      return this
    }

    if (this.pointer == this.report.size()) {
      var test = this.tests.get(this.pointer)
      var task = Callable.run(test.handler, Struct.get(test, "data"))
      executor.add(task)
      this.report.add({
        test: test.handler,
        description: test.description,
        result: task.promise,
      })
    } else {
      var status = this.report.getLast().result.status
      if (this.stopAfterFailure) {
        switch (status) {
          case PromiseStatus.REJECTED: this.finished = true
            break
          case PromiseStatus.FULLFILLED: this.pointer += 1
            break
        }
      } else if (status != PromiseStatus.PENDING) {
        this.pointer += 1
      }
    }

    return this
  }
}


function FPSMeasure() constructor {
  ///@type {Array<Array<Struct>>}
  timeline = new Array(Array, [ new Array(Struct) ])

  ///@type {Number}
  time = 0.0

  ///@type {Number}
  startTime = 0.0

  ///@return {FPSMeasure}
  update = function() {
    var current = get_timer()
    if (this.time == 0.0) {
      this.time = current
      this.startTime = current
    }

    if (current - this.time >= 1000000) {
      this.time = current
      timeline.add(new Array(Struct))
    }

    timeline.getLast().add({
      "fps": fps,
      "fpsReal": fps_real,
    })

    return this
  }

  ///@return {Array<Struct>}
  generateReport = function() {
    reports = new Array(Struct)

    this.timeline.forEach(function(cell, index, reports) {
      var report = {
        minFps: null,
        maxFps: null,
        avgFps: null,
        minFpsReal: null,
        maxFpsReal: null,
        avgFpsReal: null,
      }

      cell.forEach(function(entry, index, report) {
        report.minFps = report.minFps == null ? entry.fps : min(report.minFps, entry.fps)
        report.maxFps = report.maxFps == null ? entry.fps : min(report.maxFps, entry.fps)
        report.avgFps = report.avgFps == null ? entry.fps : report.avgFps + entry.fps
        report.minFpsReal = report.minFpsReal == null ? entry.fpsReal : min(report.minFpsReal, entry.fpsReal)
        report.maxFpsReal = report.maxFpsReal == null ? entry.fpsReal : min(report.maxFpsReal, entry.fpsReal)
        report.avgFpsReal = report.avgFpsReal == null ? entry.fpsReal : report.avgFpsReal + entry.fpsReal
      }, report)
      
      report.avgFps = (report.avgFps == null || cell.size() == 0) ? 0.0 : report.avgFps / cell.size()
      report.avgFpsReal = (report.avgFpsReal == null || cell.size() == 0) ? 0.0 : report.avgFpsReal / cell.size()
      reports.add(report)
    }, reports)

    return {
      duration: (get_timer() - this.startTime) / 1000000,
      data: reports.container,
    }
  }
}