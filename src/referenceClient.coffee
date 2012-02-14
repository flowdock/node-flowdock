Session = require('./flowdock').Session

session = new Session(process.env.EMAIL, process.env.PASS)

session.flows (flows) ->
  flowIds = flows.map((f) -> f.id)
  stream = session.stream flowIds
  stream.on 'message', (message) ->
    console.log 'message from stream:', message
    stream.close()
