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

      @framework.ruleManager.addActionProvider(new MySensorsActionProvider @framework, config) 
      
      deviceClasses = [
        MySensorsDHT
        MySensorsBMP
        MySensorsPIR
        MySensorsSwitch
        MySensorsDimmer
        MySensorsPulseMeter
        MySensorsButton
        MySensorsLight
        MySensorsGas
        MySensorsBattery
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) => 
             device  =  new Cl(config,lastState, @board)
             return device
            })
      #env.logger.info @framework.deviceManager.devicesConfig.length
       
  class MySensorsDHT extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name 
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

  class MySensorsBMP extends env.devices.TemperatureSensor

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
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
      @_pulsecount = lastState?.pulsecount?.value
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
          for sensorid in @config.sensorid
            if result.sensor is sensorid
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
        if result.sender is @config.nodeid and result.type is ( V_TRIPPED or V_LIGHT ) and result.sensor is @config.sensorid
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
        if result.sender is @config.nodeid and result.type is V_LIGHT and result.sensor is @config.sensorid 
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
        "type"  : V_LIGHT,
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
        if result.sender is @config.nodeid and result.type is V_DIMMER and result.sensor is @config.sensorid 
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
        "type"  : V_DIMMER,
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


    
  class MySensorsGas extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
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


   
  class MySensorsBattery extends env.devices.Device

    constructor: (@config,lastState, @board) ->
      @id = config.id
      @name = config.name
      env.logger.info "MySensorsBattery" , @id , @name

      @attributes = {}
      @_batterystat = {}
      for nodeid in @config.nodeid
        do (nodeid) =>
          attr = "battery_" + nodeid
          @attributes[attr] = {
            description: "the measured Battery Stat of Sensor"
            type: "number"
            unit: '%'
          }
          getter = ( =>  Promise.resolve @_batterystat[nodeid] )
          @_createGetter( attr, getter)
          @_batterystat[nodeid] = lastState?[attr]?.value

      @board.on("rfbattery", (result) =>
        unless result.value is null or undefined
          @_batterystat[result.sender] =  parseInt(result.value)
          @emit "battery_" + result.sender, @_batterystat[result.sender]
      )
      super()


 

 # PushBullet = require('pushbullet');
 # Promise.promisifyAll(PushBullet.prototype)
  
  pusherService = null

  # class PushbulletPlugin extends env.plugins.Plugin

  #   init: (app, @framework, config) =>
      apikey = config.apikey
      env.logger.debug "apikey= #{apikey}"
      pusherService = new PushBullet(apikey)
      
      @framework.ruleManager.addActionProvider(new MySensorsActionProvider @framework, config)


  
  class MySensorsActionProvider extends env.actions.ActionProvider

    constructor: (@framework) -> 
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    parseAction: (input, context) =>
      retVal = null
      commandTokens = null
      fullMatch = no

      setCommand = (m, tokens) => commandTokens = tokens
      onEnd = => fullMatch = yes
      
      m = M(input, context)
        .match("SendIR ")
        .matchStringWithVars(setCommand)
      
      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new MysensorsActionHandler(@framework, commandTokens)
        }
      else
        return null

  class MySensorsActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @commandTokens) ->
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    executeAction: (simulate) =>
      @framework.variableManager.evaluateStringExpression(@commandTokens).then( (command) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would execute \"%s\"", command)
        else

      datas = {}      
      datas = 
      { 
        "destination": @config.nodeid, 
        "sensor": @config.sensorid, 
        "type"  : V_LIGHT,
        "value" : command,
        "ack"   : 1
      } 
      @board._rfWrite(datas).then ( () =>
         @_setState(state)
      )
          # return exec(command).then( (streams) =>
          #   stdout = streams[0]
          #   stderr = streams[1]
          #   env.logger.error stderr if stderr.length isnt 0
          #   return __("executed \"%s\": %s", command, stdout.trim())
          )
      )

  # ###Finally
  # Create a instance of my plugin
  mySensors = new MySensors
  # and return it to the framework.
  return mySensors
