assert = require 'assert'
JSONStream = require(__dirname + '/../src/json_stream')

describe 'JSONStream', () ->
  parser = null
  beforeEach ->
    parser = new JSONStream()

  it 'does not emit on newline', ->
    parser.on 'data', (message) ->
      assert false, 'unexpected message was emitted'
    parser.write(Buffer '\n')

  it 'does not emit partial message', ->
    parser.on 'data', (message) ->
      assert false, parser.write(new Buffer "{")
    parser.write(Buffer '{')

  it 'emits when chunk contains JSON', ->
    messages = 0
    parser.on 'data', (message) ->
      assert.deepEqual message, {}
      messages += 1
    parser.write '{}\r\n'
    assert messages, 1, 'message was not emitted'

  it 'emits multiple messages from one chunk', ->
    messages = 0
    parser.on 'data', (message) ->
      messages += 1
    parser.write '{}\r\n{}\r\n'
    assert.equal messages, 2

  it 'should join chunks together', ->
    messages = 0
    parser.on 'data', (message) ->
      assert.deepEqual message, {}
      messages += 1
    parser.write '\n{'
    parser.write '}\r\n'
    assert.equal messages, 1, 'message was not emitted'

  it 'handles partial multibyte characters', ->
    messages = 0
    parser.on 'data', (message) ->
      assert.deepEqual message, ['ä']
      messages += 1

    # ["ä"]\r\n as UTF-8, splitted in between multibyte character
    parser.write(Buffer [0x5b, 0x22, 0xc3])
    parser.write(Buffer [0xa4, 0x22, 0x5d, 0x0d, 0x0a])
    assert.equal messages, 1, 'message was not emitted'
