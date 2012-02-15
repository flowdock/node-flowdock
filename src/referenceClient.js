(function() {
  var Session, flow, session, stream;

  Session = require('./flowdock').Session;

  session = new Session(process.env.EMAIL, process.env.PASS);

  flow = process.env.FLOW;

  stream = session.stream(flow);

  stream.on('message', function(message) {
    stream.status(flow, 'I just got the first message through the Flowdock stream API.');
    stream.message(flow, 'Isn\'t this cool?');
    return stream.close();
  });

  session.flows(function(flows) {
    var anotherStream, flowIds;
    flowIds = flows.map(function(f) {
      return f.id;
    });
    anotherStream = session.stream(flowIds);
    return stream.on('message', function(message) {
      console.log('message from stream:', message);
      return anotherStream.close();
    });
  });

}).call(this);
