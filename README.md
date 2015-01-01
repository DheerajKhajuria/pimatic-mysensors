pimatic-plugin-template
=======================

See the [development guide](http://pimatic.org/guide/development/required-skills-readings/) for
usage.

Some Tips:

###Adding package dependencies
* You can add other package dependencies by running `npm install something --save`. With the `--save`
  option npm will auto add the installed dependency in your `package.json`
* You can always install all dependencies in the package.json with `npm install`

###Commit your changes to git
* Add all edited files with `git add file`. For example: `git add package.json` then commit you changes 
  with `git commit`.
* After that you can push you commited work to github: `git push`
* 


pimatic-plugin-MySensors
========================

Pimatic plugin supporting MySensors as controller. (http://mysensors.org/)

### Controllers
* node-id to be fixed in Sensors/Actuator code.

* Support for following sensors
** Temperature and Humidity  ( http://mysensors.org/build/humidity)
** more to be add.. :)

### Gateways
   Gateway usign 
   using  https://github.com/mysensors/Raspberry


Note:  beta version 

Configuration

You can load the plugin by editing your config.json to include:

{
      "plugin": "MySensors",
      "driver": "serialport",
      "driverOptions": {
      "serialDevice": "/dev/ttyMySensorsGateway", # #'/dev/ttyUSB0' if using 
      "baudrate": 115200
      }
}
in the plugins section. 


Devices

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
