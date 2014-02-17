# node-flowdock [![Build Status](https://secure.travis-ci.org/flowdock/node-flowdock.png?branch=master)](http://travis-ci.org/flowdock/node-flowdock)

Flowdock Streaming client for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock
or

    # in package.json
    "dependencies": {
      "node-flowdock": "latest"
    }

## Example usage

#### Credentials

Flowdock node library supports both authenticating using [api token](http://www.flowdock.com/account/tokens) or username and password.

```
var Session = require('flowdock').Session;
// For api token auth...
var s = new Session('deadbeefacdcabbacd')

// ...or using email/password combination
var s = new Session('user@example.com', 'mypassword')
```

#### Flow ids

Flow id's are strings and should be considered opaque identifiers. Some older flows still have an id that looks human readable, but you should not try to parse any information from that, since it might not be accurate anymore. If you need to [create url's](https://flowdock.com/api/rest#/url-breakdown), use `flow.parameterized_name` and `flow.organization.parameterized_name`.

#### Opening and closing a stream
```javascript
var Session = require('flowdock').Session;

var session = new Session(email, password);
var stream = session.stream('6f67fd0b-b764-4661-9e53-c38293d1e997');
stream.end();
```
The argument(s) for stream() can be a string (`'6f67fd0b-b764-4661-9e53-c38293d1e997'`) or an array (`['6f67fd0b-b764-4661-9e53-c38293d1e997', 'ba0a8850-bb05-42c4-a215-16bfece679e8']`).

The second parameter can be used to add parameters to the streaming url, so you can for example subscribe to private messages. See [Flowdock streaming api documentation](https://www.flowdock.com/api/streaming) for instructions on available parameters.

```javascript
var streamWithPrivates = session.stream('6f67fd0b-b764-4661-9e53-c38293d1e997', {user: 1, active: 'idle'});
```

session.stream() returns an instance of EventEmitter. Currently it emits two types of events:

* `error` is emitted with a response status code and an error message. This can happen when a connection can't be estabilished or you don't have access to one or more flows you tried to stream.
* `message` is emitted when the `stream` receives a JSON message.

#### Listen to messages
```javascript
stream = session.stream(flowId);
stream.on('message', function(message) {
  // Do stuff with message
  return stream.end();
});
```
The full message format specification for different message types is in [Flowdock API Message documentation](https://www.flowdock.com/api/messages).

### Sending messages

Session has several methods to send messages to Flowdock. All methods except `status` support adding tags to the messages too. You can optionally supply a callback as the last parameter, that gets the created message and the response as parameters.

#### Set your status for a flow
```javascript
session.status('6f67fd0b-b764-4661-9e53-c38293d1e997', 'I just got the first message through the Flowdock stream API.');
```
Both arguments should be strings. Setting a status is flow specific.

#### Post a chat message to a flow
```javascript
session.message('6f67fd0b-b764-4661-9e53-c38293d1e997', 'Isn\'t this cool?', ['tag1', 'tag2']);
```
Both arguments should be strings. Sending a message is flow specific. Third one is an optional array of tags.

#### Post a comment to a flow
```javascript
session.comment('6f67fd0b-b764-4661-9e53-c38293d1e997', 54321, 'I\'m commenting through the api!', ['cool'])
```
First argument is flow id, second is the id of the message being commented. Rest of the arguments work the same as with `message`.

#### Post a chat message to a private chat
```javascript
session.privateMessage(12345, 'Hi, this is a secret message!');
```
The first argument is the recipient's ID.

### Invite user to Flow
```javascript
session.invite('6f67fd0b-b764-4661-9e53-c38293d1e997', 'organizationId', 'email@example.com', 'Please join to our flow!');
```
The first argument is flow id, second is organization id, third is email where the invitation is sent and fourth is message that is sent with invitation.

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
    //   flow: '6f67fd0b-b764-4661-9e53-c38293d1e997',
    //   content: { last_activity: 1329310503807 },
    //   user: '12345',
    //   .. plus few other fields
    // }
  });
});
```
The full message format specification for different message types is in [Flowdock API Message documentation](https://www.flowdock.com/api/messages).

## Development

You'll need `coffee-script`, `mocha` and `colors` for development, just run `npm install`. Code can be compiled to .js with command `make build`.
