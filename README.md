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
  * PulseMeter ( wattage/Ampere )
  * Multi Sensor support as one device.
  * support for sending Custom Value msg to mysensor node ( using Action Provider/Handler )
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
      "protocols": "1.5.1",
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
* Sending custom msg i.e V_VAR1 to V_VAR5 to mysensors node using "send custom "V_VAR1" nodeid: "id" sensorid: "id" cmdcode: "value"
* For sending IR hex code to mysensors node use send custom "V_IR_SEND"  command in action text box.
  exp. send custom "V_IR_SEND" nodeid: "id" sensorid: "id" cmdcode: "0x342333"


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
*  Lux sensor ( lux )
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
* Multi sensor 

This device works a little bit different then the other devices. You can add multiple (or just one, if you like to) sensors to this device, even from different nodes.

You have to give the sensor a name, a type of value that the sensor sends, the nodeid of the sensor and if the sensor is not a battery, then you should also supply the sensorid of the sensor.

##### Attributes:

You should give the sensor an unique **name** 

The **nodeid** should be the nodeid of the MySensors sensor

The **sensorid** should be the sensorid of the MySensors sensor. Don't use this if the type is 'battery'. Then you should only provide a nodeid.

If multiple sensors are using the same sensorid, you can specify a **sensortype**. The PressureSensor Example Arduino sketch from MySensors uses V_PRESSURE to send the pressure and V_FORECAST to send the forecast. They are both send with the same sensorid (MySensor calls it child-sensor-id). 
You can see in the documentation of the MySensors library (http://www.mysensors.org/download/serial_api_15, under 'set, req') that V_PRESSURE has a value of 4, so the **sensortype** is 4. V_FORECAST has a value of 5, so the **sensortype** should be 5.


The **type** can be one of the following:
- **integer** (integers are your primary data-type for number storage)
- **float** (datatype for floating-point numbers, a number that has a decimal point)
- **round** (rounds the received value to the nearest integer)
- **boolean** (true or false)
- **string** (text)
- **battery** (if you want to receive a battery percentage from a node)

**booleanlabels** should only be provided if the type is 'boolean'. Instead of true or false, it will use the text from this array.

You can provide an **acronym**, if you want to display a text before the received value.
 
**unit** can be set to display a text after the received value (lux, %, °C etc).

When you don't set a **label**, then it uses the **name** that you have provided for the sensor. If you don't want that, you can provide a **label**.


##### Example 1:

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
              "type": "float",
              "acronym": "T",
              "unit": "°C"
            },
            {
              "name": "humidity",
              "nodeid": 4,
              "sensorid": 2,
              "type": "round",
              "acronym": "H",
              "unit": "%"
            },
            {
              "name": "moisture",
              "nodeid": 4,
              "sensorid": 0,
              "type": "integer",
              "acronym": "M",
              "unit": "%",
              "label": "ilikepimaticandmysensors"
            },
            {
              "name": "pir",
              "nodeid": 9,
              "sensorid": 2,
              "type": "boolean",
              "booleanlabels": [
                "Movement",
                "No movement"
              ],
              "acronym": "PIR"
            },
            {
              "name": "battery",
              "nodeid": 4,
              "type": "battery",
              "acronym": "Battery",
              "unit": "%"
            }
          ]
        }
```

![MySensorsMulti example](https://raw.githubusercontent.com/PascalLaurens/pimatic-mysensors/master/screenshots/MySensorsMultiExample.png)

In the example above, you can see that the MySensorsMulti class is used.
- Temperature has a nodeid of 4 and an sensorid of 1. Because the temperature has a decimal number, I used 'float' as type. 'T' is displayed before the value and '°C' after the value.
- Humidity has a nodeid of 4 and an sensorid of 2. I used 'round' as type, so the received value will be rounded to the nearest integer. 'H' is displayed before the value and '%' after the value.
- Moisture has a nodeid of 4 and an sensorid of 0. I used 'integer' as type, because my MySensors sketch also sends an integer. 'M' is displayed before the value and '%' after the value. In the picture you can see that if I click the value, it displays 'ilikepimaticandmysensors', instead of 'moisture'.
- Pir has a different nodeid. It uses 9 as nodeid and 2 as sensorid. Because it has a type of 'boolean', it normally displays 'true' or 'false', but because I provided the booleanlabels, it displays 'Movement' or 'No movement'.
- Battery is the battery percentage of the battery from nodeid 4. It displays 'Battery' before the value and '%' after the value.

You can also use other sensors. As long as they support the available value types (integer, float, round, boolean, string or battery). You can't for example use this device as a switch. 

##### Example 2:

In the following example you can see that a lot of sensors are supported with the MySensorsMulti class. The pressure and forecast are both being send with sensorid 12, so I used the sensortype to separate them.

```
    {
      "class": "MySensorsMulti",
      "id": "multi2",
      "name": "Multi Sensor",
      "attributes": [
        {
          "name": "BinarySwitch",
          "nodeid": 1,
          "sensorid": 0,
          "type": "boolean",
          "booleanlabels": [
            "Open",
            "Closed"
          ],
          "acronym": "BinarySwitch: "
        },
        {
          "name": "DimmableLED",
          "nodeid": 1,
          "sensorid": 1,
          "type": "integer",
          "acronym": "DimmableLED: ",
          "unit": "%"
        },
        {
          "name": "DistanceSensor",
          "nodeid": 1,
          "sensorid": 2,
          "type": "integer",
          "acronym": "DistanceSensor: ",
          "unit": "cm"
        },
        {
          "name": "DustSensor",
          "nodeid": 1,
          "sensorid": 3,
          "type": "integer",
          "acronym": "DustSensor: "
        },
        {
          "name": "AirQualitySensor",
          "nodeid": 1,
          "sensorid": 4,
          "type": "integer",
          "acronym": "AirQualitySensor: ",
          "unit": "ppm"
        },
        {
          "name": "HumiditySensor",
          "nodeid": 1,
          "sensorid": 5,
          "type": "float",
          "acronym": "HumiditySensor: ",
          "unit": "%"
        },
        {
          "name": "TemperatureSensor",
          "nodeid": 1,
          "sensorid": 6,
          "type": "float",
          "acronym": "TemperatureSensor: ",
          "unit": "°C"
        },
        {
          "name": "LightSensor",
          "nodeid": 1,
          "sensorid": 7,
          "type": "integer",
          "acronym": "LightSensor: ",
          "unit": "%"
        },
        {
          "name": "LightLuxSensor",
          "nodeid": 1,
          "sensorid": 8,
          "type": "integer",
          "acronym": "LightLuxSensor: ",
          "unit": "lx"
        },
        {
          "name": "SoilMoistSensor",
          "nodeid": 1,
          "sensorid": 9,
          "type": "boolean",
          "booleanlabels": [
            "Needs Water",
            "Water enough"
          ],
          "acronym": "SoilMoistSensor: "
        },
        {
          "name": "SoilMoistPercentageSensor",
          "nodeid": 1,
          "sensorid": 10,
          "type": "integer",
          "acronym": "SoilMoistPercentageSensor: ",
          "unit": "%"
        },
        {
          "name": "MotionSensor",
          "nodeid": 1,
          "sensorid": 11,
          "type": "boolean",
          "booleanlabels": [
            "Movement",
            "No movement"
          ],
          "acronym": "MotionSensor: "
        },
        {
          "name": "PressureSensor",
          "nodeid": 1,
          "sensorid": 12,
          "sensortype": 4,
          "type": "integer",
          "acronym": "PressureSensor: ",
          "unit": "hPa"
        },
        {
          "name": "ForecastSensor",
          "nodeid": 1,
          "sensorid": 12,
          "sensortype": 5,
          "type": "string",
          "acronym": "ForecastSensor: "
        }
      ]
    }
 ```
 
 ![MySensorsMulti example 2](https://raw.githubusercontent.com/PascalLaurens/pimatic-mysensors/master/screenshots/MySensorsMultiExample2.png)
