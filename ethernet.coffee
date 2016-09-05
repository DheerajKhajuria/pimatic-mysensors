events = require 'events'
net = require 'net'
Promise = require 'bluebird'

class EthernetDriver extends events.EventEmitter
  
  constructor: (protocolOptions)->
    port = protocolOptions.port
    host = protocolOptions.host
    @connection = net.createConnection port, host
  connect: (timeout, retries) ->
    # cleanup
    @ready = no

    # reject promise on error
    @connection.on('error', (error) => @emit('error', error) )
    @connection.on('close', => @emit 'close' )
    
    # setup data listner
    @connection.on 'data', (data) => 
      # Sanitize data

      line = data.slice(0, data.length - 1)
      
      @emit('line', line)
    
    #resolve promise on connect
    @connection.on 'connect', () =>
      @ready = yes
      @emit 'ready'
      return
      
    return new Promise( (resolve, reject) =>
      @once("ready", resolve)
      @once("error", reject)
    )

  disconnect: -> 
    @connection.end()
    return Promise.resolve()

  write: (data) -> 
    if not @connection.write(data, 'utf-8', () =>
      @emit "done"
    )
      @emit "error"

    return new Promise( (resolve, reject) =>
      @once("done", resolve)
      @once("error", reject)
    )

module.exports = EthernetDriver
