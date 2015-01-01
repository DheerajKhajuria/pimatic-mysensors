# #my-plugin configuration options
# Declare your config option for your plugin here. 
# # configuration options
module.exports = {
  title: "MySensors config"
  type: "object"
  properties:

    driver:
      description: "The diver to connect to the PiGateway"
      type: "string"
      enum: ["serialport"]
      default: "serialport"

    driverOptions:
      description: "Options for the driver"
      type: "object"
      default: {
        "serialDevice": '/dev/pts/25', #"/dev/ttyUSB0",
        "baudrate": 115200
      }
    connectionTimeout: 
      description: "Time to wait for ready package on connection"
      type: "integer"
      default: 20000
}
