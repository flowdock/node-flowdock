https = require("https")
querystring = require('querystring')
events = require("events")

host = ".flowdock.com"

class FlowdockSocket extends process.EventEmitter
  constructor: (@cookies, @clientId) ->
    @ack = -1
    @connect()

  data: () ->
    "ack": @ack,
    "mode": "stream2"
    "last_activity": new Date().getTime(),
    "client": @clientId

  connect: () ->
    data = querystring.stringify(@data())
    options =
      host: 'www' + host
      path: '/messages?' + data
      method: 'GET'
      headers:
        'Cookie': @cookies.join("; ")

    https.get options, (res) =>
      buffer = ""
      res.on "data", (data) =>
        chunk = data.toString("utf8")
        if chunk[chunk.length - 1] != "\n"
          buffer += chunk
          return

        (buffer + chunk).split("\n").forEach (json) =>
          if (json.length > 0)
            message = JSON.parse(json)
            @ack = message.id
            @emit("message", message)
        buffer = ""
      res.on "end", =>
        @connect()



class Session extends process.EventEmitter
  constructor: (@email, @password) ->
    @clientId = (random = (length) ->
      if length == 0
        ''
      else
        chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
        chars.charAt(Math.floor(Math.random() * chars.length)) + random(length - 1)
    )(16)
    @cookies = []
    @flows = []
    @login(() =>
      @flows.forEach((flow) =>
        @subscribe(flow.subdomain, flow.name)
      )
    )

  start: () ->
    @socket = new FlowdockSocket(@cookies, @clientId)
    @socket.on "message", (message) =>
      @emit("message", message)

  login: (callback) ->
    post_data = querystring.stringify(
      "user_session[email]": @email
      "user_session[password]": @password
    )

    options =
      host: 'www' + host
      path: '/session'
      method: 'POST'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': post_data.length

    req = https.request options, (res) =>
      @cookies = res.headers["set-cookie"].filter((cookie) ->
        cookie.indexOf("secure; HttpOnly") > 0
      ).map((cookie) ->
        cookie.split(";")[0]
      )
      res.on "end", () =>
        @start()
        callback()

    req.write(post_data)
    req.end()

  subscribe: (subdomain, flow) ->
    @flows.push(
      subdomain: subdomain
      name: flow
    )
    return if @cookies.length == 0

    if @flows.length == 0
      @start()

    options =
      host: subdomain + host
      path: '/flows/' + flow
      headers:
        'Cookie': @cookies.join("; ")
    
    https.get options, (res) =>
      res.on "end", () =>
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

exports.Session = Session
