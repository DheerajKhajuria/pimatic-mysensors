Board = require './board'
colors = require 'colors'

config = {
	id: 1,
	name:"Room1 DHT11",
	driver: "serialport",
	"driverOptions": {
      "serialDevice": "/dev/pts/26",
      "baudrate": 115200
    }
	NodeId: 10,
	protocols: '1.4.1',
	sensorId: 0,
	subtypeId: 0 #V_TEMP	0	Temperature
}


serialDevice = process.argv[2] or  '/dev/pts/24'  #'/dev/ttyUSB0' #
baudrate = process.argv[3] or 115200
console.log config
board = new Board(config)
console.log "connecting to #{config.serialDevice} with #{config.baudRate}".green
board.on "data", (data) => console.log data 
board.on "rfReceived", (data) => console.log data
board.connect().then( =>
  console.log "connected".green
 
).done()



#V_HUM	1	HumidityBV

