assert = require 'assert'
BufferParser = require(__dirname + '/../src/buffer_parser')

parser = new BufferParser()
assert.deepEqual parser.parse(Buffer "\n"), []

parser = new BufferParser()
assert.deepEqual parser.parse(Buffer ""), []

parser = new BufferParser()
assert.deepEqual parser.parse(Buffer "{}\r\n"), [{}]
assert.equal(parser.buffer.length, 0)

parser = new BufferParser()
assert.deepEqual parser.parse(Buffer "{}\r\n{}\r\n"), [{}, {}]

parser = new BufferParser()
assert.deepEqual parser.parse(Buffer "{}\r\n{"), [{}]
assert.equal(parser.buffer, "{")
assert.deepEqual parser.parse(Buffer "}\r\n"), [{}]

parser = new BufferParser()
buf = Buffer( JSON.stringify({lol: 321}) + "\r\n" )
assert.deepEqual parser.parse(buf), [{lol: 321}]

parser = new BufferParser()
# JSON stringified "ä", which is delivered in two parts with \r\n in the end to have it JSON parsed
buf1 = Buffer [0x5b, 0x22, 0xc3]
assert.deepEqual parser.parse(buf1), []
buf2 = Buffer [0xa4, 0x22, 0x5d, 0x0d, 0x0a]
assert.deepEqual parser.parse(buf2), [["ä"]]

console.log "All tests OK!"
