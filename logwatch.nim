#
#

import json
import logging
import os
import times
import re
import streams

import zip/zlib

var consoleHandler = newConsoleLogger(fmtStr=verboseFmtStr)
addHandler(consoleHandler)

# var fileHandler = newRollingFileLogger(
#   "logwatch." & format(times.getLocalTime(getTime()), "yyyymdHHMM") & ".log",
#   fmtStr = verboseFmtStr
# )
# addHandler(fileHandler)

const data = joinPath("/", "home","abralek", "projects", "logwatch", "data")
var reBeginRec = re"^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d.\d\d\d-\d\d\d\d"


proc compress(source: string): string =
  var
    sourcelen = source.len
    destlen = sourcelen + (sourcelen.float * 0.1).int + 16
  result = ""
  result.setLen destLen
  var res = zlib.compress(cstring(result), addr destLen, cstring(source), sourceLen)
  if res != Z_OK:
    echo "Error occurred: ", res
  elif destLen < result.len:
    result.setLen(destLen)


proc uncompress(source: string, destLen: var int): string =
  result = ""
  result.setLen destLen
  var res = zlib.uncompress(cstring(result), addr destLen, cstring(source), source.len)
  if res != Z_OK:
    echo "Error occurred: ", res


iterator readLogRecord(pathname: string): string =
  ## A Docstring
  var
    fd = newFileStream(pathname, fmRead)
    record = newStringStream()
    line = ""

  if not isNil(fd):
    while fd.readLine(line):
      if line.match(reBeginRec):
        setPosition(record, 0)
        yield record.readAll()
        record = newStringStream()
      writeLine(record, line)
    fd.close()
    record.close()


proc main() =
  ## Entry point for logwatch

  var message = %*{
    "host": {
      "hostname": "alpha",
      "TZ": "MSK"
    }
  }

  for kind, path in walkDir(data):
    debug("Processing", path)
    message["source"] = %path

    for record in readLogRecord(path):
      message["data"] = %record

      var message_json = $message
      var message_zipped = compress($message)

      debug("Record size:", message_json.len, " c:", message_zipped.len)

      # echo $message_zipped

when isMainModule:
  main()
