Promise = require 'bluebird'
assert = require 'assert'
events = require 'events'

settled = (promise) -> Promise.settle([promise])


FIRMWARE_BLOCK_SIZE = 16
BROADCAST_ADDRESS   = 255
NODE_SENSOR_ID      = 255

C_PRESENTATION     = 0
C_SET              = 1
C_REQ              = 2
C_INTERNAL         = 3
C_STREAM           = 4

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

  # @HIGH=1
  # @LOW=0
  # @INPUT=0
  # @OUTPUT=1
  # @INPUT_PULLUP=2

  # _awaitingAck: []
  # _opened: no
  # ready: no

  constructor: (config) ->
    @config = config
    assert @config.driver in ["serialport", "gpio"]
    # setup a new driver
    switch @config.driver
      when "serialport"
        SerialPortDriver = require './serialport'
        @driver = new SerialPortDriver(@config.driverOptions)
    #@_lastAction = Promise.resolve()
    #@driver.on('ready', => 
    #  @ready = yes
    #  @emit('ready') 
    #)
    @driver.on('error', (error) => @emit('error', error) )
    @driver.on('reconnect', (error) => @emit('reconnect', error) )
    @driver.on('close', => 
      #@ready = no
      @emit('close')
    )
    @driver.on("data", (data) =>
      @emit "data", data
    )
    @driver.on("line", (line) =>
      @emit "line", line
      @_rfReceived(line)
    )
    #@on('ready', => @setupWatchdog())

  connect: (timeout = 20000, retries = 3) -> 
    # Stop watchdog if its running and close current connection
    return @pendingConnect = @driver.connect(timeout, retries)

  disconnect: ->
    #@stopWatchdog()
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
        console.log  "Presented Node : ", datas
      when C_SET
        result = {}            
        result = {
          "sender": sender,
          "sensor": sensor,
          "type"  : type,
          "value" : parseInt(rawpayload)
        } 
        @emit "rfValue", result

module.exports = Board