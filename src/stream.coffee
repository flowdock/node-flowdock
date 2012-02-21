BufferParser = require('./buffer_parser')
url = require 'url'

baseURL = ->
  url.parse(process.env.FLOWDOCK_STREAM_URL || 'https://stream.flowdock.com')

class Stream extends process.EventEmitter
  constructor: (@auth, @flows) ->

  connect: ->
    uri = baseURL()
    options =
      host: uri.hostname
      port: uri.port
      path: '/flows?filter=' + @flows.join(',')
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    http = if uri.protocol == 'http:'
      require 'http'
    else
      require 'https'

    @request = http.get options, (res) =>
      parser = new BufferParser()
      if res.statusCode >= 500
        @emit "error", res.statusCode, "Streaming connection failed"
        return
      if res.statusCode >= 400
        @emit "error", res.statusCode, "Access denied"
        return

      res.on "data", (data) =>
        messages = parser.parse(data)
        for message in messages
          @emit 'message', message
      res.on "close", =>
        @emit "close"
      res.on "end", =>
        @emit "end"

    @request.end()
    return @request

  close: ->
    @request.abort() if @request

Stream.connect = (auth, flows) ->
  stream = new Stream(auth, flows)
  stream.connect()
  stream

module.exports = Stream
