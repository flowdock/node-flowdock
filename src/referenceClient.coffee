Session = require('./flowdock').Session

session = new Session(process.env.EMAIL, process.env.PASS)

flow = process.env.FLOW
stream = session.stream flow
stream.on 'message', (message) ->
  stream.status flow, 'I just got the first message through the Flowdock stream API.'
  stream.message flow, 'Isn\'t this cool?'
  stream.close()


session.flows (flows) ->
  flowIds = flows.map((f) -> f.id)
  anotherStream = session.stream flowIds
  stream.on 'message', (message) ->
    console.log 'message from stream:', message
    anotherStream.close()
