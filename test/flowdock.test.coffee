assert = require 'assert'
StreamParser = require(__dirname + '/../src/flowdock').StreamParser

parser = new StreamParser()
assert.deepEqual parser.parse(Buffer "\n"), []

parser = new StreamParser()
assert.deepEqual parser.parse(Buffer ""), []

parser = new StreamParser()
assert.deepEqual parser.parse(Buffer "{}\r\n"), [{}]
assert.equal(parser.buffer.length, 0)

parser = new StreamParser()
assert.deepEqual parser.parse(Buffer "{}\r\n{}\r\n"), [{}, {}]

parser = new StreamParser()
assert.deepEqual parser.parse(Buffer "{}\r\n{"), [{}]
assert.equal(parser.buffer, "{")
assert.deepEqual parser.parse(Buffer "}\r\n"), [{}]

parser = new StreamParser()
buf = Buffer( JSON.stringify({lol: 321}) + "\r\n" )
assert.deepEqual parser.parse(buf), [{lol: 321}]

console.log "All tests OK!"
