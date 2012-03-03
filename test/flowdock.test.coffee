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

  afterEach ->
    mockdock.removeAllListeners()

  describe 'stream', ->
    it 'can handle array parameter', ->
      stream = session.stream ['example:main', 'example:test']
      assert.deepEqual stream.flows, ['example:main', 'example:test']

    it 'can handle single flow', ->
      stream = session.stream 'example:main'
      assert.deepEqual stream.flows, ['example:main']

