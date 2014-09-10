url = require 'url'
events = require 'events'
request = require 'request'
Stream = require './stream'

extend = (objects...) ->
  result = {}
  for object in objects
    for key, value of object
      result[key] = value
  result

baseURL = ->
  uri = url.parse(process.env.FLOWDOCK_API_URL || 'https://api.flowdock.com')

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

      flows = JSON.parse body.toString("utf8")
      callback(flows, res) if callback?

  # Start streaming flows given as argument using authentication credentials
  #
  # flows - Flow id or array of flow ids
  # options - query string hash
  #
  # Returns Stream object
  stream: (flows, options = {}) ->
    flows = [flows] unless Array.isArray(flows)
    Stream.connect @auth, flows, options

  # Send message to Flowdock
  send: (path, message, callback) ->
    uri = baseURL()
    uri.path = path
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
      callback(body, res) if callback?

  # Send a chat message to Flowdock
  message: (flowId, message, tags, callback) ->
    data =
      flow: flowId
      event: 'message'
      content: message
      tags: tags || []
    @send "/messages", data, callback

  # Send a thread message to Flowdock
  threadMessage: (flowId, threadId, message, tags, callback) ->
    data =
      flow: flowId
      thread_id: threadId
      event: 'message'
      content: message
      tags: tags || []
    @send "/messages", data, callback

  # Send a chat comment to Flowdock
  comment: (flowId, parentId, comment, tags, callback) ->
    data =
      flow: flowId
      message: parentId
      event: 'comment'
      content: comment
      tags: tags || []
    @send "/comments", data, callback

  # Send a private message to Flowdock
  privateMessage: (userId, message, tags, callback) ->
    data =
      event: 'message'
      content: message
      tags: tags || []
    @send "/private/#{userId}/messages", data, callback

  # Change status on Flowdock
  status: (flowId, status, callback) ->
    data =
      event: 'status'
      content: status
      flow: flowId
    @send "/messages", data, callback

  # Invite a user to an organization's flow
  invite: (flowId, organizationId, email, message, callback) ->
    data =
      email: email
      message: message
    @send "/flows/#{organizationId}/#{flowId}/invitations", data, callback

exports.Session = Session
