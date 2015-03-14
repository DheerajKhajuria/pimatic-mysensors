module.exports = {
  title: "MySensors device config schemes"
  MySensorsDHT: {
    title: "MySensorsDHT config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-ids that uniquely identifies one attached sensor"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
      showbatterystat:
        description: "This enable the batterystats from the sensor node default: false"
        type: "boolean"
        default: false
    },
  MySensorsBMP: {
    title: "MySensorsBMP config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-ids that uniquely identifies one attached sensor"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
    },
  MySensorsPulseMeter: {
    title: "MySensorsPulseMeter config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-ids that uniquely identifies one attached sensor"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
    },  
  MySensorsPIR: {
    title: "MySensorsPIR config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
      resetTime:
        description: "Time after that the PIR presence value is reset to absent"
        type: "number"
        default: 6000
    },
  MySensorsButton: {
    title: "MySensorsButton config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
    },
  MySensorsSwitch: {
    title: "MySensorsSwitch config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
    }, 
  MySensorBattery: {
    title: "MySensorBattery config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
   }
}   
