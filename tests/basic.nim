import os
import strutils
import unittest

import nimwhistle

suite "nimwhistle unit tests":
    var websiteDir = joinPath(getCurrentDir(), "tests", "website")

    test "compress html url":
        var compressedUrl = compress("http://jasonrbriggs.com/journal/2018/03/04/restarting-the-bounce-game-revisited.html")
        check compressedUrl == "http://jasonrbriggs.com/u/jbMcEA1"

    test "compress text url":
        echo ""

    test "compress image url":
        var compressedUrl1 = compress("http://jasonrbriggs.com/journal/2017/07/16/indentation1.png")
        var compressedUrl2 = compress("http://jasonrbriggs.com/journal/2017/07/16/indentation2.png")

        check compressedUrl1 == "http://jasonrbriggs.com/u/jpLsqq2"
        check compressedUrl2 == "http://jasonrbriggs.com/u/jpLsqq4"

    test "throws error when date pattern not found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/python-for-kids/")

    test "throws error when an unrecognised file type is found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/journal/2018/03/04/blah.blah")

    test "throws error when no matching file is found":
        expect(ValueError):
            discard compress("http://jasonrbriggs.com/journal/2018/03/04/blah.html")

    test "expand html url":
        var expandedUrl = expand("http://jasonrbriggs.com/u/jbMcEA1", websiteDir)
        check expandedUrl == "http://jasonrbriggs.com/journal/2018/03/04/restarting-the-bounce-game-revisited.html"

    test "expand image url":
        var expandedUrl1 = expand("http://jasonrbriggs.com/u/jpLsqq2", websiteDir)
        var expandedUrl2 = expand("http://jasonrbriggs.com/u/jpLsqq4", websiteDir)

        check expandedUrl1 == "http://jasonrbriggs.com/journal/2017/07/16/indentation1.png"
        check expandedUrl2 == "http://jasonrbriggs.com/journal/2017/07/16/indentation2.png"

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
