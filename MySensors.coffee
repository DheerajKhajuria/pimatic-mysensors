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
  S_AIR_QUALITY        = 22

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


  class Board extends events.EventEmitter

    constructor: (framework,config) ->
      @config = config
      @framework = framework
      assert @config.driver in ["serialport", "gpio"]
      # setup a new driver
      switch @config.driver
        when "serialport"
          SerialPortDriver = require './serialport'
          @driver = new SerialPortDriver(@config.driverOptions)

      @driver.on('error', (error) => @emit('error', error) )
      @driver.on('reconnect', (error) => @emit('reconnect', error) )
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


    connect: (timeout = 20000, retries = 3) ->

      return @pendingConnect = @driver.connect(timeout, retries)

    disconnect: ->

      return @driver.disconnect()

    _rfReceived: (data) ->
      # decoding message
      datas = {};
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
          env.logger.debug "<- Presented Node ", datas
        when C_SET
          @_rfsendtoboard(sender,sensor,type,rawpayload)
        when C_REQ
          env.logger.debug "<- request from  ", sender, rawpayload
          @_rfrequest(sender,sensor,type)
        when C_INTERNAL
          switch type
            when I_BATTERY_LEVEL
              env.logger.debug "<- I_BATTERY_LEVEL ", sender, rawpayload
              @_rfsendbatterystat(sender,rawpayload)
            when I_TIME
              env.logger.debug "<- I_TIME ", data
              @_rfsendTime(sender, sensor)
            when I_VERSION
              env.logger.debug "<- I_VERSION ", payload
            when I_ID_REQUEST
              env.logger.debug "<- I_ID_REQUEST ", data
              @_rfsendNextAvailableSensorId()
            when I_ID_RESPONSE
              env.logger.debug "<- I_ID_RESPONSE ", data
            when I_INCLUSION_MODE
              env.logger.debug "<- I_INCLUSION_MODE ", data
            when I_CONFIG
              env.logger.debug "<- I_CONFIG ", data
              @_rfsendConfig(sender)
            when I_PING
              env.logger.debug "<- I_PING ", data
            when I_PING_ACK
              env.logger.debug "<- I_PING_ACK ", data
            when I_LOG_MESSAGE
              env.logger.debug "<- I_LOG_MESSAGE ", data
            when I_CHILDREN
              env.logger.debug "<- I_CHILDREN ", data
            when I_SKETCH_NAME
              #saveSketchName(sender, payload, db);
              env.logger.debug "<- I_SKETCH_NAME ", data
            when I_SKETCH_VERSION
              #saveSketchVersion(sender, payload, db);
              env.logger.debug "<- I_SKETCH_VERSION ", data


    _rfsendTime: (destination,sensor) ->
       payload = Math.floor((new Date().getTime())/1000)
       datas = {}
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
       datas = {}
       nextnodeid = @config.startingNodeId
       if nextnodeid > 255
        env.logger.debug "-> Error assigning Next ID, already reached maximum ID"
        return
       if nextnodeid is null
          nextnodeid = 1
       else
          nextnodeid +=1
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

    _rfrequest: (sender,sensor,type) ->
      result = {}
      result = {
        "sender": sender,
        "sensor": sensor,
        "type": type
      }
      @emit "rfRequest", result

    _rfsendtoboard: (sender,sensor,type,rawpayload) ->
        result = {}
        result = {
            "sender": sender,
            "sensor": sensor,
            "type"  : type,
            "value" : rawpayload
        }
        @emit "rfValue", result

    _rfsendbatterystat: (sender,rawpayload) ->
        result = {}
        result = {
            "sender": sender,
            "value" : rawpayload
        }
        @emit "rfbattery", result

    _rfsendConfig: (destination) ->
        datas = {}
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

      @framework.ruleManager.addActionProvider(new MySensorsActionProvider @framework,@board, config)

      deviceClasses = [
        MySensorsDHT
        MySensorsDST
        MySensorsBMP
        MySensorsPIR
        MySensorsSwitch
        MySensorsDimmer
        MySensorsPulseMeter
        MySensorsButton
        MySensorsLight
        MySensorsLux
        MySensorsDistance
        MySensorsGas
        MySensorsMulti
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
      @id = config.id
      @name = config.name
      @_temperatue = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.info "MySensorsDHT " , @id , @name

      @attributes = {}

      @attributes.temperature = {
        description: "the messured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.humidity = {
        description: "the messured humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      }

      @attributes.battery = {
        description: "Display the battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              env.logger.debug "<- MySensorDHT " , result
              if result.type is V_TEMP
                #env.logger.debug  "temp" , result.value
                @_temperatue = parseFloat(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_HUM
                #env.logger.debug  "humidity" , result.value
                @_humidity = Math.round(parseFloat(result.value))
                @emit "humidity", @_humidity
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsDST extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_temperatue = lastState?.temperature?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.debug "MySensorsDST " , @id , @name

      @attributes = {}

      @attributes.temperature = {
        description: "the messured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.battery = {
        description: "Display the battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid and result.type is V_TEMP and result.sensor is @config.sensorid
          env.logger.debug "<- MySensorDST " , result
          @_temperatue = parseFloat(result.value)
          @emit "temperature", @_temperatue
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsBMP extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_temperatue = lastState?.temperature?.value
      @_pressure = lastState?.pressure?.value
      @_forecast = lastState?.forecast?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.debug "MySensorsBMP " , @id , @name

      @attributes = {}

      @attributes.temperature = {
        description: "the messured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.pressure = {
          description: "the messured pressure"
          type: "number"
          unit: 'hPa'
          acronym: 'mbar'
      }

      @attributes.forecast = {
          description: "the forecast"
          type: "string"
      }

      @attributes.battery = {
        description: "Display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }


      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              env.logger.debug "<- MySensorBMP " , result
              if result.type is V_TEMP
                #env.logger.debug  "temp" , result.value
                @_temperatue = parseInt(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_PRESSURE
                #env.logger.debug  "pressure" , result.value
                @_pressure = parseInt(result.value)
                @emit "pressure", @_pressure
              if result.type is V_FORECAST
                #env.logger.debug  "forecast" , result.value
                @_forecast = result.value
                @emit "forecast", @_forecast

      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getPressure: -> Promise.resolve @_pressure
    getForecast: -> Promise.resolve @_forecast
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsPulseMeter extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @voltage = config.appliedVoltage

      @_watt = lastState?.watt?.value
      @_ampere = lastState?.ampere?.value
      @_kwh = lastState?.kWh?.value
      @_pulsecount = lastState?.pulsecount?.value
      @_batterystat = lastState?.batterystat?.value

      env.logger.debug "MySensorsPulseMeter " , @id , @name

      @attributes = {}

      @attributes.watt = {
        description: "the messured Wattage"
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
        description: "the messured kWh"
        type: "number"
        unit: 'kWh'
        acronym: 'kWh'
      }

      calculatekwh = ( =>
        @_avgkw =  @_totalkw / @_tickcount
        @_kwh = (@_avgkw * (@_tickcount * 10)) / 3600
        @_tickcount = 0
        @_totalkw  = 0
        env.logger.debug  "calculatekwh.." , @kwh
        @emit "kWh", @_kwh
      )


      @attributes.battery = {
        description: "Display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @attributes.ampere = {
        description: "the messured Ampere"
        type: "number",
        unit: "A"
        acronym: 'Ampere'
       }

      @board.on("rfRequest", (result) =>
        if result.sender is @config.nodeid
          datas = {}
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

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is @config.sensorid
            env.logger.debug "<- MySensorsPulseMeter" , result
            if result.type is V_VAR1
              env.logger.debug "<- MySensorsPulseMeter V_VAR1"
              @_pulsecount = parseInt(result.value)
              @emit "pulsecount", @_pulsecount
            if result.type is V_WATT
              env.logger.debug "<- MySensorsPulseMeter V_WATT"
              @_watt = parseInt(result.value)
              @emit "watt", @_watt
              @_ampere = @_watt / @voltage
              @emit "ampere", @_ampere
            if result.type is V_KWH
              env.logger.debug "<- MySensorsPulseMeter V_KWH"
              @_kwh = parseFloat(result.value)
              @emit "kWh", @_kwh

      )
      super()

    getWatt: -> Promise.resolve @_watt
    getPulsecount: -> Promise.resolve @_pulsecount
    getKWh: -> Promise.resolve @_kwh
    getBattery: -> Promise.resolve @_batterystat
    getAmpere: -> Promise.resolve @_ampere

  class MySensorsPIR extends env.devices.PresenceSensor

    constructor: (@config,lastState,@board) ->
      @id = config.id
      @name = config.name
      @_presence = lastState?.presence?.value or false
      env.logger.debug "MySensorsPIR " , @id , @name, @_presence

      resetPresence = ( =>
        @_setPresence(no)
      )

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is V_TRIPPED and result.sensor is @config.sensorid
          env.logger.debug "<- MySensorPIR ", result
          if result.value is ZERO_VALUE
            @_setPresence(no)
          else
            @_setPresence(yes)
          if @config.autoReset is true
            clearTimeout(@_resetPresenceTimeout)
            @_resetPresenceTimeout = setTimeout(( =>
              @_setPresence(no)
            ), @config.resetTime)
      )

      super()

    getPresence: -> Promise.resolve @_presence

  class MySensorsButton extends env.devices.ContactSensor

    constructor: (@config,lastState,@board) ->
      @id = config.id
      @name = config.name
      @_contact = lastState?.contact?.value or false
      env.logger.debug "MySensorsButton" , @id , @name, @_contact

      @attributes = _.cloneDeep @attributes

      @attributes.battery = {
        description: "Display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is ( V_TRIPPED or V_STATUS ) and result.sensor is @config.sensorid
          env.logger.debug "<- MySensorsButton ", result
          if result.value is ZERO_VALUE
            @_setContact(yes)
          else
            @_setContact(no)
      )
      super()

    getBattery: -> Promise.resolve @_batterystat

  class MySensorsSwitch extends env.devices.PowerSwitch

    constructor: (@config,lastState,@board) ->
      @id = config.id
      @name = config.name
      @_state = lastState?.state?.value
      env.logger.debug "MySensorsSwitch " , @id , @name, @_state

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is V_STATUS and result.sensor is @config.sensorid
          state = (if parseInt(result.value) is 1 then on else off)
          env.logger.debug "<- MySensorSwitch " , result
          @_setState(state)
        )
      super()

    changeStateTo: (state) ->
      assert state is on or state is off
      if state is true then _state = 1  else _state = 0
      datas = {}
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

  class MySensorsDimmer extends env.devices.DimmerActuator
    _lastdimlevel: null

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or off

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is V_PERCENTAGE and result.sensor is @config.sensorid
          state = (if parseInt(result.value) is 0 then off else on)
          dimlevel = (result.value)
          env.logger.debug "<- MySensorDimmer " , result
          @_setState(state)
          @_setDimlevel(dimlevel)
        )
      super()

    turnOn: -> @changeDimlevelTo(@_lastdimlevel)

    changeDimlevelTo: (level) ->
      unless @config.forceSend
        if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = false
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      datas = {}
      datas =
      {
        "destination": @config.nodeid,
        "sensor": @config.sensorid,
        "type"  : V_PERCENTAGE,
        "value" : level,
        "ack"   : 1
      }
      @board._rfWrite(datas).then ( () =>
         @_setDimlevel(level)
      )

  class MySensorsLight extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name

      @_light = lastState?.light?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.debug "MySensorsLight " , @id , @name
      @attributes = {}

      @attributes.battery = {
        description: "display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @attributes.light = {
        description: "the messured light"
        type: "number"
        unit: '%'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.debug "<- MySensorsLight" , result
            if result.type is V_LIGHT_LEVEL
              @_light = parseInt(result.value)
              @emit "light", @_light
      )
      super()

    getLight: -> Promise.resolve @_light
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsLux extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name

      @_lux = lastState?.lux?.value
      @_batterystat = lastState?.batterystat?.value
      #env.logger.debug "MySensorsLux " , @id , @name
      @attributes = {}


      @attributes.battery = {
        description: "display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )


      @attributes.lux = {
        description: "the messured light in lux"
        type: "number"
        unit: 'lux'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.debug "<- MySensorsLux" , result
            if result.type is V_LIGHT_LEVEL or V_LEVEL
              @_lux = parseInt(result.value)
              @emit "lux", @_lux
      )
      super()

    getLux: -> Promise.resolve @_lux
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsDistance extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_distance= lastState?.distance?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.debug "MySensorsDistance " , @id , @name
      @attributes = {}

      @attributes.battery = {
        description: "display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @attributes.distance = {
        description: "the messured distance"
        type: "number"
        unit: 'cm'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.debug "<- MySensorsDistance" , result
            if result.type is V_DISTANCE
              @_distance = parseInt(result.value)
              @emit "distance", @_distance
      )
      super()

    getDistance: -> Promise.resolve @_distance
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsGas extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_gas = lastState?.gas?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.debug "MySensorsGas " , @id , @name
      @attributes = {}

      @attributes.battery = {
        description: "display the Battery level of Sensor"
        type: "number"
        unit: '%'
        acronym: 'BATT'
        hidden: !@config.batterySensor
       }

      @board.on("rfbattery", (result) =>
         if result.sender is @config.nodeid
          unless result.value is null or undefined
            # When the battery is to low, battery percentages higher then 100 could be send
            if result.value > 100
              result.value = 0

            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @attributes.gas = {
        description: "the messured gas presence in ppm"
        type: "number"
        unit: 'ppm'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.debug "<- MySensorsGas" , result
            if result.type is V_VAR1
              @_gas = parseInt(result.value)
              @emit "gas", @_gas
      )
      super()

    getGas: -> Promise.resolve @_gas
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsMulti extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name

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
              if _.isArray attr.booleanlabels
                @attributes[name].labels = attr.booleanlabels
            when "string"
              @attributes[name].type = "string"
            when "battery"
              @attributes[name].type = "number"
            else
              throw new Error("Illegal unit for attribute type: #{name} in MySensorsMulti.")

          @attributeValue[name] = lastState?[name]?.value
          @_createGetter name, ( => Promise.resolve @attributeValue[name] )

      # when a mysensors value has been received
      @board.on("rfValue", (result) =>
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
                env.logger.debug "<- MySensorsMulti" , result
                # Adjust the received value according to the type that has been set in the config
                switch attr.type
                  when "integer"
                    value = parseInt(result.value)
                  when "float"
                    value = parseFloat(result.value)
                  when "round"
                    value = Math.round(parseFloat(result.value))
                  when "boolean"
                    if result.value is "0"
                      value = false
                    else
                      value = true
                  when "string"
                    value = result.value
                  when "battery"
                    # You should not set a sensorid for a battery sensor
                    throw new Error("A battery doesn't need a sensorid: #{name} in MySensorsMulti.")
                  else
                    throw new Error("Illegal unit for attribute type: #{name} in MySensorsMulti.")

                # If the received value is different then the current value, it should be emitted
                @_setAttribute name, value
      )

      # when a battery percentage has been received
      @board.on("rfbattery", (result) =>
        # loop trough all attributes in the config
        for attr, i in @config.attributes
          do (attr) =>
            name = attr.name
            type = attr.type
            # if the attribute has a type of battery and the received nodeid is the same as the nodeid in the config of the attribute
            if result.sender is attr.nodeid and type is "battery"
              unless result.value is null or undefined
                env.logger.debug "<- MySensorsMulti" , result
                # When the battery is to low, battery percentages higher then 100 could be send
                if result.value > 100
                  result.value = 0
                value =  parseInt(result.value)
                # If the received value is different then the current value, it should be emitted
                @_setAttribute name, value
      )
      super()

    _setAttribute: (attributeName, value) ->
      unless @attributeValue[attributeName] is value
        @attributeValue[attributeName] = value
        @emit attributeName, value

  class MySensorsBattery extends env.devices.Device

    constructor: (@config,lastState, @board,@framework) ->
      @id = config.id
      @name = config.name
      env.logger.debug "MySensorsBattery" , @id , @name

      @attributes = {}
      @_batterystat = {}
      for nodeid in @config.nodeid
        do (nodeid) =>
          for device in  @framework.deviceManager.devicesConfig
            if device?.nodeid and device?.nodeid is nodeid
              attrname = device?.name
              break

          attr = "batteryLevel_" + nodeid
          @attributes[attr] = {
            description: "the measured Battery Stat of Sensor"
            type: "number"
            unit: '%'
            acronym:  attrname
          }
          getter = ( =>  Promise.resolve @_batterystat[nodeid] )
          @_createGetter( attr, getter)
          @_batterystat[nodeid] = lastState?[attr]?.value

      @board.on("rfbattery", (result) =>
        unless result.value is null or undefined
          # When the battery is to low, battery percentages higher then 100 could be send
          if result.value > 100
            result.value = 0

          @_batterystat[result.sender] =  parseInt(result.value)
          @emit "batteryLevel_" + result.sender, @_batterystat[result.sender]
      )
      super()

  class MySensorsActionHandler extends env.actions.ActionHandler

    constructor: (@framework,@board,@nodeid,@sensorid,@cmdcode,@customvalue) ->

    executeAction: (simulate) =>
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@nodeid)
        @framework.variableManager.evaluateStringExpression(@sensorid)
        @framework.variableManager.evaluateStringExpression(@cmdcode)
        @framework.variableManager.evaluateStringExpression(@customvalue)
      ]).then( ([node, sensor, code ,customvalue]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would send IR \"%s\"", cmdCode)
        else
          datas = {}

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
			when "V_DIMMER"
              type_value = V_DIMMER
            when "V_LIGHT"
              type_value = V_LIGHT
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
