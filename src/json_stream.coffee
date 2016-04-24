bufIndexOf = require 'buffer-indexof'
stream = require 'stream'

# Carriage-return delimited stream of JSON objects
class JSONStream extends stream.Stream
  LF = "\r\n"
  LFB = new Buffer(LF)
  constructor: ->
    @buffer = new Buffer 0
    @writable = true

  # Handle chunk, emit event for all completed chunks
  #
  # Returns true
  write: (chunk, encoding) ->
    # typecast to Buffer
    input = Buffer.isBuffer(chunk) && chunk || new Buffer(chunk, encoding)

    # concatenate input to @buffer
    @buffer = Buffer.concat [@buffer, input]

    # split the buffer from the first \r\n and leave the rest into @buffer as a new Buffer
    while ((index = bufIndexOf(@buffer, LFB)) > -1)
      ret = @buffer.slice(0, index)
      @buffer = new Buffer @buffer.slice(index + LF.length)
      @emit 'data', JSON.parse(ret.toString('utf8')) # TODO: 4-byte UTF-8 character handling
    true

  # Close writable stream, forward end event
  end: ->
    @writable = false
    @emit 'end'

module.exports = JSONStream
