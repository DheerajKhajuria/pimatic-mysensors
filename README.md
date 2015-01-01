pimatic-plugin-MySensors
========================

Note:  beta version 

Pimatic plugin supporting MySensors as controller. (http://mysensors.org/)

### Controllers
* node-id to be fixed in Sensors/Actuator code.

* Support for following sensors
  *Temperature and Humidity  ( http://mysensors.org/build/humidity)
  *more to be add.. :)

### Gateways
*   Gateway can be anything from for arduino serial gateway or Raspberry pi 
   
    NRF24L01+ connected to  raspberry pi SPI. (using  https://github.com/mysensors/Raspberry )
    ( SPI core clock changes and never works. if pi is  overclock , so avoid it )
    
    Serial Gateway (http://mysensors.org/build/serial_gateway)

### Pimatic Configuration changes   

* Configuration

You can load the plugin by editing your config.json to include:

{
      "plugin": "MySensors",
      "driver": "serialport",
      "driverOptions": {
      "serialDevice": "/dev/ttyMySensorsGateway", # #'/dev/ttyUSBx' if using serial Gateway
      "baudrate": 115200
      }
}
in the plugins section. 


* Devices

Devices must be added manually to the device section of your pimatic config.

This is the basic sensor with only temperature and humidity

{
      "id": "10",  # node ID
      "name": "DHT",
      "class": "MySensorsDHT",
      "protocols": "1.4.1",
      "sensorid": [
        0,  # sensor IDs
        1
      ],
      "subtypeid": [
        0,  #V_TEMP	0	Temperature
        1   #V_HUM	1	Humidity
      ]
}
