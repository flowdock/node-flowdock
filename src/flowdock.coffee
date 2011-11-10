https = require("https")
querystring = require('querystring')
events = require("events")

host = (process.env.FLOWDOCK_ENDPOINT || ".flowdock.com")

class FlowdockSocket extends process.EventEmitter
  constructor: (@cookies, @clientId) ->
    @ack = -1
    @connect()

  data: () ->
    "ack": @ack,
    "mode": "stream2"
    "last_activity": new Date().getTime(),
    "client": @clientId

  close: () ->
    if @request
      @request.abort()

  connect: () ->
    data = querystring.stringify(@data())
    options =
      host: 'www' + host
      path: '/messages?' + data
      method: 'GET'
      headers:
        'Cookie': @cookies.join("; ")

    @request = https.get options, (res) =>
      if res.statusCode > 500
        @emit "error", res.statusCode, "Backend connection failed"
        return

      buffer = ""
      res.on "data", (data) =>
        chunk = data.toString("utf8")
        if chunk[chunk.length - 1] != "\n"
          buffer += chunk
          return

        (buffer + chunk).split("\n").forEach (json) =>
          if (json.length > 0)
            message = JSON.parse(json)
            @ack = Math.max(message.id, @ack)
            @emit("message", message)
        buffer = ""
      res.on "close", =>
        console.log "Connection terminated. Restart your connection to get back online."
      res.on "end", =>
        @connect()

handshake = (cookies, subdomain, flow, callback) ->
  options =
    host: subdomain + host
    path: '/flows/' + flow
    headers:
      'Cookie': cookies.join("; ")

  https.get options, (res) =>
    res.on "end", () =>
      callback()

class Session extends process.EventEmitter
  constructor: (@email, @password) ->
    @flows = []
    @users = []
    @initialize()

  initialize: () ->
    @clientId = (random = (length) ->
      if length == 0
        ''
      else
        chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
        chars.charAt(Math.floor(Math.random() * chars.length)) + random(length - 1)
    )(16)
    @users = []
    @cookies = []
    @socket = null
    @login()
    @subscribe flow.subdomain, flow.name for flow in @flows

  start: () ->
    @socket = new FlowdockSocket(@cookies, @clientId)
    @socket.on "message", (message) =>
      @emit("message", message)
    @socket.on "error", (statusCode, message) =>
      setTimeout () =>
        @initialize()
      , 5000

  login: () ->
    post_data = querystring.stringify(
      "user_session[email]": @email
      "user_session[password]": @password
      "user_session[remember_me]": "1"
    )

    options =
      host: 'www' + host
      path: '/session'
      method: 'POST'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': post_data.length,
        'Accept': 'text/javascript'

    req = https.request options, (res) =>
      @cookies = res.headers["set-cookie"].map((cookie) ->
        cookie.split(";")[0]
      )
      res.on "end", () =>
        switch res.statusCode
          when 200, 302
            @emit "login"
          else
            console.log "ERROR: Unsuccessful login. Exiting."
            process.exit(0)

    req.write(post_data)
    req.end()

  fetchFlows: (callback) ->
    if @cookies.length == 0
      @once "login", =>
        @fetchFlows(callback)
      return

    options =
      host: 'www' + host
      path: '/flows.json'
      method: 'GET'
      headers:
        'Cookie': @cookies.join("; ")

    request = https.get options, (res) =>
      data = ""
      res.on "data", (chunk) ->
        data += chunk
      res.on "end", ->
        flows = JSON.parse(data.toString("utf8"))
        callback(flows)
    request.end()

  fetchUsers: (subdomain, flowSlug, callback) ->
    if @cookies.length == 0
      @once "login", =>
        @fetchUsers(subdomain, flowSlug, callback)
      return

    options =
      host: subdomain + host
      path: '/flows/' + flowSlug + '.json'
      method: 'GET'
      headers:
        'Cookie': @cookies.join("; ")

    request = https.get options, (res) =>
      data = ""
      res.on "data", (chunk) ->
        data += chunk
      res.on "end", =>
        json = JSON.parse(data.toString("utf8"))
        json.users.forEach (flow_user) =>
          @users.push(flow_user)
        callback(@users)
    request.end()

  subscribe: (subdomain, flow) ->
    if @cookies.length == 0
      @once "login", =>
        @subscribe subdomain, flow
      return

    if @flows.filter((f) -> f.subdomain == subdomain && f.name == flow).length == 0
      @flows.push(
        subdomain: subdomain
        name: flow
      )

    options =
      host: subdomain + host
      path: '/flows/' + flow
      headers:
        'Cookie': @cookies.join("; ")

    handshake @cookies, subdomain, flow, =>
      @start() unless @socket
      post_data = querystring.stringify(
        channel: '/meta'
        event: 'join'
        message: JSON.stringify(
          channel: '/flows/' + flow
          client: @clientId
        )
      )
      options =
        host: subdomain + host
        path: '/messages'
        method: 'POST'
        headers:
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': post_data.length
          'Cookie': @cookies.join("; ")

      req = https.request(options)
      req.write(post_data)
      req.end()

  send: (subdomain, flow, message) ->
    data = {}
    data["message"] = JSON.stringify(message["content"] || message["message"])
    data["event"] = message["event"]
    data["tags"] = (message["tags"] || []).join(" ")
    data["channel"] = "/flows/" + flow

    ["uuid", "app"].forEach (key) ->
      data[key] = message[key] if message[key]

    postMessage = () =>
      post_data = querystring.stringify(data)

      options =
        host: subdomain + host
        path: '/messages'
        method: 'POST'
        headers:
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': post_data.length
          'Cookie': @cookies.join("; ")


      req = https.request options
      req.write(post_data)
      req.end()

    if (@flows.filter((flow) -> flow.subdomain == subdomain && flow.name == flow).length > 0)
      handshake ->
        postMessage()
    else
      postMessage()

  chatMessage: (subdomain, flow, message) ->
    data =
      content: message
      app: "chat"
      event: "message"
    @send(subdomain, flow, data)

exports.Session = Session
