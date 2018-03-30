import os
import strutils
import unittest

import nimwhistle

suite "nimwhistle unit tests":
    var websiteDir = joinPath(getCurrentDir(), "tests", "website")

    test "compress url":
        var compressedUrl = compress("http://jasonrbriggs.com/journal/2018/03/04/restarting-the-bounce-game-revisited.html")
        check compressedUrl == "http://jasonrbriggs.com/u/jbMcEA1"

    test "throws error when date pattern not found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/python-for-kids/")

    test "throws error when an unrecognised file type is found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/journal/2018/03/04/blah.blah")

    test "throws error when no matching file is found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/journal/2018/03/04/blah.html")

    test "expand url":
        var expandedUrl = expand("http://jasonrbriggs.com/u/jbMcEA1", websiteDir)
        check expandedUrl == "http://jasonrbriggs.com/journal/2018/03/04/restarting-the-bounce-game-revisited.html"

    test "throws error when no matching base dir is found":
        expect(ValueError):
            discard expand("http://jasonrbriggs.com/u/z12345", websiteDir)

    test "throws error when no matching date dir is found":
        expect(ValueError):
            discard expand("http://jasonrbriggs.com/u/jbMcESg", websiteDir)

    test "throws error when no matching file is found":
        expect(ValueError):
            discard expand("http://jasonrbriggs.com/u/jbMcEA2", websiteDir)

    test "add a fixed url":
        addFixedUrl("test/test.html", websiteDir)
        addFixedUrl("https://duckduckgo.com", websiteDir)
        check(existsFile(joinPath(websiteDir, "nimwhistle.urls")))

        var f1 = expand("http://test.test/u/f1", websiteDir)
        check f1 == "test/test.html"

        var f2 = expand("http://test.test/u/f2", websiteDir)
        check f2 == "https://duckduckgo.com"
