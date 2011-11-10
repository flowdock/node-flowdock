var FlowdockSocket, Session, events, handshake, host, https, querystring;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
https = require("https");
querystring = require('querystring');
events = require("events");
host = process.env.FLOWDOCK_ENDPOINT || ".flowdock.com";
FlowdockSocket = (function() {
  __extends(FlowdockSocket, process.EventEmitter);
  function FlowdockSocket(cookies, clientId) {
    this.cookies = cookies;
    this.clientId = clientId;
    this.ack = -1;
    this.connect();
  }
  FlowdockSocket.prototype.data = function() {
    return {
      "ack": this.ack,
      "mode": "stream2",
      "last_activity": new Date().getTime(),
      "client": this.clientId
    };
  };
  FlowdockSocket.prototype.close = function() {
    if (this.request) {
      return this.request.abort();
    }
  };
  FlowdockSocket.prototype.connect = function() {
    var data, options;
    data = querystring.stringify(this.data());
    options = {
      host: 'www' + host,
      path: '/messages?' + data,
      method: 'GET',
      headers: {
        'Cookie': this.cookies.join("; ")
      }
    };
    return this.request = https.get(options, __bind(function(res) {
      var buffer;
      if (res.statusCode > 500) {
        this.emit("error", res.statusCode, "Backend connection failed");
        return;
      }
      buffer = "";
      res.on("data", __bind(function(data) {
        var chunk;
        chunk = data.toString("utf8");
        if (chunk[chunk.length - 1] !== "\n") {
          buffer += chunk;
          return;
        }
        (buffer + chunk).split("\n").forEach(__bind(function(json) {
          var message;
          if (json.length > 0) {
            message = JSON.parse(json);
            this.ack = Math.max(message.id, this.ack);
            return this.emit("message", message);
          }
        }, this));
        return buffer = "";
      }, this));
      res.on("close", __bind(function() {
        return console.log("Connection terminated. Restart your connection to get back online.");
      }, this));
      return res.on("end", __bind(function() {
        return this.connect();
      }, this));
    }, this));
  };
  return FlowdockSocket;
})();
handshake = function(cookies, subdomain, flow, callback) {
  var options;
  options = {
    host: subdomain + host,
    path: '/flows/' + flow,
    headers: {
      'Cookie': cookies.join("; ")
    }
  };
  return https.get(options, __bind(function(res) {
    return res.on("end", __bind(function() {
      return callback();
    }, this));
  }, this));
};
Session = (function() {
  __extends(Session, process.EventEmitter);
  function Session(email, password) {
    this.email = email;
    this.password = password;
    this.flows = [];
    this.users = [];
    this.initialize();
  }
  Session.prototype.initialize = function() {
    var flow, random, _i, _len, _ref, _results;
    this.clientId = (random = function(length) {
      var chars;
      if (length === 0) {
        return '';
      } else {
        chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
        return chars.charAt(Math.floor(Math.random() * chars.length)) + random(length - 1);
      }
    })(16);
    this.users = [];
    this.cookies = [];
    this.socket = null;
    this.login();
    _ref = this.flows;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      flow = _ref[_i];
      _results.push(this.subscribe(flow.subdomain, flow.name));
    }
    return _results;
  };
  Session.prototype.start = function() {
    this.socket = new FlowdockSocket(this.cookies, this.clientId);
    this.socket.on("message", __bind(function(message) {
      return this.emit("message", message);
    }, this));
    return this.socket.on("error", __bind(function(statusCode, message) {
      return setTimeout(__bind(function() {
        return this.initialize();
      }, this), 5000);
    }, this));
  };
  Session.prototype.login = function() {
    var options, post_data, req;
    post_data = querystring.stringify({
      "user_session[email]": this.email,
      "user_session[password]": this.password,
      "user_session[remember_me]": "1"
    });
    options = {
      host: 'www' + host,
      path: '/session',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': post_data.length,
        'Accept': 'text/javascript'
      }
    };
    req = https.request(options, __bind(function(res) {
      this.cookies = res.headers["set-cookie"].map(function(cookie) {
        return cookie.split(";")[0];
      });
      return res.on("end", __bind(function() {
        switch (res.statusCode) {
          case 200:
          case 302:
            return this.emit("login");
          default:
            console.error("ERROR: Flowdock Login failed");
            return this.emit("error", "Login failed");
        }
      }, this));
    }, this));
    req.write(post_data);
    return req.end();
  };
  Session.prototype.fetchFlows = function(callback) {
    var options, request;
    if (this.cookies.length === 0) {
      this.once("login", __bind(function() {
        return this.fetchFlows(callback);
      }, this));
      return;
    }
    options = {
      host: 'www' + host,
      path: '/flows.json',
      method: 'GET',
      headers: {
        'Cookie': this.cookies.join("; ")
      }
    };
    request = https.get(options, __bind(function(res) {
      var data;
      data = "";
      res.on("data", function(chunk) {
        return data += chunk;
      });
      return res.on("end", function() {
        var flows;
        flows = JSON.parse(data.toString("utf8"));
        return callback(flows);
      });
    }, this));
    return request.end();
  };
  Session.prototype.fetchUsers = function(subdomain, flowSlug, callback) {
    var options, request;
    if (this.cookies.length === 0) {
      this.once("login", __bind(function() {
        return this.fetchUsers(subdomain, flowSlug, callback);
      }, this));
      return;
    }
    options = {
      host: subdomain + host,
      path: '/flows/' + flowSlug + '.json',
      method: 'GET',
      headers: {
        'Cookie': this.cookies.join("; ")
      }
    };
    request = https.get(options, __bind(function(res) {
      var data;
      data = "";
      res.on("data", function(chunk) {
        return data += chunk;
      });
      return res.on("end", __bind(function() {
        var json;
        json = JSON.parse(data.toString("utf8"));
        json.users.forEach(__bind(function(flow_user) {
          return this.users.push(flow_user);
        }, this));
        return callback(this.users);
      }, this));
    }, this));
    return request.end();
  };
  Session.prototype.subscribe = function(subdomain, flow) {
    var options;
    if (this.cookies.length === 0) {
      this.once("login", __bind(function() {
        return this.subscribe(subdomain, flow);
      }, this));
      return;
    }
    if (this.flows.filter(function(f) {
      return f.subdomain === subdomain && f.name === flow;
    }).length === 0) {
      this.flows.push({
        subdomain: subdomain,
        name: flow
      });
    }
    options = {
      host: subdomain + host,
      path: '/flows/' + flow,
      headers: {
        'Cookie': this.cookies.join("; ")
      }
    };
    return handshake(this.cookies, subdomain, flow, __bind(function() {
      var post_data, req;
      if (!this.socket) {
        this.start();
      }
      post_data = querystring.stringify({
        channel: '/meta',
        event: 'join',
        message: JSON.stringify({
          channel: '/flows/' + flow,
          client: this.clientId
        })
      });
      options = {
        host: subdomain + host,
        path: '/messages',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': post_data.length,
          'Cookie': this.cookies.join("; ")
        }
      };
      req = https.request(options);
      req.write(post_data);
      return req.end();
    }, this));
  };
  Session.prototype.send = function(subdomain, flow, message) {
    var data, postMessage;
    data = {};
    data["message"] = JSON.stringify(message["content"] || message["message"]);
    data["event"] = message["event"];
    data["tags"] = (message["tags"] || []).join(" ");
    data["channel"] = "/flows/" + flow;
    ["uuid", "app"].forEach(function(key) {
      if (message[key]) {
        return data[key] = message[key];
      }
    });
    postMessage = __bind(function() {
      var options, post_data, req;
      post_data = querystring.stringify(data);
      options = {
        host: subdomain + host,
        path: '/messages',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': post_data.length,
          'Cookie': this.cookies.join("; ")
        }
      };
      req = https.request(options);
      req.write(post_data);
      return req.end();
    }, this);
    if (this.flows.filter(function(flow) {
      return flow.subdomain === subdomain && flow.name === flow;
    }).length > 0) {
      return handshake(function() {
        return postMessage();
      });
    } else {
      return postMessage();
    }
  };
  Session.prototype.chatMessage = function(subdomain, flow, message) {
    var data;
    data = {
      content: message,
      app: "chat",
      event: "message"
    };
    return this.send(subdomain, flow, data);
  };
  return Session;
})();
exports.Session = Session;