# node-flowdock

Flowdock Streaming client for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock

## Example usage

### Opening a stream
```javascript
var Session = require('./flowdock').Session,
    flow = 'subdomain/flow',
    session = new Session(username, password),
    stream;

stream = session.stream(flow);
stream.close();
```

### Listen to messages
```javascript
stream = session.stream(flow);
stream.on('message', function(message) {
  // Do stuff with message
  return stream.close();
});
```

### Set your status for a flow
```javascript
stream.status(flow, 'I just got the first message through the Flowdock stream API.');
```

### Post a chat message to a flow
```javascript
stream.message(flow, 'Isn\'t this cool?');
```

### Fetch and stream all the flows your user has an access
```javascript
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
  });
});
```

## Development

You'll need ```coffee-script```, ```mocha``` and ```colors``` for development, just run ```npm install```. Code can be compiled to .js with command ```cake build```.
