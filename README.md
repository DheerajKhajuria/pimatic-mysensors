pimatic-plugin-mySensors
========================

> Note:  beta version 

Pimatic plugin supporting MySensors as controller. (http://mysensors.org/)

Controllers
-----------
  Support for following sensors
  * Temperature and Humidity  ( http://mysensors.org/build/humidity)
  * Temperature and Pressure ( http://mysensors.org/build/pressure)
  * Motion ( http://mysensors.org/build/motion )
  * Relay-Actuator ( http://www.mysensors.org/build/relay )
  * TimeAware Sensor support ( Unix time seconds ) 
  * Binary buttom ( http://www.mysensors.org/build/binary )
  * Dimmer 
  * Distance
  * Light Sensor 
  * Lux Sensor
  * Gas Sensor ( ppm )
  * PulseMeter ( experimental only support wattage/Ampere )
  * Battery level  of multiple sensors
  * support for sending IR codes to mysensor node ( using Action Provider/Handler )
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
      "startingNodeId": 1,
      "driverOptions": {
      "//": "'/dev/ttyUSBx' if using serial Gateway",
      "serialDevice": "/dev/ttyMySensorsGateway", 
      "baudrate": 115200
      }
}
```
in the plugins section. 

### Rules
* For sending IR hex code to mysensors node use either "send Ir" or simply "Ir" command in action text box.
  exp. Ir nodeid: "id" sensorid: "id" cmdcode: "0x342333"
Note: uses V_IR_SEND type code to send IR command.
  


### Devices

 Note:  To enable battery level with  sensor. set ["batterystat"] to true. see temp & Hum exp.
        support is enable for all sensor except PIR,Switch. for PIR or switch use configure seperate battery devices.

* Temperature and Humidity

Devices must be added manually to the device section of your pimatic config.

This is the basic sensor with only temperature and humidity
```
 {
      "id": "DHT11",
      "name": "DHT11",
      "class": "MySensorsDHT",
      "nodeid": 10,
      "batterySensor": true,
      "sensorid": [
        0,
        1
      ]
    }
```

* Temperature

This is the basic sensor with only temperature
```
    {
      "id": "Temp1",
      "name": "Temp1",
      "class": "MySensorsDST",
      "nodeid": 11,
      "batterySensor": true,
      "sensorid": 0
    }
```

* Temperature and Pressure

```
 {
      "id": "BMP",
      "name": "BMP",
      "class": "MySensorsBMP",
      "nodeid": 10,
      "batterySensor": true,
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
* Dimmer 
```
 {
      "id": "Dimmer",
      "name": "Dimmer",
      "class": "MySensorsDimmer",
      "nodeid": 10,
      "sensorid": 1
    },
```
* Binary Button
```
  {
      "id": "Door",
      "name": "Door",
      "class": "MySensorsButton",
      "nodeid": 12,
      "batterySensor": true,
      "sensorid": 1
  },

  
```
*  Battery levels
```
  {
      "id": "Battery",
      "name": "Batterylevel",
      "class": "MySensorsBattery",
      "nodeid": [
      11,
      12,
      13
      ]
  },
  
```  
*  Light sensor ( 0 to 100 )
```
  {
      "id": "Light",
      "name": "Light",
      "class": "MySensorsLight",
      "nodeid": 15,
      "batterySensor": true,
      "sensorid": 2
  }
```
*  Lux sensor ( 0 to 10000+ )
```
  {
      "id": "Lux",
      "name": "Lux",
      "class": "MySensorsLux",
      "nodeid": 16,
      "batterySensor": true,
      "sensorid": 1
  }
```
*  Gas sensor ( ppm )
```
  {
      "id": "GasSensor,
      "name": "GasSensor",
      "class": "MySensorsGas",
      "nodeid": 14,
      "batterySensor": true,
      "sensorid": 3
  }
  
```  
*  Pulse sensor ( Watt, KWh and Ampere )
```
  {
      "id": "EnergySensor,
      "name": "Energy Sensor",
      "class": "MySensorsPulseMeter",
      "nodeid": 3,
      "batterySensor": true,
      "sensorid": 1,
      "appliedVoltage"  : 220
  }
  
```  
