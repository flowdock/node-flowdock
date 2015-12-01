assert = require 'assert'
flowdock = require __dirname + '/../src/flowdock'
Mockdock = require('./helper').Mockdock

describe 'Flowdock', ->
  mockdock = Mockdock.start()
  session = null

  beforeEach ->
    process.env.FLOWDOCK_STREAM_URL = "http://localhost:#{mockdock.port}"
    process.env.FLOWDOCK_API_URL = "http://localhost:#{mockdock.port}"
    session = new flowdock.Session('test', 'password')
    session.on 'error', -> #noop

  afterEach ->
    mockdock.removeAllListeners()

  describe 'stream', ->
    it 'can handle array parameter', (done) ->
      mockdock.on 'request', (req, res) ->
        assert.equal req.url, '/?filter=example%3Amain%2Cexample%3Atest'
        res.setHeader('Content-Type', 'application/json')
        res.end('{}')
      stream = session.stream ['example:main', 'example:test']
      stream.on 'connected', ->
        stream.removeAllListeners()
        done()
      assert.deepEqual stream.flows, ['example:main', 'example:test']

    it 'can handle single flow', (done) ->
      mockdock.on 'request', (req, res) ->
        assert.equal req.url, '/?filter=example%3Amain'
        res.setHeader('Content-Type', 'application/json')
        res.end('{}')
      stream = session.stream 'example:main'
      stream.on 'connected', ->
        stream.removeAllListeners()
        done()
      assert.deepEqual stream.flows, ['example:main']

  describe 'invitations', ->
    it 'can send an invitation', (done) ->
      mockdock.on 'request', (req, res) ->
        assert.equal req.url, '/flows/org1/flow1/invitations'
        res.setHeader('Content-Type', 'application/json')
        res.end('{}')
      session.invite 'flow1', 'org1', 'test@localhost', 'test message', (err, data, result) ->
        assert.equal err, null
        done()

  describe '_request', ->
    it 'makes a sensible request', (done) ->
      mockdock.on 'request', (req, res) ->
        assert.equal req.url, '/flows/find?id=acdcabbacd1234567890'
        res.setHeader('Content-Type', 'application/json')
        res.end('{"flow":"foo"}')
      session._request 'get', '/flows/find', {id: 'acdcabbacd1234567890'}, (err, data, res) ->
        assert.equal err, null
        assert.deepEqual data, {flow: "foo"}
        done()

  describe 'Session', ->
    it 'should optionally take a URL', (done) ->
      alt_mockdock = Mockdock.start()
      alt_session = new flowdock.Session('test', 'password', "http://localhost:#{alt_mockdock.port}")
      
      alt_mockdock.on 'request', (req, res) ->
        assert.equal req.url, '/flows/find?id=acdcabbacd1234567890'
        res.setHeader('Content-Type', 'application/json')
        res.end('{"flow":"foo"}')
      alt_session._request 'get', '/flows/find', {id: 'acdcabbacd1234567890'}, (err, data, res) ->
        assert.equal err, null
        assert.deepEqual data, {flow: "foo"}
        alt_mockdock.removeAllListeners()
        done()
      