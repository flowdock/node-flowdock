assert = require 'assert'
http = require 'http'
Stream = require(__dirname + '/../src/stream')

# Fake Flowdock Streaming API, do whatever you want
class Mockdock extends process.EventEmitter
  request: (req, res) =>
    @emit 'request', req, res
  constructor: (@port) ->
    server = http.createServer @request
    server.listen(@port)

ephemeralPort = ->
  range = [49152..65535]
  range[Math.floor(Math.random() * range.length)]

describe 'Stream', ->
  describe 'response', ->
    mockdock = new Mockdock(ephemeralPort())

    beforeEach ->
      process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port}"

    it 'emits error if connection cannot be established', (done) ->
      process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port + 1}"
      stream = Stream.connect('foobar', ['example:main'])
      stream.on 'error', (status, message) ->
        assert.equal status, 0
        done()

    it 'emits error event if response is not successful', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 401
        res.end()
  
      stream = Stream.connect('foobar', ['example:main'])
      stream.on 'error', (status, message) ->
        assert.equal status, 401
        done()

    it 'emits end when response ends', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 200
        res.end()

      stream = Stream.connect('foobar', ['example:main'])
      stream.on 'end', ->
        done()

    it 'emits messages', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 200
        res.write JSON.stringify(
          id: 1
          event: 'message'
          content: 'test'
          flow: 'example:main'
        )
        res.write '\r\n'
        res.end()

      stream = Stream.connect 'foobar', ['example:main']
      stream.on 'message', (message) ->
        assert.equal message.event, 'message'
        done()
