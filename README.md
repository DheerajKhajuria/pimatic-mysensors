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
* Multi sensor 

This device works a little bit different then the other devices. You can add multiple (or just one, if you like to) sensors to this device, even from different nodes.

You have to give the sensor a name, a type of value that the sensor sends, the nodeid of the sensor and if the sensor is not a battery, then you should also supply the sensorid of the sensor.

##### Attributes:

You should give the sensor an unique **name** 

The **nodeid** should be the nodeid of the MySensors sensor

The **sensorid** should be the sensorid of the MySensors sensor. Don't use this if the valuetype is 'battery'. Then you should only provide a nodeid.

The **valuetype** can be one of the following:
- **integer (integers are your primary data-type for number storage)
- **float** (datatype for floating-point numbers, a number that has a decimal point)
- **round** (rounds the received value to the nearest integer)
- **boolean** (true or false)
- **string** (text)
- **battery** (if you want to receive a battery percentage from a node)

**booleanlabels** should only be provided if the valuetype is 'boolean'. Instead of true or false, it will use the text from this array.

You can provide an **acronym**, if you want to display a text before the received value.
 
**unit** can be set to display a text after the received value (lux, %, °C etc).

When you don't set a **label**, then it uses the **name** that you have provided for the sensor. If you don't want that, you can provide a **label**.


##### Example:

```
    {
          "class": "MySensorsMulti",
          "id": "multi",
          "name": "Multi Sensor",
          "attributes": [
            {
              "name": "temperature",
              "nodeid": 4,
              "sensorid": 1,
              "valuetype": "float",
              "acronym": "T",
              "unit": "°C"
            },
            {
              "name": "humidity",
              "nodeid": 4,
              "sensorid": 2,
              "valuetype": "round",
              "acronym": "H",
              "unit": "%"
            },
            {
              "name": "moisture",
              "nodeid": 4,
              "sensorid": 0,
              "valuetype": "integer",
              "acronym": "M",
              "unit": "%",
              "label": "ilikepimaticandmysensors"
            },
            {
              "name": "pir",
              "nodeid": 9,
              "sensorid": 2,
              "valuetype": "boolean",
              "booleanlabels": [
                "Movement",
                "No movement"
              ],
              "acronym": "PIR"
            },
            {
              "name": "battery",
              "nodeid": 4,
              "valuetype": "battery",
              "acronym": "Battery",
              "unit": "%"
            }
          ]
        }
```

![MySensorsMulti example](https://raw.githubusercontent.com/PascalLaurens/pimatic-mysensors/master/screenshots/MySensorsMultiExample.png)

In the example above, you can see that the MySensorsMulti class is used.
- Temperature has a nodeid of 4 and an sensorid of 1. Because the temperature has a decimal number, I used 'float' as valuetype. 'T' is displayed before the value and '°C' after the value.
- Humidity has a nodeid of 4 and an sensorid of 2. I used 'round' as valuetype, so the received valuetype will be rounded to the nearest integer. 'H' is displayed before the value and '%' after the value.
- Moisture has a nodeid of 4 and an sensorid of 0. I used 'integer' as valuetype, because my MySensors sketch also sends an integer. 'M' is displayed before the value and '%' after the value. In the picture you can see that if I click the value, it displays 'ilikepimaticandmysensors', instead of 'moisture'.
- Pir has a different nodeid. It uses 9 as nodeid and 2 as sensorid. Because it has a valuetype of 'boolean', it normally displays 'true' or 'false', but because I provided the booleanlabels, it displays 'Movement' or 'No movement'.
- Battery is the battery percentage of the battery from nodeid 4. It displays 'Battery' before the value and '%' after the value.

You can also use other sensors. As long as they support the available value types (integer, float, round, boolean, string or battery). You can't for example use this device as a switch. 
