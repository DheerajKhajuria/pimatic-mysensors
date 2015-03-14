pimatic-plugin-mySensors
========================

> Note:  beta version 

Pimatic plugin supporting MySensors as controller. (http://mysensors.org/)

Controllers
-----------
  node-id to be fixed in Sensors/Actuator code.

  Support for following sensors
  * Temperature and Humidity  ( http://mysensors.org/build/humidity)
  * Temperature and Pressure ( http://mysensors.org/build/pressure)
  * Motion ( http://mysensors.org/build/motion )
  * Relay-Actuator ( http://www.mysensors.org/build/relay )
  * TimeAware Sensor support ( Unix time seconds ) 
  * Binary buttom ( http://www.mysensors.org/build/binary )
  * Battery level stats of sensors
  * PulseMeter ( experimental only support wattage )
  * more to be add.. :)

Gateways
--------- 
  Gateway can be anything from for arduino serial gateway or Raspberry pi 
   
  * NRF24L01+ connected to  raspberry pi SPI. (using  https://github.com/mysensors/Raspberry )
    ( SPI core clock changes and never works. if pi is  overclock , so avoid it )
    
  * Serial Gateway (http://mysensors.org/build/serial_gateway)

Pimatic Configuration changes   
-----------------------------

### Configuration

You can load the plugin by editing your config.json to include:
```
{
      "plugin": "mysensors",
      "driver": "serialport",
      "protocols": "1.4.1",
      "driverOptions": {
      "//": "'/dev/ttyUSBx' if using serial Gateway",
      "serialDevice": "/dev/ttyMySensorsGateway", 
      "baudrate": 115200
      }
}
```
in the plugins section. 

### Devices

* Temperature and Humidity

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

* Temperature and Pressure

```
 {
      "id": "BMP",
      "name": "BMP",
      "class": "MySensorsBMP",
      "nodeid": 10,
      "sensorid": [
        0,
        1,
        2
      ]
    }
```

* Motion sensor PIR 
 
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
* Relay-Actuator 
 
```
 {
      "id": "Switch",
      "name": "Switch",
      "class": "MySensorsSwitch",
      "nodeid": 10,
      "sensorid": 1
    },
```
* Binay Button
 
```
  {
      "id": "Door",
      "name": "Door",
      "class": "MySensorsButton",
      "nodeid": 12,
      "sensorid": 1
  },
  
```
*  Battery Stat
```
  {
      "id": "Battery",
      "name": "BatteryStat",
      "class": "MySensorBattery",
      "nodeid": [
      11,
      12,
      13
      ]
  },
  
```
