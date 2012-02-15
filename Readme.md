# node-flowdock

Flowdock Streaming client for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock

## Example usage

    var Session, flow, session, stream;

    Session = require('./flowdock').Session;

    session = new Session(username, password);

    // Stream a single flow and respond to messages.
    flow = 'subdomain/flow';
    stream = session.stream(flow);
    stream.on('message', function(message) {

      // Set the status
      stream.status(flow, 'I just got the first message through the Flowdock stream API.');

      // Post a chat message
      stream.message(flow, 'Isn\'t this cool?');

      return stream.close();
    });

    // Fetch and stream all the flows your user can access.
    session.flows(function(flows) {
      var anotherStream, flowIds;
      flowIds = flows.map(function(f) {
        return f.id;
      });
      anotherStream = session.stream(flowIds);
      return anotherStream.on('message', function(msg) {

        console.log('message from stream:', msg);
        // variable 'msg' being something like:
        // {
        //   event: 'activity.user',
        //   flow: 'subdomain/flow',
        //   content: { last_activity: 1329310503807 },
        //   user: '12345',
        //   .. plus few other fields
        // }
        // See the full message specification @ Flowdock API Message documentation

        // Finally close the stream.
        return anotherStream.close();
      });
    });

## Development

You'll need ```coffee-script```, ```mocha``` and ```colors``` for development, just run ```npm install```. Code can be compiled to .js with command ```cake build```.
