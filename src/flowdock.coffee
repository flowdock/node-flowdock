url         = require 'url'
http        = require 'http'
https       = require 'https'
querystring = require 'querystring'
events      = require 'events'

BufferParser = require('./buffer_parser')

FLOWDOCK_API_URL    = url.parse(process.env.FLOWDOCK_API_URL    || 'https://api.flowdock.com')
FLOWDOCK_STREAM_URL = url.parse(process.env.FLOWDOCK_STREAM_URL || 'https://stream.flowdock.com')

httpClient = (FLOWDOCK_API_URL.protocol == 'https' && https || http)

class Session extends process.EventEmitter
  constructor: (@email, @password) ->
    @auth = 'Basic ' + new Buffer(@email + ':' + @password).toString('base64')
    @_flows = []
    @_users = []

  flows: (callback) ->
    @fetchFlows (flows) =>
      for flow in flows
        @_users.push user for user in flow.users when !@_users.some((u) -> u.id == user.id)
        @_flows.push flow if !@_flows.some((f) -> f.id == flow.id)
      callback(@_flows)

  fetchFlows: (callback) ->
    options =
      host: FLOWDOCK_API_URL.hostname
      port: FLOWDOCK_API_URL.port
      path: '/flows?users=1'
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    request = httpClient.get options, (res) ->
      data = ""
      res.on "data", (chunk) ->
        data += chunk
      res.on "end", ->
        flows = JSON.parse(data.toString("utf8"))
        callback(flows)
    request.end()

  stream: (flows) ->
    return new Stream(@auth, flows)

class Stream extends process.EventEmitter
  constructor: (@auth, @flows) ->
    @stream = @openStream(@flows.join(','))

  openStream: (flowIds) ->
    options =
      host: FLOWDOCK_STREAM_URL.hostname
      port: FLOWDOCK_STREAM_URL.port
      path: '/flows?filter=' + flowIds
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    req = httpClient.get options, (res) =>
      parser = new BufferParser()
      if res.statusCode > 500
        @emit "error", res.statusCode, "Backend connection failed"
        return

      res.on "data", (data) =>
        messages = parser.parse(data)
        for message in messages
          @emit 'message', message
      res.on "close", =>
        console.log "Connection terminated. Restart your connection to get back online."
      res.on "end", =>
        console.log 'Connection ended.'
    req.end()

    return req

  close: () ->
    @stream.abort()

  message: (flow, message, tags) ->
    data =
      event: 'message'
      content: message
      tags: tags || []
    @post(flow, data)

  status: (flow, status) ->
    data =
      event: 'status'
      content: status
    @post(flow, data)

  post: (flow, data) ->
    post_data = querystring.stringify(data)
    options =
      host: FLOWDOCK_API_URL.hostname
      port: FLOWDOCK_API_URL.port
      path: '/flows/' + flow + '/messages'
      method: 'POST'
      headers:
        'Authorization': @auth
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': post_data.length
        'Accept': 'application/json'

    req = httpClient.request options, (res) ->
      if res.statusCode >= 400
        @emit 'error', res.statusCode, "Couldn't post your #{data.event} to Flowdock."
        return
    req.write(post_data)
    req.end()


exports.Session = Session
