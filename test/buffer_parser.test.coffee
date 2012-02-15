
assert = require 'assert'
BufferParser = require(__dirname + '/../src/buffer_parser')

describe 'BufferParser', () ->
  describe '.parse()', () ->
    it 'should parse a Buffer with only \\n in it', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(Buffer "\n"), []
      done()

    it 'should parse an empty Buffer', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(new Buffer(0)), []
      done()

    it 'should parse an empty String', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(""), []
      done()

    it 'should parse an empty JSON hash', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(Buffer "{}\r\n"), [{}]
      assert.equal(parser.buffer.length, 0)
      done()

    it 'should parse two empty JSON hashes', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(Buffer "{}\r\n{}\r\n"), [{}, {}]
      done()

    it 'should parse two empty JSON hashes in two buffers', (done) ->
      parser = new BufferParser()
      assert.deepEqual parser.parse(Buffer "{}\r\n{"), [{}]
      assert.equal(parser.buffer, "{")
      assert.deepEqual parser.parse(Buffer "}\r\n"), [{}]
      done()

    it 'should parse a meaningful values as a JSON hash', (done) ->
      parser = new BufferParser()
      buf = Buffer( JSON.stringify({lol: 321}) + "\r\n" )
      assert.deepEqual parser.parse(buf), [{lol: 321}]
      done()

    it 'should be able to handle partial multibyte characters correctly', (done) ->
      parser = new BufferParser()
      # JSON stringified "ä", which is delivered in two parts with \r\n in the end to have it JSON parsed
      buf1 = Buffer [0x5b, 0x22, 0xc3]
      assert.deepEqual parser.parse(buf1), []
      buf2 = Buffer [0xa4, 0x22, 0x5d, 0x0d, 0x0a]
      assert.deepEqual parser.parse(buf2), [["ä"]]
      done()
