module.exports = {
  title: "MySensors device config schemes"
  MySensorsDHT: {
    title: "MySensorsDHT config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      protocols:
        description: "Polling interval for the readings, should be greater then 2"
        type: "string"
        default: "1.4.1"
      sensorid:
        description: "Polling interval for the readings, should be greater then 2"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
      subtypeid:
        description: "Polling interval for the readings, should be greater then 2"
        type: "array"
        default: []
        format: "table"
        items:
          type: "number"
    }
}