# #my-plugin configuration options
# Declare your config option for your plugin here. 
# # configuration options
module.exports = {
  title: "MySensors config"
  type: "object"
  properties:
    debug:
      description: "Log information for debugging, including received messages"
      type: "boolean"
      default: true
    driver:
      description: "The driver to connect to the gateway"
      type: "string"
      enum: ["serialport", "ethernet"]
      default: "serialport"
      defines:
        property: "driverOptions"
        options:
          serialport:
            title: "serialport driver options"
            type: "object"
            properties:
              serialDevice:
                description: "The name of the serial device to use"
                type: "string"
                default: "/dev/ttyUSB0"
              baudrate:
                description: "The baudrate to use for serial communication"
                type: "integer"
                default: 115200
          ethernet:
            title: "ethernet driver options"
            type: "object"
            properties:
              host:
                description: "The IP address of the gateway"
                type: "string"
                default: "192.168.1.100"
              port:
                description: "The port of the gateway"
                type: "integer"
                default: 5003
    driverOptions:
      description: "Options for the driver"
      type: "object"
      default: {
        "serialDevice": "/dev/ttyUSB0",
        "baudrate": 115200
      }
    protocols: 
      description: "MySensors protrocol version"
      type: "string"
      default: "1.5.1"
    metric: 
      description: "(M)etric or (I)mperal"
      type: "string"
      default: "M"
    startingNodeId:
      description: "Mysensors starting node id"
      type: "number"
      default: 1 
    time:
      description: "use 'local' or 'utc' time"
      type: "string"
      default: "local"  
}
