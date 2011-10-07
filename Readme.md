# node-flowdock

Flowdock client/API for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock

## Usage

    var flowdock = require('flowdock');
    var session = new flowdock.Session(username, password);

    // Listening messages
    session.subscribe(subdomain, flow);
    session.on("message", function(message) {
      console.log(message);
    });

    // Sending chat messages
    session.chatMessage(subdomain, flow, "text")

    // Any message (although you'll have to reverse engineer the formats)
    session.send(subdomain, flow, {
      event: "message",
      content: "message",
      app: "chat",
      tags: []
    });

## Development

You'll need ```coffee-script``` for development. Code can be compiled with command ```cake build```.
