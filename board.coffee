Promise = require 'bluebird'
assert = require 'assert'
events = require 'events'


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
        console.log "<- Presented Node ", datas
      when C_SET
        @_rfsendtoboard(sender,sensor,type,rawpayload)
      when C_REQ
        console.log "<- request from  ", sender, rawpayload
        @_rfrequest(sender,sensor,type)
      when C_INTERNAL
        switch type 
          when I_BATTERY_LEVEL
            console.log "<- I_BATTERY_LEVEL ", sender, rawpayload
            @_rfsendbatterystat(sender,rawpayload)
          when I_TIME
            console.log "<- I_TIME ", data 
            @_rfsendTime(sender, sensor)
          when I_VERSION
            console.log "<- I_VERSION ", payload
          when I_ID_REQUEST
            console.log "<- I_ID_REQUEST ", data
            @_rfsendNextAvailableSensorId
          when I_ID_RESPONSE
            console.log "<- I_ID_RESPONSE ", data
          when I_INCLUSION_MODE
            console.log "<- I_INCLUSION_MODE ", data
          when I_CONFIG
            console.log "<- I_CONFIG ", data
            @_rfsendConfig(sender)
          when I_PING
            console.log "<- I_PING ", data
          when I_PING_ACK
            console.log "<- I_PING_ACK ", data
          when I_LOG_MESSAGE
            console.log "<- I_LOG_MESSAGE ", data
          when I_CHILDREN
            console.log "<- I_CHILDREN ", data
          when I_SKETCH_NAME
            #saveSketchName(sender, payload, db);
            console.log "<- I_SKETCH_NAME ", data
          when I_SKETCH_VERSION
            #saveSketchVersion(sender, payload, db);
            console.log "<- I_SKETCH_VERSION ", data
      

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
      console.log "-> Error assigning Next ID, already reached maximum ID"
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
    console.log "-> Sending ", data
    @driver.write(data) 

  _rfencode: (destination, sensor, command, acknowledge, type, payload) ->
    msg = destination.toString(10) + ";" + sensor.toString(10) + ";" + command.toString(10) + ";" + acknowledge.toString(10) + ";" + type.toString(10) + ";";
    msg += payload
    msg += '\n'
    return msg.toString();  

module.exports = Board
