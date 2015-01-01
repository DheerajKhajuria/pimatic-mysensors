module.exports = (env) ->

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
        env.logger.info result
        if result.sender is parseInt(@id)
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              if result.type is 0
                console.log "temp" , result.value 
                @_temperatue = result.value
                @emit "temperature", @_temperatue
              if result.type is 1
                console.log "humidity" , result.value
                @_humidity = result.value
                @emit "humidity", @_humidity
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity
  # ###Finally
  # Create a instance of my plugin
  mySensors = new MySensors
  # and return it to the framework.
  return mySensors