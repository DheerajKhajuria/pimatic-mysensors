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
      description: "The diver to connect to the PiGateway"
      type: "string"
      enum: ["serialport"]
      default: "serialport"
    driverOptions:
      description: "Options for the driver"
      type: "object"
      default: {
        "serialDevice": '/dev/ttyUSB0', #"/dev/ttyUSB0",
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
