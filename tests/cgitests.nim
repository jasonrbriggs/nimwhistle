import os
import strutils
import unittest
import streams
import system

import nimwhistle

suite "nimwhistle cgi tests":
    var websiteDir = joinPath(getCurrentDir(), "tests", "website")

    test "cgi redirect":
        var fs = open("cgiredirect.txt", fmReadWrite)
        var oldstdout = stdout
        stdout = fs
        try:
            putEnv("REQUEST_URI", "http://jasonrbriggs.com/u/jbMcEA1")
            cgiredirect(websiteDir, "http://briggs.nz")
        finally:
            stdout = oldstdout

        setFilePos(fs, 0)
        var s = readAll(fs)
        close(fs)
        removeFile("cgiredirect.txt")

        check contains(s, "Status: 301")
        check contains(s, "Location: http://briggs.nz/journal/2018/03/04/restarting-the-bounce-game-revisited.html")