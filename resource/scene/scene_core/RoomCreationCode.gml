Core.print("Init scene_core")

var layerId = Scene.fetchLayer("instance_main", 100)

global.__coreController = GMObjectUtil.factoryStructInstance(
	GMServiceInstance, 
	Scene.fetchLayer("instance_main", 100),
	{
	  fpsReport: "",
    fpsReportPath: null,
    fpsTimer: new Timer(1.0, { loop: Infinity }),
    fpsReportTimer: new Timer(10.0, { loop: Infinity }),
    fpsValue: GAME_FPS,
    fpsRealValue: GAME_FPS,
    generateRow: function(message) {
      var z = function(v) {
        return (v < 10 ? "0" : "") + string(v)
      }

      var date =
            string(current_year) + "-"
          + z(current_month) + "-"
          + z(current_day)   + "_"
          + z(current_hour)  + "-"
          + z(current_minute)+ "-"
          + z(current_second)

      return $"{date},{message}"
    },
    initFpsReport: function(context, filename) {
      context.fpsReportPath = $"{program_directory}{filename}"
      var file = file_text_open_write(context.fpsReportPath)
      var row = context.generateRow($"{context.fpsValue},{context.fpsRealValue}")
      file_text_write_string(file, $"timestamp,FPS_MIN,FPS_REAL_MIN\n{row}\n")
      file_text_close(file);
    },
    updateBegin: function() {
	    if (!Global.inject("__GMRT_INITIALIZED", false)) {
        Core.print("========== RUN INIT SCRIPTS BEGIN ==========")

        randomize()
        init_Core()
        init_GMTF()

        Global.set("__GMRT_INITIALIZED", true)
        Core.print("========== RUN INIT SCRIPTS END ==========")

        Core.loadProperties(FileUtil.get($"{working_directory}core-properties.json"))
        if (!Beans.exists(BeanDisplayService)) {
          Beans.add(Beans.factory(BeanDisplayService, GMServiceInstance, Scene.fetchLayer("instance_main", 100),
            new DisplayService({
              windowWidth: 960,
              windowHeight: 540,
              scale: 1.0,
            })))
        }

        var displayService = Beans.get(BeanDisplayService)
        displayService.scale = 1
        displayService.windowWidth = 960
        displayService.windowHeight = 540
        displayService.minWidth = 960
        displayService.minHeight = 540
        displayService.beforeFullscreenWidth = displayService.windowWidth
        displayService.beforeFullscreenHeight = displayService.windowHeight
        displayService.previousWidth = displayService.beforeFullscreenWidth
        displayService.previousHeight = displayService.beforeFullscreenHeight
        displayService.previousGuiWidth = displayService.windowWidth / displayService.scale
        displayService.previousGuiHeight = displayService.windowHeight / displayService.scale
        displayService.resize(displayService.windowWidth, displayService.windowHeight)

        var cliParser = new CLIParamParser({
          cliParams: new Array(CLIParam, [
            new CLIParam({
              name: "-t",
              fullName: "--test",
              description: "Run tests from test suite",
              args: [
                {
                  name: "file",
                  type: "String",
                  description: "Path to test suite"
                }
              ],
              handler: function(args) {
                if (!Beans.exists(BeanTestRunner)) {
                  Beans.add(Beans.factory(BeanTestRunner, GMServiceInstance,
                      Scene.fetchLayer("instance_main", 100), new TestRunner()))
                }

                var file = args.get(0)
                Logger.debug("CLIParamParser", $"Add test {file}")

                Beans.get(BeanTestRunner).push(file)
              },
            }),
            new CLIParam({
              name: "-T",
              fullName: "--tests",
              description: "Run tests from test suites",
              args: [
                {
                  name: "files",
                  type: "String",
                  description: "Comma separated list of paths to test suites"
                }
              ],
              handler: function(args) {
                if (!Beans.exists(BeanTestRunner)) {
                  Beans.add(Beans.factory(BeanTestRunner, GMServiceInstance,
                      Scene.fetchLayer("instance_main", 100), new TestRunner()))
                }

                var files = args.get(0)
                String.split(files, ",").forEach(function(path) {
                  var test = String.trim(path)
                  if (test == "") {
                    return
                  }

                  Logger.debug("CLIParamParser", $"Add test {test}")
                  
                  Beans.get(BeanTestRunner).push(test)
                })
              },
            }),
            new CLIParam({
              name: "-f",
              fullName: "--fullscreen",
              description: "Force fullscreen mode",
              handler: function() {
                Beans.get(BeanDisplayService).setFullscreen(true)
              },
            }),
            new CLIParam({
              name: "-w",
              fullName: "--window",
              description: "Force window mode",
              handler: function() {
                Beans.get(BeanDisplayService)
                  .setFullscreen(false)
                  .setBorderlessWindow(false)
                  .center()
              },
            }),
            new CLIParam({
              name: "-L",
              fullName: "--language",
              description: "Force language",
              args: [
                {
                  name: "langCode",
                  type: "String",
                  description: "Language type"
                }
              ],
              handler: function(args) {
                var langType = args.get(0)
                if (!LanguageType.contains(langType)) {
                  Logger.error("Visu", $"Language type not supported: {langType}")
                  return
                }

                Language.load(langType)
              },
            }),
            new CLIParam({
              name: "-F",
              fullName: "--fps",
              description: "Measure fps to file",
              handler: function() {
                static z = function(v) {
                  return (v < 10 ? "0" : "") + string(v)
                }

                var filename = string(current_year) + "-"
                  + z(current_month) + "-"
                  + z(current_day) + "_"
                  + z(current_hour) + "-"
                  + z(current_minute) + "-fps-report.csv"

                CoreController.initFpsReport(CoreController, filename)
              }
            }),
            new CLIParam({
              name: "-p",
              fullName: "--properties",
              description: "Override properties",
              args: [
                {
                  name: "prompt",
                  type: "String",
                  description: "Properties string, entries are \";\" separated, key-value are \"=\" separeated"
                }
              ],
              handler: function(args) {
                var prompt = args.get(0)
                String.split(prompt, ";").forEach(function(entry) {
                  var tuple = String.split(entry, "=")
                  if (tuple.size() != 2) {
                    Logger.error("CLIParamParser", $"Cannot parse properties tuple: {tuple.getContainer()}")
                    return
                  }

                  var key = tuple.get(0)
                  var value = tuple.get(1)
                  value = (String.getFirstChar(value) == "["
                      || String.getFirstChar(value) = "{"
                      || String.toLowerCase(value) == "true"
                      || String.toLowerCase(value) == "false")
                    ? JSON.parse(value, value)
                    : NumberUtil.parse(value, value)
                  var displayValue = Core.isType(value, Array)
                    ? value.getContainer()
                    : value
                  Logger.debug("CLIParamParser", $"Set property key: {key}, value: {displayValue}")
                  Core.setProperty(key, value)
                })
              }
            })
          ])
        })

        cliParser.print().parse()
      }
	  },
	  update: function() {
      if (this.fpsReportPath != null) {
        this.fpsValue = min(this.fpsValue, abs(fps))
        this.fpsRealValue = min(this.fpsRealValue, abs(fps_real))
        if (this.fpsTimer.update().finished) {
          var row = this.generateRow($"{abs(this.fpsValue)},{abs(this.fpsRealValue)}")
          this.fpsReport = this.fpsReport == "" ? row : $"{this.fpsReport}\n{row}"
          this.fpsValue = GAME_FPS
          this.fpsRealValue = 9999
        }
      }
      
	    if (this.fpsReportPath != null && this.fpsReportTimer.update().finished) {
        var file = file_text_open_append(this.fpsReportPath)
        if (file != -1) {
          file_text_write_string(file, this.fpsReport)
          file_text_writeln(file)
          file_text_close(file)
          this.fpsReport = ""
        }
      }
	  }
	}
).__context
#macro CoreController global.__coreController
