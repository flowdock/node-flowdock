# node-flowdock

Flowdock Streaming client for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock
or

    # in package.json
    "dependencies": {
      "node-flowdock": "latest"
    }

## Example usage

Flows are stringly typed. Either subdomain:flow or subdomain/flow can be used. This may change in future versions.

#### Opening and closing a stream
```javascript
var Session = require('./flowdock').Session;

var session = new Session(username, password);
var stream = session.stream('example/main');
stream.close();
```
The argument(s) for stream() can be a string ('subdomain/flow'), an array (['subdomain/flow', 'subdomain/anotherflow']) or a list of strings ('subdomain/flow', 'subdomain/anotherflow').

session.stream() returns an instance of EventEmitter. Currently it emits two types of events:

* `error` is emitted with a response status code and an error message. This can happen when a connection can't be estabilished or you don't have access to one or more flows you tried to stream.
* `message` is emitted when the `stream` receives a JSON message.

#### Listen to messages
```javascript
stream = session.stream(flow);
stream.on('message', function(message) {
  // Do stuff with message
  return stream.close();
});
```
The full message format specification for different message types is in Flowdock API Message documentation.

#### Set your status for a flow
```javascript
session.status('example:main', 'I just got the first message through the Flowdock stream API.');
```
Both arguments should be strings. Setting a status is flow specific.

#### Post a chat message to a flow
```javascript
session.message('example:main', 'Isn\'t this cool?');
```
Both arguments should be strings. Sending a message is flow specific.

#### Fetch and stream all the flows your user has an access

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
    //   flow: 'subdomain:flow',
    //   content: { last_activity: 1329310503807 },
    //   user: '12345',
    //   .. plus few other fields
    // }
  });
});
```
The full message format specification for different message types is in Flowdock API Message documentation.

## Development

You'll need ```coffee-script```, ```mocha``` and ```colors``` for development, just run ```npm install```. Code can be compiled to .js with command ```make build```.
