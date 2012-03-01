url = require 'url'
request = require 'request'
JSONStream = require('./json_stream')

baseURL = ->
  url.parse(process.env.FLOWDOCK_STREAM_URL || 'https://stream.flowdock.com/flows')

backoff = (backoff, errors, operator = '*') ->
  Math.min(
    backoff.max,
    (if operator == '+'
      errors
    else
      Math.pow 2, errors - 1) * backoff.delay
  )

class Stream extends process.EventEmitter
  constructor: (@auth, @flows) ->
    @networkErrors = 0
    @responseErrors = 0
    @on 'reconnecting', (timeout) =>
      setTimeout =>
        @connect()
      , timeout

  connect: ->
    return if @disconnecting
    uri = baseURL()
    uri.qs =
      filter: @flows.join ','

    options =
      uri: uri
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    errorHandler = (error) =>
      @networkErrors += 1
      @emit 'clientError', 0, 'Network error'
      @emit 'reconnecting', (backoff Stream.backoff.network, @networkErrors, '+')

    @request = request(options).on 'response', (response) =>
      @request.removeListener 'error', errorHandler

      @networkErrors = 0
      if response.statusCode >= 400
        @responseErrors += 1
        @emit 'clientError', response.statusCode
        @emit 'reconnecting', (backoff Stream.backoff.error, @responseErrors, '*')
      else
        @responseErrors = 0
        parser = new JSONStream()
        parser.on 'data', (message) =>
          @emit 'message', message

        @request.on 'abort', =>
          parser.removeAllListeners()
          @emit 'disconnected'
          @emit 'end'

        parser.on 'end', =>
          parser.removeAllListeners()
          @emit 'disconnected'
          @emit 'clientError', 0, 'Disconnected'
          @emit 'reconnecting', 0 

        @request.pipe parser
        @emit 'connected'
    @request.once 'error', errorHandler
    @request

  end: ->
    @disconnecting = true
    if @request
      @request.abort()
      @request.removeAllListeners()
      @request = undefined
  close: ->
    console.warn 'DEPRECATED, use Stream#end() instead'
    @end()


Stream.connect = (auth, flows) ->
  stream = new Stream(auth, flows)
  stream.connect()
  stream


Stream.backoff =
  network:
    delay: 200
    max: 10000
  error:
    delay: 2000
    max: 120000

module.exports = Stream
