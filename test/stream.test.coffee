assert = require 'assert'
Stream = require __dirname + '/../src/stream'
Mockdock = require('./helper').Mockdock

describe 'Stream', ->
  mockdock = Mockdock.start()

  beforeEach ->
    process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port}"

  afterEach ->
    mockdock.removeAllListeners()

  describe 'url', ->
    it 'has flows as query param', (done) ->
      mockdock.once 'request', (req, res) ->
        stream.end()
        assert.ok req.url.indexOf('example%3Amain') > 0
        assert.ok req.url.indexOf('example%3Atest') > 0
        done()
      stream = Stream.connect 'foobar', ['example:main', 'example:test']

    it 'has authentication header', (done) ->
      mockdock.once 'request', (req, res) ->
        stream.end()
        assert.equal req.headers.authorization, 'foobar'
        done()
      stream = Stream.connect 'foobar', ['example:main', 'example:test']

    it 'can set extra parameters', (done) ->
      mockdock.once 'request', (req, res) ->
        stream.end()
        assert.ok req.url.indexOf('active=true') > 0
        done()
      stream = Stream.connect 'foobar', ['example:main'], active: true

  describe 'response', ->
    it 'emits error if connection cannot be established', (done) ->
      process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port + 1}"
      stream = Stream.connect('foobar', ['example:main'])
      stream.on 'clientError', (status, message) ->
        stream.end()
        assert.equal status, 0
        done()

    it 'emits error event if response is not successful', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 401
        res.end()
  
      stream = Stream.connect 'foobar', ['example:main']
      stream.once 'clientError', (status, message) ->
        stream.end()
        assert.equal status, 401
        done()

    it 'emits end when response ends', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 200
        res.write '\n'

      stream = Stream.connect 'foobar', ['example:main']
      stream.once 'connected', ->
        stream.end()
      stream.once 'end', ->
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
      stream.once 'message', (message) ->
        assert.equal message.event, 'message'
        stream.end()
        done()

  describe 'reconnection', ->
    it 'reconnects immediately after connection ends', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 200
        res.write '\n'
        res.end()

      stream = Stream.connect 'foobar', ['example:main']
      stream.once 'reconnecting', (timeout) ->
        stream.end()
        assert.equal timeout, 0
        done()

    it 'reconnects after small delay if network error', (done) ->
      process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port + 1}"
      stream = Stream.connect 'foobar', ['example:main']
      stream.once 'reconnecting', (timeout) ->
        stream.end()
        assert.equal timeout, 200
        done()

    it 'backs off linearly if there are network errors', (done) ->
      process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port + 1}"
      stream = Stream.connect 'foobar', ['example:main']
      stream.networkErrors = 2
      stream.once 'reconnecting', (timeout) ->
        stream.end()
        assert.equal timeout, 600
        done()


    it 'reconnects after delay if server responds with error', (done) ->
      mockdock.once 'request', (req, res) ->
        res.writeHead 503
        res.end()

      stream = Stream.connect 'foobar', ['example:main']
      stream.once 'reconnecting', (timeout) ->
        stream.end()
        assert.equal timeout, 2000
        done()

    it 'increases delay exponentially if there are existing failure responses', (done) ->
      mockdock.on 'request', (req, res) ->
        res.writeHead 503
        res.end()

      stream = Stream.connect 'foobar', ['example:main']
      stream.responseErrors = 2
      stream.once 'reconnecting', (timeout) ->
        stream.end()
        assert.equal timeout, 8000
        done()

