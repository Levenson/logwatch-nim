#
#

import json
import logging
import os
import times
import re
import streams

var consoleHandler = newConsoleLogger(fmtStr=verboseFmtStr)
addHandler(consoleHandler)

# var fileHandler = newRollingFileLogger(
#   "logwatch." & format(times.getLocalTime(getTime()), "yyyymdHHMM") & ".log",
#   fmtStr = verboseFmtStr
# )
# addHandler(fileHandler)

const data = joinPath("/", "home","abralek", "projects", "logwatch", "data")
var reBeginRec = re"^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d.\d\d\d-\d\d\d\d"


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
      debug("Record size:", sizeof(message_json))

      echo $message
main()
