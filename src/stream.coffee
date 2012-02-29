url = require 'url'
request = require 'request'
JSONStream = require('./json_stream')

baseURL = ->
  url.parse(process.env.FLOWDOCK_STREAM_URL || 'https://stream.flowdock.com/flows')

class Stream extends process.EventEmitter
  constructor: (@auth, @flows) ->

  connect: ->
    uri = baseURL()
    uri.qs =
      filter: @flows.join ','

    options =
      uri: uri
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    @request = request(options).on 'response', (response) =>
      if response.statusCode >= 500
        @emit 'error', response.statusCode
      else if response.statusCode >= 401
        @emit 'error', response.statusCode
      else
        parser = new JSONStream()
        parser.on 'data', (message) =>
          @emit 'message', message
        parser.on 'end', =>
          @emit 'end'
        @request.pipe parser
    @request.on 'error', (error) =>
      @emit 'error', 0

  close: ->
    @request.abort() if @request

Stream.connect = (auth, flows) ->
  stream = new Stream(auth, flows)
  stream.connect()
  stream

module.exports = Stream
