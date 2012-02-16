url         = require 'url'
http        = require 'http'
https       = require 'https'
querystring = require 'querystring'
events      = require 'events'

Stream = require './stream'

FLOWDOCK_API_URL = url.parse(process.env.FLOWDOCK_API_URL || 'https://api.flowdock.com')
httpClient = (FLOWDOCK_API_URL.protocol == 'https' && https || http)

class Session extends process.EventEmitter
  constructor: (@email, @password) ->
    @auth = 'Basic ' + new Buffer(@email + ':' + @password).toString('base64')
  flows: (callback) ->
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

  stream: (flows...) ->
    flows = flows[0] if flows[0] instanceof Array && flows.length == 1
    return Stream.connect @auth, flows

  send: (subdomain, flow, message, callback) ->
    json = JSON.stringify(message)
    options =
      host: FLOWDOCK_API_URL.hostname
      port: FLOWDOCK_API_URL.port
      path: '/flows/' + subdomain + '/' + flow + '/messages'
      method: 'POST'
      headers:
        'Authorization': @auth
        'Content-Type': 'application/json'
        'Content-Length': json.length
        'Accept': 'application/json'

    req = httpClient.request options, (res) ->
      if res.statusCode >= 500
        @emit "error", res.statusCode, "Couldn't estabilish a connection to Flowdock Messages API"
        return
      if res.statusCode >= 400
        @emit 'error', res.statusCode, "Couldn't post your #{data.event} to Flowdock Messages API"
        return
      callback res if callback
    req.write(json)
    req.end()

  message: (subdomain, flow, message, tags) ->
    data =
      event: 'message'
      content: message
      tags: tags || []
    @send(subdomain, flow, data)

  status: (subdomain, flow, status) ->
    data =
      event: 'status'
      content: status
    @send(flow, data)



exports.Session = Session
