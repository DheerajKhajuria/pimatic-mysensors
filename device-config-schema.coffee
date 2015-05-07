module.exports = {
  title: "MySensors device config schemes"
  MySensorsDHT: {
    title: "MySensorsDHT config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
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
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no
    },
  MySensorsBMP: {
    title: "MySensorsBMP config options"
    type: "object"
    extensions: ["xLink" ,"xAttributeOptions"]
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
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no    
    },
  MySensorsPulseMeter: {
    title: "MySensorsPulseMeter config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      appliedVoltage:
        description: "The voltage applied"
        type: "number"
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-ids that uniquely identifies one attached sensor"
        type: "number"
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no    
    },  
  MySensorsPIR: {
    title: "MySensorsPIR config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
      autoReset:
        description: "Disable this if your PIR sensors also emit absence."
        type: "boolean"
        default: true
      resetTime:
        description: "Time after that the PIR presence value is reset to absent"
        type: "number"
        default: 6000
    },
  MySensorsButton: {
    title: "MySensorsButton config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xClosedLabel", "xOpenedLabel"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no  
    },
  MySensorsSwitch: {
    title: "MySensorsSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
    }, 
  MySensorsDimmer: {
    title: "MySensorsDimmer config options"
    type: "object"
    extensions: ["xConfirm"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
    },
  MySensorsLight: {
    title: "MySensorsLight config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no  
    },
  MySensorsBattery: {
   title: "MySensorsBattery config options"
   type: "object"
   extensions: ["xLink", "xAttributeOptions"]
   properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
    },
  MySensorsGas:  {
    title: "MySensorsGas config options"
    type: "object"
    extensions: ["xLink","xAttributeOptions"]
    properties:
      nodeid:
        description: "The unique id of the node that sends or should receive the message"
        type: "number"
      sensorid:
        description: "This is the child-sensor-id that uniquely identifies one attached sensor"
        type: "number"
      batterySensor:
         description: "Show battery level with Sensors"
         type: "boolean"
         default: no  
    } 
}   
