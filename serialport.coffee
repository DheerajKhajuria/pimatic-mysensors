module.exports = (env) ->

  events = require 'events'

  serialport = require("serialport")
  SerialPort = require 'serialport'
  Readline = SerialPort.parsers.Readline #require('@serialport/parser-readline')

  Promise = env.require 'bluebird'
  Promise.promisifyAll(SerialPort.prototype)


  class SerialPortDriver extends events.EventEmitter

    constructor: (protocolOptions)->
      env.logger.debug "initializing SerialPortDriver"
      @serialPort = new SerialPort(protocolOptions.serialDevice, {
        baudRate: protocolOptions.baudrate,
        autoOpen: false
      })

    connect: (timeout, retries) ->
      # cleanup
      @ready = no
      @serialPort.removeAllListeners('error')
      @serialPort.removeAllListeners('data')
      @serialPort.removeAllListeners('close')

      @serialPort.on('error', (error) => @emit('error', error) )
      @serialPort.on('close', => @emit 'close' )

      return @serialPort.openAsync().then( =>
        #resolver = null

        # setup data listener
        @parser = @serialPort.pipe(new Readline("\n"));
        @parser.on("data", (data) =>
          # Sanitize data
          line = data.replace(/\0/g, '').trim()
          @emit('data', data)
          #if line is "ready"
          #  @ready = yes
          #  @emit 'ready'
          #return
          #unless @ready
            # got, data but was not ready => reset
          #  @serialPort.writeAsync("RESET\n").catch( (error) -> @emit("error", error) )
          #  return
          @emit('line', line)
        )

        #return new Promise( (resolve, reject) =>
          # write ping to force reset (see data listerner) if device was not reseted probably
        #  Promise.delay(1000).then( =>
        #    @serialPort.writeAsync("PING\n").catch(reject)
        #  ).done()
        #  resolver = resolve
        #  @once("ready", resolver)
        #).timeout(timeout).catch( (err) =>
        #  @removeListener("ready", resolver)
        #  @serialPort.removeAllListeners('data')
        #  if err.name is "TimeoutError" and retries > 0
        #    @emit 'reconnect', err
            # try to reconnect
        #    return @connect(timeout, retries-1)
        #  else
        #    throw err
        #)
      )

    disconnect: -> @serialPort.closeAsync()

    write: (data) -> @serialPort.writeAsync(data)

  module.exports = SerialPortDriver
