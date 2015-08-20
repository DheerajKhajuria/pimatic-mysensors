module.exports = (env) ->

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

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  Board = require('./board')
  M = env.matcher

  Promise.promisifyAll(Board.prototype)

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
        MySensorsDistance
        MySensorsGas
        MySensorsLevel
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
            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              env.logger.info "<- MySensorDHT " , result
              if result.type is V_TEMP
                #env.logger.info  "temp" , result.value
                @_temperatue = parseFloat(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_HUM
                #env.logger.info  "humidity" , result.value
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
      env.logger.info "MySensorsBMP " , @id , @name

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
            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          for sensorid in @config.sensorid
            if result.sensor is sensorid
              env.logger.info "<- MySensorBMP " , result
              if result.type is V_TEMP
                #env.logger.info  "temp" , result.value
                @_temperatue = parseInt(result.value)
                @emit "temperature", @_temperatue
              if result.type is V_PRESSURE
                #env.logger.info  "pressure" , result.value
                @_pressure = parseInt(result.value)
                @emit "pressure", @_pressure
              if result.type is V_FORECAST
                #env.logger.info  "forecast" , result.value
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

      env.logger.info "MySensorsPulseMeter " , @id , @name

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
        env.logger.info  "calculatekwh.." , @kwh
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
            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is @config.sensorid
            env.logger.info "<- MySensorsPulseMeter" , result
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
      env.logger.info "MySensorsPIR " , @id , @name, @_presence

      resetPresence = ( =>
        @_setPresence(no)
      )

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is V_TRIPPED and result.sensor is @config.sensorid
          env.logger.info "<- MySensorPIR ", result
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
      env.logger.info "MySensorsButton" , @id , @name, @_contact

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
            @_batterystat =  parseInt(result.value)
            @emit "battery" , @_batterystat
      )

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is ( V_TRIPPED or V_STATUS ) and result.sensor is @config.sensorid
          env.logger.info "<- MySensorsButton ", result
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
      env.logger.info "MySensorsSwitch " , @id , @name, @_state

      @board.on('rfValue', (result) =>
        if result.sender is @config.nodeid and result.type is V_STATUS and result.sensor is @config.sensorid
          state = (if parseInt(result.value) is 1 then on else off)
          env.logger.info "<- MySensorSwitch " , result
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
          env.logger.info "<- MySensorDimmer " , result
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
      env.logger.info "MySensorsLight " , @id , @name
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


      @attributes.light = {
        description: "the messured light"
        type: "number"
        unit: '%'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.info "<- MySensorsLight" , result
            if result.type is V_LIGHT_LEVEL
              @_light = parseInt(result.value)
              @emit "light", @_light
      )
      super()

    getLight: -> Promise.resolve @_light
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsDistance extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_distance= lastState?.distance?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.info "MySensorsDistance " , @id , @name
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


      @attributes.distance = {
        description: "the messured distance"
        type: "number"
        unit: 'cm'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.info "<- MySensorsDistance" , result
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
      env.logger.info "MySensorsGas " , @id , @name
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

      @attributes.gas = {
        description: "the messured gas presence in ppm"
        type: "number"
        unit: 'ppm'
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.info "<- MySensorsGas" , result
            if result.type is V_VAR1
              @_gas = parseInt(result.value)
              @emit "gas", @_gas
      )
      super()

    getGas: -> Promise.resolve @_gas
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsLevel extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      @_level = lastState?.level?.value
      @_batterystat = lastState?.batterystat?.value
      env.logger.info "MySensorsLevel " , @id , @name
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

      @attributes.level = {
        description: "the level of moisture, dust, air quality, sound, vibration or light"
        type: "number"
        unit: @config.unit
        acronym:  @config.acronym
      }

      @board.on("rfValue", (result) =>
        if result.sender is @config.nodeid
          if result.sensor is  @config.sensorid
            env.logger.info "<- MySensorsLevel" , result
            if result.type is V_LEVEL
              @_level = parseInt(result.value)
              @emit "level", @_level
      )
      super()

    getLevel: -> Promise.resolve @_level
    getBattery: -> Promise.resolve @_batterystat

  class MySensorsMulti extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name

      @attributeValue = {}
      @attributes = {}
      # initialise all attributes
      for attr, i in @config.attributes
        do (attr) =>
          name = attr.name
          @attributes[name] = {
            description: name
            unit : attr.unit
            acronym: attr.acronym
            type: attr.valuetype
          }
          @attributeValue[name] = lastState?[name]?.value
          @_createGetter name, ( => Promise.resolve @attributeValue[name] )

      @board.on("rfValue", (result) =>
        for attr, i in @config.attributes
          do (attr) =>
            name = attr.name
            if result.sender is attr.nodeid
              if result.sensor is  attr.sensorid
                env.logger.info "<- MySensorsMulti" , result

                if result.type is attr.sensortype
                  value = parseFloat(result.value)
                  @attributeValue[name] = value
                  @emit name, value

      )
      super()

    _setAttribute: (attributeName, value) ->
      unless @[attributeName] is value
        @[attributeName] = value
        @emit attributeName, value


  class MySensorsBattery extends env.devices.Device

    constructor: (@config,lastState, @board,@framework) ->
      @id = config.id
      @name = config.name
      env.logger.info "MySensorsBattery" , @id , @name

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
          @_batterystat[result.sender] =  parseInt(result.value)
          @emit "batteryLevel_" + result.sender, @_batterystat[result.sender]
      )
      super()

  class MySensorsActionHandler extends env.actions.ActionHandler

    constructor: (@framework,@board,@nodeid,@sensorid,@cmdcode) ->

    executeAction: (simulate) =>
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@nodeid)
        @framework.variableManager.evaluateStringExpression(@sensorid)
        @framework.variableManager.evaluateStringExpression(@cmdcode)
      ]).then( ([node, sensor, Code]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would send IR \"%s\"", cmdCode)
        else
          datas = {}
          datas =
          {
            "destination": node,
            "sensor": sensor,
            "type"  : V_IR_SEND,
            "value" : Code,
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

      setCmdcode = (m, tokens) => cmdcode = tokens
      setSensorid = (m, tokens) => sensorid = tokens
      setNodeid = (m, tokens) => nodeid = tokens

      onEnd = => fullMatch = yes

      m = M(input, context)
        .match('send ', optional: yes)
        .match('Ir')

      next = m.match(' nodeid:').matchStringWithVars(setNodeid)
      if next.hadMatch() then m = next

      next = m.match(' sensorid:').matchStringWithVars(setSensorid)
      if next.hadMatch() then m = next

      next = m.match(' cmdcode:').matchStringWithVars(setCmdcode)
      if next.hadMatch() then m = next

      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new MySensorsActionHandler(@framework,@board,nodeid,sensorid,cmdcode)
        }
      else
        return null

  # ###Finally
  # Create a instance of my plugin
  mySensors = new MySensors
  # and return it to the framework.
  return mySensors
