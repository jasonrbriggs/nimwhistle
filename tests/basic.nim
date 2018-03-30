import unittest

import nimwhistle

suite "description for this stuff":
    echo "suite setup: run once before the tests"

    setup:
        echo "run before each test"

    teardown:
        echo "run after each test"

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
