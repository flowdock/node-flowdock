# node-flowdock [![Build Status](https://secure.travis-ci.org/flowdock/node-flowdock.png?branch=master)](http://travis-ci.org/flowdock/node-flowdock)

Flowdock Streaming client for node.js. Listen to messages from Flowdock in real-time and post new messages.

## Installation

    npm install flowdock
or

    # in package.json
    "dependencies": {
      "flowdock": "latest"
    }

## Example usage

#### Error handling

Note that `Flowdock.Session` will emit errors, and if unhandled they will crash your application. If you want to just handle errors in the callbacks, attach an empty error handler to the instance.

```javascript
var session = new Session(...);
session.on('error', function () { /* noop */ });
```

#### Credentials

The library supports authenticating using both the [API token](http://www.flowdock.com/account/tokens) or a username and password.

```
var Session = require('flowdock').Session;
// For API token auth...
var s = new Session('deadbeefacdcabbacd')

// ...or using email/password combination
var s = new Session('user@example.com', 'mypassword')
```

#### Flow IDs

Flow IDs are strings and should be considered opaque identifiers. Some older flows still have an id that looks human readable, but you should not try to parse any information from it, since it might no longer be accurate. If you need to [create URLs](https://flowdock.com/api/rest#/url-breakdown), use `flow.parameterized_name` and `flow.organization.parameterized_name`.

#### Opening and closing a stream
```javascript
var Session = require('flowdock').Session;

var session = new Session(email, password);
var stream = session.stream('6f67fd0b-b764-4661-9e53-c38293d1e997');
stream.end();
```
The argument(s) for stream() can be a string (`'6f67fd0b-b764-4661-9e53-c38293d1e997'`) or an array (`['6f67fd0b-b764-4661-9e53-c38293d1e997', 'ba0a8850-bb05-42c4-a215-16bfece679e8']`).

The second parameter can be used to add parameters to the streaming URL, meaning you can subscribe to private messages, for example. See [Flowdock Streaming API documentation](https://www.flowdock.com/api/streaming) for more information about the available parameters.

```javascript
var streamWithPrivates = session.stream('6f67fd0b-b764-4661-9e53-c38293d1e997', {user: 1, active: 'idle'});
```

session.stream() returns an instance of EventEmitter. Currently it emits two types of events:

* `error` is emitted with a response status code and an error message. This can happen when a connection can't be estabilished or you don't have access to one or more flows that you tried to stream.
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

Session has several methods to send messages to Flowdock. All methods except `status` support adding tags to the messages. You can optionally supply a callback as the last parameter, with the signature `-> (err, message, res)`, where message is the created message and res is the raw response object.

#### Post a chat message to a flow
```javascript
session.message('6f67fd0b-b764-4661-9e53-c38293d1e997', 'Isn\'t this cool?', ['tag1', 'tag2']);
```
The first two arguments should be strings. The first argument is the flow ID and the second one is the message. The third argument is an optional array of tags. Sending a message is flow-specific.

#### Post a comment to a flow
```javascript
session.comment('6f67fd0b-b764-4661-9e53-c38293d1e997', 54321, 'I\'m commenting through the api!', ['cool'])
```
The first argument is the flow ID and the second is the ID of the message being commented. The rest of the arguments work the same as with `message`.

#### Set your status for a flow
```javascript
session.status('6f67fd0b-b764-4661-9e53-c38293d1e997', 'I just got the first message through the Flowdock streaming API.');
```
Both arguments should be strings. The first argument is the flow ID and the second one is the status message. Setting a status is flow-specific.

#### Post a chat message to a private chat
```javascript
session.privateMessage(12345, 'Hi, this is a secret message!');
```
The first argument is the recipient's ID and the second one is the message.

#### Invite user to Flow
```javascript
// Note that flow and organization ids must be the "parameterized_name" from api response.
session.invite('my-flow', 'example-organization', 'email@example.com', 'Please join our flow!');
```
The first argument is flow ID, the second one is the organization ID, the third one is the invitation recipient's email address and the fourth is the custom message that is sent with the invitation.

#### Edit a message

When editing a message, you need to specify the organization, flow and message id of the edited message. You can then change the content or tags by supplying them in the data hash.

```javascript
session.editMessage(
  'my-flow',
  'example-organization',
  12345,
  {content: 'new content'},
  function (err, message, response) {
    /* do something */
  }
)
```

#### Fetch and stream all the flows your user has access to

```javascript
session.flows(function(err, flows) {
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
The full message format specification for different message types is in the [Flowdock API Message documentation](https://www.flowdock.com/api/messages).

## API usage

The Session object can be used as an API wrapper. It provides the basic HTTP request functions (GET, POST, PUT, DELETE). All functions accept the same parameters: `path`, `data` and `callback`. For example, fetching a single flow by ID:

```javascript
session.get(
  '/flows/find',
  {id: '6f67fd0b-b764-4661-9e53-c38293d1e997'},
  function (err, flow, response) {
    /* do something */
  }
);
```

Or delete a message:

```javascript
path = flow.url + "/messages/" + message.id;
session.delete(path, function (err) {
  /* do something */
});
```

## Development

Run `npm install`. Code can be compiled to .js with command `make build`.

## Changes

- v. 0.9.1 - Removed buffertools dependency and now uses event.EventEmitter instead of process.EventEmitter. (Thanks @valeriangalliat)
- v. 0.9.0 - Updated dependencies to newest versions and added api wrappers (get, post, put, delete). Node 0.6 is no longer supported.
- v. 0.8.2 - Newer buffertools to support node 0.11
- v. 0.8.1 - Errors are error objects instead of strings. Flows callback also receives error as first argument.
- v. 0.8.0 - Message callbacks conform to node standard with -> (err, body, res) signature

