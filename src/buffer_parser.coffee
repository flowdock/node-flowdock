require 'buffertools'

class BufferParser
  LF = "\r\n"
  constructor: () ->
    @buffer = new Buffer(0)

  parse: (buf) ->
    # typecast to Buffer
    input = Buffer.isBuffer(buf) && buf || new Buffer(buf)

    # concatenate input to @buffer
    @buffer = @buffer.concat input

    jsons = []
    # split the buffer from the first \r\n and leave the rest into @buffer as a new Buffer
    while ((index = @buffer.indexOf(LF)) > -1)
      ret = @buffer.slice(0, index)
      @buffer = new Buffer @buffer.slice(index + LF.length)
      jsons.push JSON.parse(ret.toString('utf8')) # TODO: use wtf8 library by lautis
    return jsons

module.exports = BufferParser
