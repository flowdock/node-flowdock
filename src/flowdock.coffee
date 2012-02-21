url = require 'url'
events = require 'events'
request = require 'request'
Stream = require './stream'

baseURL = ->
  url.parse(process.env.FLOWDOCK_API_URL || 'https://api.flowdock.com')

class Session extends process.EventEmitter
  constructor: (@email, @password) ->
    @auth = 'Basic ' + new Buffer(@email + ':' + @password).toString('base64')
  flows: (callback) ->
    uri = baseURL()
    uri.path = '/flows?users=1'

    options =
      uri: uri
      method: 'GET'
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    request options, (error, res, body) =>
      if error
        @emit 'error', 'Couldn\'t connect to Flowdock'
        return
      if res.statusCode > 300
        @emit 'error', res.statusCode
        return

      flows = JSON.parse(body.toString("utf8"))
      callback(flows)

  stream: (flows...) ->
    flows = flows[0] if flows[0] instanceof Array && flows.length == 1
    return Stream.connect @auth, flows

  send: (flow, message, callback) ->
    uri = baseURL()
    uri.path = "/flows/#{flow.replace ':', '/'}/messages"

    options =
      uri: uri
      method: 'POST'
      json: message
      headers:
        'Authorization': @auth
        'Accept': 'application/json'

    request options, (error, res, body) =>
      if error
        @emit 'error', 'Couldn\'t connect to Flowdock'
        return
      else if res.statusCode >= 300
        @emit 'error', res.statusCode
        return

      callback res if callback

  message: (flow, message, tags) ->
    data =
      event: 'message'
      content: message
      tags: tags || []
    @send(flow, data)

  status: (flow, status) ->
    data =
      event: 'status'
      content: status
    @send(flow, data)



exports.Session = Session
