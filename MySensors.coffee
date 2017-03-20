module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  events = env.require 'events'
  M = env.matcher

  V_TEMP               = 0
  V_HUM                = 1
  V_STATUS             = 2
  V_PERCENTAGE         = 3
  V_PRESSURE           = 4
  V_FORECAST           = 5
  V_RAIN               = 6
  V_RAINRATE           = 7
  V_WIND               = 8
  V_GUST               = 9
  V_DIRECTION          = 10
  V_UV                 = 11
  V_WEIGHT             = 12
  V_DISTANCE           = 13
  V_IMPEDANCE          = 14
  V_ARMED              = 15
  V_TRIPPED            = 16
  V_WATT               = 17
  V_KWH                = 18
  V_SCENE_ON           = 19
  V_SCENE_OFF          = 20
  V_HEATER             = 21
  V_HEATER_SW          = 22
  V_LIGHT_LEVEL        = 23
  V_VAR1               = 24
  V_VAR2               = 25
  V_VAR3               = 26
  V_VAR4               = 27
  V_VAR5               = 28
  V_UP                 = 29
  V_DOWN               = 30
  V_STOP               = 31
  V_IR_SEND            = 32
  V_IR_RECEIVE         = 33
  V_FLOW               = 34
  V_VOLUME             = 35
  V_LOCK_STATUS        = 36
  V_LEVEL              = 37
  V_VOLTAGE            = 38
  V_CURRENT            = 39
  V_RGB                = 40
  V_RGBW               = 41
  V_ID                 = 42
  V_UNIT_PREFIX        = 43
  V_HVAC_SETPOINT_COOL = 44
  V_HVAC_SETPOINT_HEAT = 45
  V_HVAC_FLOW_MODE     = 46
  V_TEXT               = 47
  V_CUSTOM             = 48
  V_POSITION           = 49
  V_IR_RECORD          = 50
  V_PH                 = 51
  V_ORP                = 52
  V_EC                 = 53

  ZERO_VALUE         = "0"

  FIRMWARE_BLOCK_SIZE = 16
  BROADCAST_ADDRESS   = 255
  NODE_SENSOR_ID      = 255

  C_PRESENTATION     = 0
  C_SET              = 1
  C_REQ              = 2
  C_INTERNAL         = 3
  C_STREAM           = 4


  I_BATTERY_LEVEL    = 0
  I_TIME             = 1
  I_VERSION          = 2
  I_ID_REQUEST       = 3
  I_ID_RESPONSE      = 4
  I_INCLUSION_MODE   = 5
  I_CONFIG           = 6
  I_PING             = 7
  I_PING_ACK         = 8
  I_LOG_MESSAGE      = 9
  I_CHILDREN         = 10
  I_SKETCH_NAME      = 11
  I_SKETCH_VERSION   = 12
  I_REBOOT           = 13
  I_GATEWAY_READY    = 14
  I_REQUEST_SIGNING  = 15
  I_GET_NONCE        = 16
  I_GET_NONCE_RESPONSE = 17
  I_HEARTBEAT        = 18
  I_PRESENTATION     = 19
  I_DISCOVER         = 20
  I_DISCOVER_RESPONSE = 21
  I_HEARTBEAT_RESPONSE = 22
  I_LOCKED           = 23

  S_DOOR             = 0
  S_MOTION           = 1
  S_SMOKE            = 2
  S_LIGHT            = 3
  S_DIMMER           = 4
  S_COVER            = 5
  S_TEMP             = 6
  S_HUM              = 7
  S_BARO             = 8
  S_WIND             = 9
  S_RAIN             = 10
  S_UV               = 11
  S_WEIGHT           = 12
  S_POWER            = 13
  S_HEATER           = 14
  S_DISTANCE         = 15
  S_LIGHT_LEVEL      = 16
  S_ARDUINO_NODE     = 17
  S_ARDUINO_REPEATER_NODE    = 18
  S_LOCK             = 19
  S_IR               = 20
  S_WATER            = 21
  S_AIR_QUALITY      = 22
  S_CUSTOM           = 23
  S_DUST             = 24
  S_SCENE_CONTROLLER = 25
  S_RGB_LIGHT        = 26
  S_RGBW_LIGHT       = 27
  S_COLOR_SENSOR     = 28
  S_HVAC             = 29
  S_MULTIMETER       = 30
  S_SPRINKLER        = 31
  S_WATER_LEAK       = 32
  S_SOUND            = 33
  S_VIBRATION        = 34
  S_MOISTURE         = 35
  S_INFO             = 36
  S_GAS              = 37
  S_GPS              = 38
  S_WATER_QUALITY    = 39

  ST_FIRMWARE_CONFIG_REQUEST   = 0
  ST_FIRMWARE_CONFIG_RESPONSE  = 1
  ST_FIRMWARE_REQUEST          = 2
  ST_FIRMWARE_RESPONSE         = 3
  ST_SOUND           = 4
  ST_IMAGE           = 5

  P_STRING           = 0
  P_BYTE             = 1
  P_INT16            = 2
  P_UINT16           = 3
  P_LONG32           = 4
  P_ULONG32          = 5
  P_CUSTOM           = 6
  P_FLOAT32          = 7

  class Board extends events.EventEmitter

    constructor: (framework,config) ->
      @config = config
      @framework = framework

      assert  @config.time in ["utc", "local"]
      assert @config.driver in ["serialport", "ethernet"]
      
      @timeOffset = 0
      if @config.time is "local"
        @timeOffset = ((new Date()).getTimezoneOffset() * 60 )
        env.logger.debug "<- TimeOffset ", @timeOffset
        
      # setup a new driver
      switch @config.driver
        when "serialport"
          SerialPortDriver = require('./serialport')(env)
          @driver = new SerialPortDriver(@config.driverOptions)
        when "ethernet"
          EthernetDriver = require './ethernet'
          @driver = new EthernetDriver(@config.driverOptions)

      @driver.on('error', (error) => 
        env.logger.error error
      )
      @driver.on('reconnect', (error) =>
        @emit('reconnect', error)
      )
      @driver.on('close', =>
        @emit('close')
      )
      @driver.on("data", (data) =>
        @emit "data", data
      )
      @driver.on("line", (line) =>
        @emit "line", line
        @_rfReceived(line)
      )


    connect: (timeout = 2500, retries = 3) ->

      return @pendingConnect = @driver.connect(timeout, retries)

    disconnect: ->

      return @driver.disconnect()

    _rfReceived: (data) ->
      # decoding message
      datas = data.toString().split(";")
      sender = parseInt datas[0]

      sensor = parseInt datas[1]
      command = parseInt datas[2]
      ack = parseInt datas[3]
      type = parseInt datas[4]
      rawpayload = ""

      if (datas[5])
        rawpayload = datas[5].trim()

      switch command
        when C_PRESENTATION
          if @config.debug
            env.logger.debug "<- Presented Node ", datas
          @_rfpresent(sender,sensor,type)
        when C_SET
          @_rfsendtoboard(sender,sensor,type,rawpayload)
        when C_REQ
          if @config.debug
            env.logger.debug "<- request from  ", sender, rawpayload
          @_rfrequest(sender,sensor,type)
        when C_INTERNAL
          switch type
            when I_BATTERY_LEVEL
              if @config.debug
                env.logger.debug "<- I_BATTERY_LEVEL ", sender, rawpayload
              @_rfsendbatterystat(sender,rawpayload)
            when I_TIME
              if @config.debug
                env.logger.debug "<- I_TIME ", data
              @_rfsendTime(sender, sensor)
            when I_VERSION
              if @config.debug
                env.logger.debug "<- I_VERSION ", rawpayload
            when I_ID_REQUEST
              if @config.debug
                env.logger.debug "<- I_ID_REQUEST ", data
              @_rfsendNextAvailableSensorId()
            when I_ID_RESPONSE
              if @config.debug
                env.logger.debug "<- I_ID_RESPONSE ", data
            when I_INCLUSION_MODE
              if @config.debug
                env.logger.debug "<- I_INCLUSION_MODE ", data
            when I_CONFIG
              if @config.debug
                env.logger.debug "<- I_CONFIG ", data
              @_rfsendConfig(sender)
            when I_PING
              if @config.debug
                env.logger.debug "<- I_PING ", data
            when I_PING_ACK
              if @config.debug
                env.logger.debug "<- I_PING_ACK ", data
            when I_LOG_MESSAGE
              if @config.debug
                env.logger.debug "<- I_LOG_MESSAGE ", data
            when I_CHILDREN
              if @config.debug
                env.logger.debug "<- I_CHILDREN ", data
            when I_SKETCH_NAME
              #saveSketchName(sender, payload, db);
              if @config.debug
                env.logger.debug "<- I_SKETCH_NAME ", data
            when I_SKETCH_VERSION
              #saveSketchVersion(sender, payload, db);
              if @config.debug
                env.logger.debug "<- I_SKETCH_VERSION ", data


    _rfsendTime: (destination,sensor) ->
      date = new Date()
      payload = Math.floor( ( date.getTime() ) / 1000 ) - @timeOffset
      datas =
      {
        "destination": destination,
        "sensor": sensor,
        "type"  : I_TIME,
        "ack"   : 0,
        "command" : C_INTERNAL,
        "value" : payload
      }
      @_rfWrite( datas)


    _rfsendNextAvailableSensorId: ->
      newid = false
      nextnodeid = @config.startingNodeId
      if nextnodeid is null
        nextnodeid = 1
      else
        nextnodeid +=1
      while newid is false
        newid = not @framework.deviceManager.devicesConfig.some (device, iterator) =>
          device.nodeid is nextnodeid
        if newid is false
          nextnodeid +=1

      if newid is true and nextnodeid < 255
        datas =
        {
          "destination": BROADCAST_ADDRESS,
          "sensor": NODE_SENSOR_ID,
          "type"  : I_ID_RESPONSE,
          "ack"   : 0,
          "command" : C_INTERNAL,
          "value" : nextnodeid
        }
        @config.startingNodeId = nextnodeid
        @_rfWrite(datas)
        @framework.saveConfig()
      else
        env.logger.error "-> Error assigning next node ID"

    _rfrequest: (sender,sensor,type) ->
      result = {
        "sender": sender,
        "sensor": sensor,
        "type": type
      }
      @emit "rfRequest", result

    _rfpresent: (sender,sensor,type) ->
      result = {
        "sender": sender,
        "sensor": sensor,
        "type"  : type
      }
      @emit "rfPresent", result

    _rfsendtoboard: (sender,sensor,type,rawpayload) ->
      result = {
        "sender": sender,
        "sensor": sensor,
        "type"  : type,
        "value" : rawpayload
      }
      @emit "rfValue", result

    _rfsendbatterystat: (sender,rawpayload) ->
      result = {
        "sender": sender,
        "value" : rawpayload
      }
      @emit "rfbattery", result

    _rfsendConfig: (destination) ->
      datas = {
        "destination": destination,
        "sensor": NODE_SENSOR_ID,
        "type"  : I_CONFIG,
        "ack"   : 0,
        "command" : C_INTERNAL,
        "value" : @config.metric
      }
      @_rfWrite(datas)

    _rfWrite: (datas) ->
      datas.command ?= C_SET
      data = @_rfencode(datas.destination,datas.sensor,datas.command,datas.ack,datas.type,datas.value)
      if @config.debug
        env.logger.debug "-> Sending ", data
      @driver.write(data)

    _rfencode: (destination, sensor, command, acknowledge, type, payload) ->
      msg = destination.toString(10) + ";" + sensor.toString(10) + ";" + command.toString(10) + ";" + acknowledge.toString(10) + ";" + type.toString(10) + ";";
      msg += payload
      msg += '\n'
      return msg.toString()

  Promise.promisifyAll(Board.prototype)
  ## MySensors class.
  class MySensors extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @board = new Board(@framework, @config)
      @board.connect().then( =>
        env.logger.info("Connected to MySensors Gateway.")
      )

      deviceConfigDef = require("./device-config-schema")

      # Discover MySensor nodes
      @framework.deviceManager.on('discover', (eventData) =>

        @framework.deviceManager.discoverMessage(
            'pimatic-mysensors', "Searching for nodes"
          )

        # Stop searching after configured time
        setTimeout(( =>
          @board.removeListener("rfPresent", discoverListener)
        ), eventData.time)

        # Received presentation message from the gateway
        @board.on("rfPresent", discoverListener = (result) =>
          newdevice = true
          nodeid = result.sender
          sensorid = result.sensor
          sensortype = result.type

          # Check if device already exists in pimatic
          newdevice = not @framework.deviceManager.devicesConfig.some (device, iterator) =>
            device.sensorid is sensorid and device.nodeid is nodeid

          # Device is a new device and not a battery device
          if newdevice
            # Temp sensor found
            if sensortype is S_TEMP
              config = {
                class: 'MySensorsDST',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Temp Sensor #{nodeid}.#{sensorid}", config
              )

            # PIR sensor found
            if sensortype is S_MOTION
              config = {
                class: 'MySensorsPIR',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Motion Sensor #{nodeid}.#{sensorid}", config
              )
            # Smoke sensor found
            if sensortype is S_SMOKE
              config = {
                class: 'MySensorsPIR',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Smoke Sensor #{nodeid}.#{sensorid}", config
              )

            # Moisture sensor found
            if sensortype is S_MOISTURE
              config = {
                class: 'MySensorsPIR',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Moisture Sensor #{nodeid}.#{sensorid}", config
              )

            # Leak sensor found
            if sensortype is S_WATER_LEAK
              config = {
                class: 'MySensorsPIR',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Leak Sensor #{nodeid}.#{sensorid}", config
              )

            # Contact sensor found
            if sensortype is S_DOOR
              config = {
                class: 'MySensorsButton',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Contact Sensor #{nodeid}.#{sensorid}", config
              )

            # Shutter found
            if sensortype is S_COVER
              config = {
                class: 'MySensorsShutter',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Shutter #{nodeid}.#{sensorid}", config
              )

            # Light sensor found
            if sensortype is S_LIGHT_LEVEL
              config = {
                class: 'MySensorsLight',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Light Sensor #{nodeid}.#{sensorid}", config
              )

            # Lux sensor found
            if sensortype is S_LIGHT_LEVEL
              config = {
                class: 'MySensorsLux',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Lux Sensor #{nodeid}.#{sensorid}", config
              )

            # kWh sensor found
            if sensortype is S_POWER
              config = {
                class: 'MySensorsPulseMeter',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "kWh Sensor #{nodeid}.#{sensorid}", config
              )

            # Water sensor found
            if sensortype is S_WATER
              config = {
                class: 'MySensorsWaterMeter',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Water Sensor #{nodeid}.#{sensorid}", config
              )

            # pH sensor found
            if sensortype is S_WATER_QUALITY
              config = {
                class: 'MySensorsPH',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "pH Sensor #{nodeid}.#{sensorid}", config
              )

            # Switch found
            if sensortype is S_LIGHT or sensortype is S_SPRINKLER
              config = {
                class: 'MySensorsSwitch',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Switch #{nodeid}.#{sensorid}", config
              )

            # Dimmer found
            if sensortype is S_DIMMER
              config = {
                class: 'MySensorsDimmer',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Dimmer #{nodeid}.#{sensorid}", config
              )

            # Distance sensor found
            if sensortype is S_DISTANCE
              config = {
                class: 'MySensorsDistance',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Distance Sensor #{nodeid}.#{sensorid}", config
              )

            # Gas sensor found
            if sensortype is S_AIR_QUALITY
              config = {
                class: 'MySensorsGas',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "Gas sensor #{nodeid}.#{sensorid}", config
              )
            
            # IR sensor found
            if sensortype is S_IR
              config = {
                class: 'MySensorsIR',
                nodeid: nodeid,
                sensorid: sensorid
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mysensors', "IR sensor #{nodeid}.#{sensorid}", config
              )
        )
      )

      @framework.ruleManager.addActionProvider(new MySensorsActionProvider @framework,@board, @config)

      deviceClasses = [
        MySensorsDHT
        MySensorsDST
        MySensorsBMP
        MySensorsPIR
        MySensorsSwitch
        MySensorsDimmer
        MySensorsPulseMeter
        MySensorsEnergyMeter
        MySensorsWaterMeter
        MySensorsPH
        MySensorsButton
        MySensorsLight
        MySensorsLux
        MySensorsDistance
        MySensorsGas
        MySensorsShutter
        MySensorsMulti
        MySensorsIR
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) =>
              device  =  new Cl(config,lastState, @board)
              return device
            })
      # registerDevice for MySensorsBattery device
      @framework.deviceManager.registerDeviceClass(MySensorsBattery.name, {
        configDef: deviceConfigDef[MySensorsBattery.name]
        createCallback: (config,lastState) =>
          device  =  new MySensorsBattery(config,lastState, @board,@framework)
          return device
        })

  class MySensorsDHT extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_temperatue = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsDHT ", @id, @name

      @attributes = {}

      @attributes.temperature = {
        description: "the measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.humidity = {
        description: "the measured humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              if mySensors.config.debug
                env.logger.debug "<- MySensorDHT ", result
              if result.type is V_TEMP
                #env.logger.debug  "temp", result.value
                @_temperatue = parseFloat(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_HUM
                #env.logger.debug  "humidity", result.value
                @_humidity = Math.round(parseFloat(result.value))
                @emit "humidity", @_humidity
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity
    getBattery: -> Promise.resolve @_battery

  class MySensorsDST extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_temperatue = lastState?.temperature?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsDST ", @id, @name

      @attributes = {}

      @attributes.temperature = {
        description: "the measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_TEMP and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorDST ", result
          @_temperatue = parseFloat(result.value)
          @emit "temperature", @_temperatue
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getBattery: -> Promise.resolve @_battery

  class MySensorsBMP extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_temperatue = lastState?.temperature?.value
      @_pressure = lastState?.pressure?.value
      @_forecast = lastState?.forecast?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsBMP ", @id, @name

      @attributes = {}

      @attributes.temperature = {
        description: "the measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.pressure = {
          description: "the measured pressure"
          type: "number"
          unit: 'hPa'
          acronym: 'mbar'
      }

      @attributes.forecast = {
          description: "the forecast"
          type: "string"
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }


      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              if mySensors.config.debug
                env.logger.debug "<- MySensorBMP ", result
              if result.type is V_TEMP
                #env.logger.debug  "temp", result.value
                @_temperatue = parseInt(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_PRESSURE
                #env.logger.debug  "pressure", result.value
                @_pressure = parseInt(result.value)
                @emit "pressure", @_pressure
              if result.type is V_FORECAST
                #env.logger.debug  "forecast", result.value
                @_forecast = result.value
                @emit "forecast", @_forecast

      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getPressure: -> Promise.resolve @_pressure
    getForecast: -> Promise.resolve @_forecast
    getBattery: -> Promise.resolve @_battery

  class MySensorsPulseMeter extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @voltage = @config.appliedVoltage

      @_watt = lastState?.watt?.value
      @_ampere = lastState?.ampere?.value
      @_kwh = lastState?.kWh?.value
      @_pulsecount = lastState?.pulsecount?.value
      @_battery = lastState?.battery?.value

      if mySensors.config.debug
        env.logger.debug "MySensorsPulseMeter ", @id, @name

      @attributes = {}

      @attributes.watt = {
        description: "the measured Wattage"
        type: "number"
        unit: 'W'
        acronym: 'Watt'
      }

      @attributes.pulsecount = {
        description: "Measure the Pulse Count"
        type: "number"
        #unit: ''
        hidden: yes
      }

      @attributes.kWh = {
        description: "the measured kWh"
        type: "number"
        unit: 'kWh'
        acronym: 'kWh'
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @attributes.ampere = {
        description: "the measured Ampere"
        type: "number",
        unit: "A"
        acronym: 'Ampere'
       }

      @rfRequestEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          datas =
          {
            "destination": @config.nodeid,
            "sensor": @config.sensorid,
            "type"  : V_VAR1,
            "value" : @_pulsecount,
            "ack"   : 1
          }
          @board._rfWrite(datas)
      )

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsPulseMeter", result
          if result.type is V_VAR1
            if mySensors.config.debug
              env.logger.debug "<- MySensorsPulseMeter V_VAR1"
            @_pulsecount = parseInt(result.value)
            @emit "pulsecount", @_pulsecount
          if result.type is V_WATT
            if mySensors.config.debug
              env.logger.debug "<- MySensorsPulseMeter V_WATT"
            @_watt = parseInt(result.value)
            @emit "watt", @_watt
            @_ampere = @_watt / @voltage
            @emit "ampere", @_ampere
          if result.type is V_KWH
            if mySensors.config.debug
              env.logger.debug "<- MySensorsPulseMeter V_KWH"
            @_kwh = parseFloat(result.value)
            @emit "kWh", @_kwh
      )
      @board.on("rfRequest", @rfRequestEventHandler)
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfRequest", @rfRequestEventHandler
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getWatt: -> Promise.resolve @_watt
    getPulsecount: -> Promise.resolve @_pulsecount
    getKWh: -> Promise.resolve @_kwh
    getBattery: -> Promise.resolve @_battery
    getAmpere: -> Promise.resolve @_ampere

  class MySensorsEnergyMeter extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      if mySensors.config.debug
        env.logger.debug "MySensorsEnergyMeter ", @id, @name

      @kWhlastTime = {}
      @attributes = {}
      @_watt = {}
      for sensorid in @config.sensorid
        do(sensorid) =>
          attr = "Phase_" + sensorid

          @attributes[attr] = {
            description: "this measure wattage"
            type: "number"
            displaySparkline: false
            unit: "W"
            acronym: attr
          }
          @kWhlastTime[sensorid] = Date.now()
          getter = ( =>  Promise.resolve @_watt[sensorid] )
          @_createGetter( attr, getter)
          @_watt[sensorid] = lastState?[attr]?.value

      @_kwh = lastState?.kWh?.value or 0
      @_totalPower = lastState?.totalPower?.value or 0
      @_rate = lastState?.rate?.value or 0
      @_battery = lastState?.battery?.value

      @attributes.totalPower = {
        description: "Total Watt"
        type: "number"
        unit: 'W'
        displaySparkline: false
        acronym: 'Total'
      }

      @attributes.kWh = {
        description: "this measure kWh"
        type: "number"
        unit: 'kWh'
        acronym: 'kWh'
      }

      @attributes.rate = {
        description: "Electricity Cost"
        type: "number"
        unit: ""
        displaySparkline: false
        acronym: @config.currency
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          if result.sensor in @config.sensorid and result.type is V_WATT
            if mySensors.config.debug
              env.logger.debug "<- MySensorsEnergyMeter", result
            @calculatePower(result)
      )

      @_resetWattage = setInterval(( =>
        env.logger.debug "<- MySensorsEnergyMeter setinterval"
        for sensorid in @config.sensorid
          if (new Date()) - @kWhlastTime[sensorid]  > @config.resetTime
            result = {}
            result =
            {
              sender: @config.nodeid,
              sensor: sensorid,
              type  : V_WATT,
              value : 0
            }
            @calculatePower(result)
        ), 30000)
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    calculatePower:(result) ->
      currdate = new Date()

      diffTime = currdate - @kWhlastTime[result.sensor]

      @_watt[result.sensor] =  Math.floor(parseInt(result.value))
      calibratedWattage = (@_watt[result.sensor] * (100 - @config.correction)/100)
      intKwh = ((calibratedWattage / 1000 ) * ( diffTime ) / 3600000)
      @_totalPower = 0
      for sensorid in @config.sensorid
        @_totalPower += @_watt[sensorid]

      @_kwh = @_kwh + intKwh
      @kWhlastTime[result.sensor] = currdate
      @_rate = @_rate + intKwh * @config.rate
      if mySensors.config.debug
        env.logger.debug "<- MySensorsEnergyMeter V_KWH", @_kwh , @_rate

      @emit "Phase_" + result.sensor, @_watt[result.sensor]
      @emit "totalPower" , @_totalPower
      @emit "kWh", @_kwh
      @emit "rate", @_rate

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      clearInterval(@_resetWattage)
      super()

    getKWh: -> Promise.resolve @_kwh
    getRate: -> Promise.resolve @_rate
    getTotalPower: -> Promise.resolve @_totalPower
    getBattery: -> Promise.resolve @_battery

  class MySensorsWaterMeter extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @_flow = lastState?.flow?.value
      @_volume = lastState?.volume?.value
      @_pulsecount = lastState?.pulsecount?.value
      @_battery = lastState?.battery?.value

      if mySensors.config.debug
        env.logger.debug "MySensorsWaterMeter ", @id, @name

      @attributes = {}

      @attributes.flow = {
        description: "the measured water in liter per minute"
        type: "number"
        unit: 'l/min'
        acronym: 'Flow'
      }

      @attributes.pulsecount = {
        description: "Measure the Pulse Count"
        type: "number"
        #unit: ''
        hidden: yes
      }

      @attributes.volume = {
        description: "the measured water in m3"
        type: "number"
        unit: 'm3'
        acronym: 'Total'
      }

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfRequestEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          datas =
          {
            "destination": @config.nodeid,
            "sensor": @config.sensorid,
            "type"  : V_VAR1,
            "value" : @_pulsecount,
            "ack"   : 1
          }
          @board._rfWrite(datas)
      )

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsWaterMeter", result
          if result.type is V_VAR1
            if mySensors.config.debug
              env.logger.debug "<- MySensorsWaterMeter V_VAR1"
            @_pulsecount = parseInt(result.value)
            @emit "pulsecount", @_pulsecount
          if result.type is V_FLOW
            if mySensors.config.debug
              env.logger.debug "<- MySensorsWaterMeter V_FLOW"
            @_flow = parseInt(result.value)
            @emit "flow", @_flow
          if result.type is V_VOLUME
            if mySensors.config.debug
              env.logger.debug "<- MySensorsWaterMeter V_VOLUME"
            @_volume = parseFloat(result.value)
            @emit "volume", @_volume

      )
      @board.on("rfRequest", @rfRequestEventHandler)
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfRequest", @rfRequestEventHandler
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getFlow: -> Promise.resolve @_flow
    getPulsecount: -> Promise.resolve @_pulsecount
    getVolume: -> Promise.resolve @_volume
    getBattery: -> Promise.resolve @_battery

  class MySensorsPH extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @_ph = lastState?.ph?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsPH ", @id, @name
      @attributes = {}

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @attributes.ph = {
        description: "the measured pH value"
        type: "number"
        unit: 'pH'
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsPH", result
          if result.type is V_PH or result.type is V_VAR1
            @_ph = parseFloat(result.value)
            @emit "ph", @_ph
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getPh: -> Promise.resolve @_ph
    getBattery: -> Promise.resolve @_battery

  class MySensorsPIR extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_presence = lastState?.presence?.value or false
      @_battery = lastState?.battery?.value

      if mySensors.config.debug
        env.logger.debug "MySensorsPIR ", @id, @name, @_presence

      @addAttribute('battery', {
        description: "Battery",
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
      })
      @['battery'] = ()-> Promise.resolve(@_battery)

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery = parseInt(result.value)
            @emit "battery", @_battery
      )

      resetPresence = ( =>
        @_setPresence(no)
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_TRIPPED and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorPIR ", result
          if result.value is ZERO_VALUE
            @_setPresence(no)
          else
            @_setPresence(yes)
          if @config.autoReset is true
            clearTimeout(@_resetPresenceTimeout)
            @_resetPresenceTimeout = setTimeout(( =>
              if @_destroyed then return
              @_setPresence(no)
            ), @config.resetTime)
      )

      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getPresence: -> Promise.resolve @_presence
    getBattery: -> Promise.resolve @_battery

  class MySensorsButton extends env.devices.ContactSensor

    constructor: (@config,lastState,@board) ->
      @id = @config.id
      @name = @config.name
      @_contact = lastState?.contact?.value or false
      if mySensors.config.debug
        env.logger.debug "MySensorsButton", @id, @name, @_contact

      @attributes = _.cloneDeep @attributes

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is ( V_TRIPPED or V_STATUS ) and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsButton ", result
          if result.value is ZERO_VALUE
            @_setContact(yes)
          else
            @_setContact(no)
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getBattery: -> Promise.resolve @_battery

  class MySensorsSwitch extends env.devices.PowerSwitch

    constructor: (@config,lastState,@board) ->
      @id = @config.id
      @name = @config.name
      @_state = lastState?.state?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsSwitch ", @id, @name, @_state

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_STATUS and result.sensor is @config.sensorid
          state = (if parseInt(result.value) is 1 then on else off)
          if mySensors.config.debug
            env.logger.debug "<- MySensorSwitch ", result
          @_setState(state)
      )

      @rfRequestEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_STATUS
          datas =
          {
            "destination": @config.nodeid,
            "sensor": @config.sensorid,
            "type"  : V_STATUS,
            "value" : @_state,
            "ack"   : 1
          }
          @board._rfWrite(datas)
      )
      @board.on("rfValue", @rfValueEventHandler)
      @board.on("rfRequest", @rfRequestEventHandler)
      super()

    changeStateTo: (state) ->
      assert state is on or state is off
      if state is true then _state = 1  else _state = 0
      datas =
      {
        "destination": @config.nodeid,
        "sensor": @config.sensorid,
        "type"  : V_STATUS,
        "value" : _state,
        "ack"   : 1
      }
      @board._rfWrite(datas).then ( () =>
         @_setState(state)
      )

    destroy: ->
      @board.removeListener "rfValue", @rfValueEventHandler
      @board.removeListener "rfRequest", @rfRequestEventHandler
      super()

  class MySensorsDimmer extends env.devices.DimmerActuator
    _lastdimlevel: null

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or off

      @rfRequestEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_PERCENTAGE
          datas =
          {
            "destination": @config.nodeid,
            "sensor": @config.sensorid,
            "type"  : V_PERCENTAGE,
            "value" : @_dimlevel,
            "ack"   : 1
          }
          @board._rfWrite(datas)
      )

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.type is V_PERCENTAGE and result.sensor is @config.sensorid
          state = (if parseInt(result.value) is 0 then off else on)
          dimlevel = (result.value)
          if mySensors.config.debug
            env.logger.debug "<- MySensorDimmer ", result
          @_setState(state)
          @_setDimlevel(dimlevel)
      )
      @board.on("rfRequest", @rfRequestEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    turnOn: -> @changeDimlevelTo(@_lastdimlevel)

    changeDimlevelTo: (level) ->
      unless @config.forceSend
        if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = false
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      datas =
      {
        "destination": @config.nodeid,
        "sensor": @config.sensorid,
        "type"  : V_PERCENTAGE,
        "value" : level,
        "ack"   : 1
      }
      @board._rfWrite(datas).then ( () =>
        if level in [0-100]
         @_setDimlevel(level)
      )

    destroy: ->
      @board.removeListener "rfRequest", @rfRequestEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

  class MySensorsLight extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @_light = lastState?.light?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsLight ", @id, @name
      @attributes = {}

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @attributes.light = {
        description: "the measured light"
        type: "number"
        unit: '%'
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsLight", result
          if result.type is V_LIGHT_LEVEL
            @_light = parseInt(result.value)
            @emit "light", @_light
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getLight: -> Promise.resolve @_light
    getBattery: -> Promise.resolve @_battery

  class MySensorsLux extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @_lux = lastState?.lux?.value
      @_battery = lastState?.battery?.value
      #env.logger.debug "MySensorsLux ", @id, @name
      @attributes = {}


      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )


      @attributes.lux = {
        description: "the measured light in lux"
        type: "number"
        unit: 'lux'
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsLux", result
          if result.type is V_LIGHT_LEVEL or V_LEVEL
            @_lux = parseInt(result.value)
            @emit "lux", @_lux
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getLux: -> Promise.resolve @_lux
    getBattery: -> Promise.resolve @_battery

  class MySensorsDistance extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_distance = lastState?.distance?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsDistance ", @id, @name
      @attributes = {}

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @attributes.distance = {
        description: "the measured distance"
        type: "number"
        unit: 'cm'
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsDistance", result
          if result.type is V_DISTANCE
            @_distance = parseInt(result.value)
            @emit "distance", @_distance
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getDistance: -> Promise.resolve @_distance
    getBattery: -> Promise.resolve @_battery

  class MySensorsGas extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_gas = lastState?.gas?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsGas ", @id, @name
      @attributes = {}

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @attributes.gas = {
        description: "the measured gas presence in ppm"
        type: "number"
        unit: 'ppm'
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsGas", result
          if result.type is V_LEVEL
            @_gas = parseInt(result.value)
            @emit "gas", @_gas
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getGas: -> Promise.resolve @_gas
    getBattery: -> Promise.resolve @_battery

  class MySensorsShutter extends env.devices.ShutterController

    constructor: (@config,lastState,@board) ->
      @id = @config.id
      @name = @config.name
      @_position = lastState?.position?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsShutter ", @id, @name, @_position

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and
           result.sensor is @config.sensorid and
           (result.type is V_UP or result.type is V_DOWN or result.type is V_STOP)
          position = (if result.type is V_UP then 'up' else if result.type is V_DOWN then 'down' else 'stopped')
          if mySensors.config.debug
            env.logger.debug "<- MySensorsShutter ", result
          @_setPosition(position)
      )
      @board.on("rfValue", @rfValueEventHandler)
      super()

    moveToPosition: (position) ->
      # assert position is up or position is down
      if position is 'up' then _position = V_UP  else _position = V_DOWN
      datas =
      {
        "destination": @config.nodeid,
        "sensor": @config.sensorid,
        "type"  : _position,
        "value" : "",
        "ack"   : 1
      }
      @board._rfWrite(datas).then ( () =>
        @_setPosition(position)
      )

    stop: () ->
      datas =
      {
        "destination": @config.nodeid,
        "sensor": @config.sensorid,
        "type"  : V_STOP,
        "value" : "",
        "ack"   : 1
      }
      @board._rfWrite(datas).then ( () =>
        @_setPosition('stopped')
      )

    destroy: ->
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

  class MySensorsMulti extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @attributeValue = {}
      @attributes = {}
      # loop trough all attributes in the config  and initialise all attributes
      for attr, i in @config.attributes
        do (attr) =>
          name = attr.name
          @attributes[name] = {
            description: name
            unit : attr.unit
            acronym: attr.acronym
            label : attr.label
            displaySparkline: false
          }
          switch attr.type
            when "integer"
              @attributes[name].type = "number"
            when "float"
              @attributes[name].type = "number"
            when "round"
              @attributes[name].type = "number"
            when "boolean"
              @attributes[name].type = "boolean"
              if _.isArray attr.booleanlabels and attr.booleanlabels.length is 2
                @attributes[name].labels = attr.booleanlabels
            when "string"
              @attributes[name].type = "string"
            when "battery"
              @attributes[name].type = "number"
              @attributes[name].unit = "%"
              @attributes[name].icon = {
                  noText: true
                  mapping: {
                    'icon-battery-empty': 0
                    'icon-battery-fuel-1': [0, 20]
                    'icon-battery-fuel-2': [20, 40]
                    'icon-battery-fuel-3': [40, 60]
                    'icon-battery-fuel-4': [60, 80]
                    'icon-battery-fuel-5': [80, 100]
                    'icon-battery-filled': 100
                  }
              }
            else
              throw new Error("Illegal type for attribute #{name}: " + attr.type + " in MySensorsMulti.")

          @attributeValue[name] = lastState?[name]?.value
          @_createGetter name, ( => Promise.resolve @attributeValue[name] )

      # when a mysensors value has been received
      @rfValueEventHandler = ( (result) =>
        # loop trough all attributes in the config
        for attr, i in @config.attributes
          do (attr) =>
            name = attr.name
            # check if the received nodeid and sensorid are the same as the nodeid and sensorid in the config of the attribute
            if result.sender is attr.nodeid and result.sensor is attr.sensorid
              receiveData = false
              # if a sensortype has been provided
              if attr.sensortype?
                # check if the received sensortype is the same as the sensortype in the config of the attribute
                if result.type is attr.sensortype
                  receiveData = true
              else
                receiveData = true

              if (receiveData)
                if mySensors.config.debug
                  env.logger.debug "<- MySensorsMulti", result
                # Adjust the received value according to the type that has been set in the config
                switch attr.type
                  when "integer"
                    value = parseInt(result.value)
                  when "float"
                    value = parseFloat(result.value)
                  when "round"
                    value = Math.round(parseFloat(result.value))
                  when "boolean"
                    if parseInt(result.value) is 0
                      value = false
                    else
                      value = true
                  when "string"
                    value = result.value
                  when "battery"
                    # You should not set a sensorid for a battery sensor
                    throw new Error("A battery doesn't need a sensorid: #{name} in MySensorsMulti.")
                  else
                    throw new Error("Illegal type for attribute #{name}: " + attr.type + " in MySensorsMulti.")

                @_setAttribute name, value
      )

      # when a battery percentage has been received
      @rfbatteryEventHandler = ( (result) =>
        # loop trough all attributes in the config
        for attr, i in @config.attributes
          do (attr) =>
            name = attr.name
            type = attr.type
            # if the attribute has a type of battery and the received nodeid is the same as the nodeid in the config of the attribute
            if result.sender is attr.nodeid and type is "battery"
              unless result.value is null or undefined
                if mySensors.config.debug
                  env.logger.debug "<- MySensorsMulti", result
                # When the battery is too low, battery percentages higher then 100 could be sent
                if result.value > 100
                  result.value = 0
                value =  parseInt(result.value)
                # If the received value is different then the current value, it should be emitted
                @_setAttribute name, value
      )
      @board.on("rfValue", @rfValueEventHandler)
      @board.on("rfbattery", @rfbatteryEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfValue", @rfValueEventHandler
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      super()

    _setAttribute: (attributeName, value) ->
      @attributeValue[attributeName] = value
      @emit attributeName, value

  class MySensorsBattery extends env.devices.Device

    constructor: (@config,lastState, @board,@framework) ->
      @id = @config.id
      @name = @config.name
      if mySensors.config.debug
        env.logger.debug "MySensorsBattery", @id, @name

      @attributes = {}
      @_battery = {}
      for nodes in @config.nodes
        if not nodes.name
          for device in @framework.deviceManager.devicesConfig
            if device?.nodeid and device?.nodeid is nodes.nodeid
              attrname = device?.name
              break
        else
          attrname = nodes.name

        attr = "batteryLevel_" + nodes.nodeid
        @attributes[attr] = {
          description: "the measured Battery Stat of Sensor"
          type: "number"
          displaySparkline: false
          unit: "%"
          acronym: attrname
          icon:
              noText: true
              mapping: {
                'icon-battery-empty': 0
                'icon-battery-fuel-1': [0, 20]
                'icon-battery-fuel-2': [20, 40]
                'icon-battery-fuel-3': [40, 60]
                'icon-battery-fuel-4': [60, 80]
                'icon-battery-fuel-5': [80, 100]
                'icon-battery-filled': 100
              }
        }
        getter = ( =>  Promise.resolve @_battery[nodes.nodeid] )
        @_createGetter( attr, getter)
        @_battery[nodes.nodeid] = lastState?[attr]?.value

      @rfbatteryEventHandler = ( (result) =>
        unless result.value is null or undefined
          # When the battery is to low, battery percentages higher then 100 could be send
          if result.value > 100
            result.value = 0

          @_battery[result.sender] =  parseInt(result.value)
          @emit "batteryLevel_" + result.sender, @_battery[result.sender]
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      super()
  
  class MySensorsIR extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = @config.id
      @name = @config.name

      @_code = lastState?.code?.value
      @_battery = lastState?.battery?.value
      if mySensors.config.debug
        env.logger.debug "MySensorsIR ", @id, @name
      @attributes = {}

      @attributes.battery = {
        description: "Display the battery level of sensor"
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        hidden: !@config.batterySensor
       }

      @rfbatteryEventHandler = ( (result) =>
        if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_battery =  parseInt(result.value)
            @emit "battery", @_battery
      )

      @attributes.code = {
        description: "the received IR code"
        type: "string"
        unit: ''
      }

      @rfValueEventHandler = ( (result) =>
        if result.sender is @config.nodeid and result.sensor is @config.sensorid
          if mySensors.config.debug
            env.logger.debug "<- MySensorsIR", result
          if result.type is V_IR_RECEIVE
            @_code = result.value
            @emit "code", @_code
      )
      @board.on("rfbattery", @rfbatteryEventHandler)
      @board.on("rfValue", @rfValueEventHandler)
      super()

    destroy: ->
      @board.removeListener "rfbattery", @rfbatteryEventHandler
      @board.removeListener "rfValue", @rfValueEventHandler
      super()

    getCode: -> Promise.resolve @_code
    getBattery: -> Promise.resolve @_battery

  class MySensorsActionHandler extends env.actions.ActionHandler

    constructor: (@framework,@board,@nodeid,@sensorid,@cmdcode,@customvalue) ->

    executeAction: (simulate) =>
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@nodeid)
        @framework.variableManager.evaluateStringExpression(@sensorid)
        @framework.variableManager.evaluateStringExpression(@cmdcode)
        @framework.variableManager.evaluateStringExpression(@customvalue)
      ]).then( ([node, sensor, code,customvalue]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would send IR \"%s\"", cmdCode)
        else

          switch customvalue
            when "V_VAR1"
              type_value = V_VAR1
            when "V_VAR2"
              type_value = V_VAR2
            when "V_VAR3"
              type_value = V_VAR3
            when "V_VAR4"
              type_value = V_VAR4
            when "V_VAR5"
              type_value = V_VAR5
            when "V_PERCENTAGE"
              type_value = V_PERCENTAGE
            when "V_STATUS"
              type_value = V_STATUS
            when "V_UP"
              type_value = V_UP
            when "V_DOWN"
              type_value = V_DOWN
            when "V_STOP"
              type_value = V_STOP
            else
              type_value = V_IR_SEND

          datas =
          {
            "destination": node,
            "sensor": sensor,
            "type"  : type_value,
            "value" : code,
            "ack"   : 1
          }
          return @board._rfWrite(datas).then ( () =>
            __("IR message sent successfully")
          )
          )

  class MySensorsActionProvider extends env.actions.ActionProvider

    constructor: (@framework,@board) ->

    parseAction: (input, context) =>

      cmdcode = "0x00000"
      nodeid = "0"
      sensorid = "0"
      fullMatch = no
      CustomValue = "V_IR_SEND"

      setTypeValue = (m, tokens) => CustomValue = tokens
      setCmdcode = (m, tokens) => cmdcode = tokens
      setSensorid = (m, tokens) => sensorid = tokens
      setNodeid = (m, tokens) => nodeid = tokens

      onEnd = => fullMatch = yes

      m = M(input, context)
        .match('send ')
        .match('custom ').matchStringWithVars(setTypeValue)

      next = m.match(' nodeid: ').matchStringWithVars(setNodeid)
      if next.hadMatch() then m = next

      next = m.match(' sensorid: ').matchStringWithVars(setSensorid)
      if next.hadMatch() then m = next

      next = m.match(' cmdcode: ').matchStringWithVars(setCmdcode)
      if next.hadMatch() then m = next

      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new MySensorsActionHandler(@framework,@board,nodeid,sensorid,cmdcode,CustomValue)
        }
      else
        return null

  # ###Finally
  # Create a instance of my plugin
  mySensors = new MySensors
  # and return it to the framework.
  return mySensors
