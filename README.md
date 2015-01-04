pimatic-plugin-MySensors
========================

> Note:  beta version 

Screenshots
-----------
[![Screenshot 1][screen1_thumb]](http://www.pimatic.org/screens/screen1.png) 

Pimatic plugin supporting MySensors as controller. (http://mysensors.org/)

### Controllers
  node-id to be fixed in Sensors/Actuator code.

  Support for following sensors
  * Temperature and Humidity  ( http://mysensors.org/build/humidity)
  * motion ( http://mysensors.org/build/motion )
  * more to be add.. :)

### Gateways
  Gateway can be anything from for arduino serial gateway or Raspberry pi 
   
  * NRF24L01+ connected to  raspberry pi SPI. (using  https://github.com/mysensors/Raspberry )
    ( SPI core clock changes and never works. if pi is  overclock , so avoid it )
    
  * Serial Gateway (http://mysensors.org/build/serial_gateway)

### Pimatic Configuration changes   

* Configuration

You can load the plugin by editing your config.json to include:
```
{
      "plugin": "MySensors",
      "driver": "serialport",
      "protocols": "1.4.1",
      "driverOptions": {
      "serialDevice": "/dev/ttyMySensorsGateway", # #'/dev/ttyUSBx' if using serial Gateway
      "baudrate": 115200
      }
}
```
in the plugins section. 

* Devices

Temperature and Humidity

Devices must be added manually to the device section of your pimatic config.

This is the basic sensor with only temperature and humidity
```
 {
      "id": "DHT11",
      "name": "DHT11",
      "class": "MySensorsDHT",
      "nodeid": 10,
      "sensorid": [
        0,
        1
      ]
    }
```
 Motion sensor PIR 
 
```
    {
      "id": "PIR",
      "name": "PIR",
      "class": "MySensorsPIR",
      "nodeid": 10,
      "sensorid": 2,
      "resetTime": 8000
    },
```
