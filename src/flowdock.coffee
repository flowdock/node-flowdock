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

class Session extends process.EventEmitter

  constructor: (@email, @password, @url = process.env.FLOWDOCK_API_URL || 'https://api.flowdock.com') ->
    @auth = 'Basic ' + new Buffer(@email + ':' + @password).toString('base64')

  flows: (callback) ->
    @get('/flows', {users: 1}, callback)

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
    @post path, message, callback

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

  editMessage: (flowId, organizationId, messageId, data, callback) ->
    @put "/flows/#{organizationId}/#{flowId}/messages/#{messageId}", data, callback

  # API access
  post: (path, data, cb) ->
    @_request('post', path, data, cb)

  get: (path, data, cb) ->
    @_request('get', path, data, cb)

  put: (path, data, cb) ->
    @_request('put', path, data, cb)

  delete: (path, cb) ->
    @_request('delete', path, {}, cb)

  _request: (method, path, data, cb) ->
    uri = @baseURL()
    uri.pathname = path
    if method.toLowerCase() == 'get'
      qs = data
      data = {}
    options =
      uri: url.format(uri)
      method: method
      json: data
      qs: qs
      headers:
        'Authorization': @auth
        'Accept': 'application/json'
        'Content-Type': 'application/json'

    request options, (err, res, body) =>
      if err
        error = new Error('Couldn\'t connect to Flowdock:' + err.toString())
      else if res.statusCode >= 300
        error = new Error('Received status ' + res.statusCode)
      if error?
        @emit 'error', error
        cb?(error)
      else
        cb?(null, body, res)

  baseURL: () ->
    url.parse(@url)

exports.Session = Session
