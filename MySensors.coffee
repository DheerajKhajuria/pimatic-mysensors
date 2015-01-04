module.exports = (env) ->

  V_TEMP             = 0
  V_HUM              = 1
  V_LIGHT            = 2
  V_DIMMER           = 3
  V_PRESSURE         = 4
  V_FORECAST         = 5
  V_RAIN             = 6
  V_RAINRATE         = 7
  V_WIND             = 8
  V_GUST             = 9
  V_DIRECTION        = 10
  V_UV               = 11
  V_WEIGHT           = 12
  V_DISTANCE         = 13
  V_IMPEDANCE        = 14
  V_ARMED            = 15
  V_TRIPPED          = 16
  V_WATT             = 17
  V_KWH              = 18
  V_SCENE_ON         = 19
  V_SCENE_OFF        = 20
  V_HEATER           = 21
  V_HEATER_SW        = 22
  V_LIGHT_LEVEL      = 23
  V_VAR1             = 24
  V_VAR2             = 25
  V_VAR3             = 26
  V_VAR4             = 27
  V_VAR5             = 28
  V_UP               = 29
  V_DOWN             = 30
  V_STOP             = 31
  V_IR_SEND          = 32
  V_IR_RECEIVE       = 33
  V_FLOW             = 34
  V_VOLUME           = 35
  V_LOCK_STATUS      = 36

  ZERO_VALUE         = "0"


  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  Board = require('./board')

  class MySensors extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @board = new Board(@config)

      @board.connect().then( =>
        env.logger.info("Connected to MySensors Gateway.")
      ) 
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("MySensorsDHT", {
        configDef: deviceConfigDef.MySensorsDHT, 
        createCallback: (config) => new MySensorsDHT(config, @board)
      })    

      @framework.deviceManager.registerDeviceClass("MySensorsPIR", {
        configDef: deviceConfigDef.MySensorsPIR, 
        createCallback: (config) => new MySensorsPIR(config, @board)
      })    

  class MySensorsDHT extends env.devices.TemperatureSensor

    constructor: (@config, @board) ->
      @id = config.id
      @name = config.name
      env.logger.info "MySensorsDHT" , @id , @name

      @attributes = {}

      @attributes.temperature = {
        description: "the messured temperature"
        type: "number"
        unit: '°C'
      }

      @attributes.humidity = {
          description: "the messured humidity"
          type: "number"
          unit: '%'
      }
     
      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              env.logger.info "MySensorDHT" , result
              if result.type is V_TEMP
                #env.logger.info  "temp" , result.value 
                @_temperatue = parseInt(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_HUM
                #env.logger.info  "humidity" , result.value
                @_humidity = parseInt(result.value)
                @emit "humidity", @_humidity
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity


  class MySensorsPIR extends env.devices.PresenceSensor

    constructor: (@config,@board) ->
      @id = config.id
      @name = config.name
      #@_presence = lastState?.presence?.value or false

      resetPresence = ( =>
        @_setPresence(no)
      )

      @board.on('rfValue', (result) =>
        env.logger.info "MySensorPIR", result
        if result.sender is @config.nodeid and result.type is V_TRIPPED and result.sensor is @config.sensorid
          unless result.value is ZERO_VALUE
            @_setPresence(yes)
          clearTimeout(@_resetPresenceTimeout)
          @_resetPresenceTimeout = setTimeout(resetPresence, @config.resetTime)
      )
      super()

    getPresence: -> Promise.resolve @_presence

  # ###Finally
  # Create a instance of my plugin
  mySensors = new MySensors
  # and return it to the framework.
  return mySensors