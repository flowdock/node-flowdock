events = require 'events'
http = require 'http'

# Fake Flowdock Streaming API, do whatever you want
class Mockdock extends events.EventEmitter
  request: (req, res) =>
    @emit 'request', req, res
  constructor: (@port) ->
    server = http.createServer @request
    server.listen(@port)

Mockdock.ephemeralPort = ->
  range = [49152..65535]
  range[Math.floor Math.random() * range.length]

Mockdock.start = ->
  new Mockdock(Mockdock.ephemeralPort())

exports.Mockdock = Mockdock
