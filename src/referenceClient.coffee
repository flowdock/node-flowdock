FDSession = require('./flowdock').Session

session = new FDSession(process.env.EMAIL, process.env.PASS)
session.on 'message', (message) ->
  console.log 'client got message:', message
session.stream()
setTimeout () ->
  session.message session.flows[0].id, 'A chat message from client!'
  session.status session.flows[0].id, 'A new status!'
, 5000