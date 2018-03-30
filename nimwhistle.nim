import cgi
import encodings
import httpclient
import htmlparser
import os
import ospaths
import re
import sequtils
import strutils
import system
import tables
import xmltree
import strformat
import strtabs
import typetraits
import uri
import algorithm

import docopt

let doc = """
nimwhistle. Algorithmic url shortener based on the ideas in Whistle with some additional enhancements (http://tantek.pbworks.com/w/page/21743973/Whistle)

Usage:
  nimwhistle a <url> <htdocs>
  nimwhistle c <url>
  nimwhistle x <url> <htdocs>
  nimwhistle cgi <htdocs>

Commands:
    a           Add a URL to a file (used for f1..x shortened URLs. e.g. /u/f10)
    c           Compress a URL
    x           Expand a shortened URL
    cgi         CGI-based URL expansion

Options:
  -h --help     Show this screen.
  --version     Show version
"""

const CHARACTERS = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz"
var numbers = initTable[char, int]()

var i = 0
for x in CHARACTERS:
    numbers[x] = i
    i += 1

numbers['l'] = 1 # typo lowercase l to 1
numbers['I'] = 1 # typo capital I to 1
numbers['O'] = 0 # typo capital O to 0


var datePattern = re"[0-9]{4}/[0-9]{2}/[0-9]{2}"


proc numtosxg(n:int64):string =
    var s = ""
    var n0 = n
    var n1 = n
    while n1 > 0:
        n1 = n0 div 60
        var i = cast[int](n0 mod 60)
        n0 = n1
        s = CHARACTERS[i] & s
    return s


proc sxgtonum(s:string):int =
    var n = 0
    for c in s:
        n = n * 60 + getOrDefault(numbers, c)
    return n


proc hasalttxt(node:XmlNode):bool =
    var imgs = findAll(node, "img")
    for img in imgs:
        if img.attrs != nil and hasKey(img.attrs, "alt") and img.attrs["alt"] == "[TXT]":
            return true
    return false


proc dateasnum(url:string):int =
    var (first, last) = findBounds(url, datePattern)
    var date = substr(url, first, last)
    date = replace(date, "/", "")
    return parseInt(date)


proc ftype(fname:string):string =
    if endsWith(fname, ".html") or endsWith(fname, ".htm"):
        return "b"
    elif endsWith(fname, ".text") or endsWith(fname, ".txt"):
        return "t"
    return "";


proc addFixedUrl*(url:string, basedir:string) =
    var fname = joinPath(basedir, "nimwhistle.urls")
    var f = open(fname, fmAppend)
    var line: array[2000, char]
    var i = 0
    for c in url:
        line[i] = c
        i += 1
    line[1999] = '\n'
    discard writeChars(f, line, 0, 2000)
    close(f)


proc compress*(url:string):string =
    var u = parseUri(url)
    var client = newHttpClient()
    var dirpath = substr(u.path, 0, rfind(u.path, "/"))
    var filename = substr(u.path, rfind(u.path, "/") + 1)
    var date = dateasnum(dirpath)
    if date == 0:
        raise newException(ValueError, "No date pattern found in " & dirpath)

    let firstchar = substr(u.path, 1, 1)
    let ft = ftype(filename)

    if ft == "":
        raise newException(ValueError, "Unsupported file type " & filename)

    var html = client.getContent(u.scheme & "://" & u.hostname & dirpath & "?C=M;O=A")
    var doc = parseHtml(html)
    var idx = 1
    var actualidx = -1
    for tr in doc.findAll("tr"):
        if hasalttxt(tr):
            var anchors = tr.findAll("a")
            for anchor in anchors:
                if anchor.attrs != nil and hasKey(anchor.attrs, "href"):
                    var href = anchor.attrs["href"]
                    if href == filename:
                        actualidx = idx
                        break
                    if ftype(href) == ft:
                        idx += 1

    if actualidx < 0:
        raise newException(ValueError, "Unable to find match for " & filename & " in " & dirpath)

    let sxg = numtosxg(((date - 19900101) * 1000) + actualidx)

    return u.scheme & "://" & u.hostname & "/u/" & firstchar & ft & sxg


proc slen(url:string):int =
    var i = 0
    for c in url:
        if c != '\0':
            i += 1
        else:
            break
    return i


proc expandFixed(num:string, basedir:string):string =
    var idx = parseInt(num) - 1
    var pos = idx * 2000

    var fname = joinPath(basedir, "nimwhistle.urls")
    var f = open(fname, fmRead)
    setFilePos(f, pos)
    var url = readLine(f)
    var l = slen(url)
    var rtn = newStringOfCap(l)
    for c in url:
        if c != '\0':
            rtn.add(c)
        else:
            break
    return rtn


proc expand*(url:string, basedir:string):string =
    var u = parseUri(url)
    if not startsWith(u.path, "/u/"):
        raise newException(ValueError, "Unrecognised url path '" & u.path & "'")

    var firstchar = substr(u.path, 3, 3)
    if firstchar == "f":
        return expandFixed(substr(u.path, 4), basedir)

    var typechar = substr(u.path, 4, 4)
    var sxg = substr(u.path, 5)

    setCurrentDir(basedir)
    var dirs:seq[string] = @[]
    for d in walkDirs("*"):
        dirs.add(d)
    sort(dirs, system.cmp)

    var dir = ""
    for d in dirs:
        if startsWith(d, firstchar):
            dir = d
            break

    if dir == "":
        raise newException(ValueError, "Can't find directory matching char '" & firstchar & "'")

    var num = sxgtonum(sxg) + 19900101000
    var snum = num.`$`

    var idx = parseInt(substr(snum, 8))

    var path = dir & "/" & substr(snum, 0, 3) & "/" & substr(snum, 4, 5) & "/" & substr(snum, 6, 7)
    if not existsDir(path):
        raise newException(ValueError, "Path not found " & path)

    var filename = ""
    var newdir = joinPath(basedir, path)
    setCurrentDir(newdir)
    var i = 0
    for f in walkFiles("*"):
        if ftype(f) == typechar:
            i += 1
            if i == idx:
                filename = f

    if filename == "":
        raise newException(ValueError, "Unable to find a matching file in " & path & " (idx:" & idx.`$` & ")")

    var rtn = ""
    if u.scheme != nil and u.scheme != "":
        rtn &= u.scheme & "://" & u.hostname

    rtn &= "/" & path & "/" & filename

    return rtn


if isMainModule:
    let args = docopt(doc, version = "0.1")

    if args["a"]:
        var url = $args["<url>"]
        var basedir = $args["<htdocs>"]

        addFixedUrl(url, basedir)

    elif args["c"]:
        try:
            var url = $args["<url>"]
            echo compress(url)
        except:
            echo getCurrentExceptionMsg()
            quit(1)
    elif args["x"]:
        try:
            var url = $args["<url>"]
            var basedir = $args["<htdocs>"]
            echo expand(url, basedir)
        except:
            echo getCurrentExceptionMsg()
            quit(1)
    elif args["cgi"]:
        try:
            var htdocs = $args["<htdocs>"]
            var uri = getRequestURI()
            var expandedUri = expand(uri, htdocs)

            writeLine(stdout, "Status: 301 Moved Permanently")
            writeLine(stdout, "Location: " & expandedUri)
            writeContentType()
            writeLine(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">")
            writeLine(stdout, "<html><body>" & expandedUri & "<body></html>")
        except:
            var msg = getCurrentExceptionMsg()
            writeLine(stdout, "Status: 404 Not found")
            writeContentType()
            writeLine(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">")
            writeLine(stdout, "<html><body>")
            writeLine(stdout, "Unable to redirect. " & msg)
            writeLine(stdout, "<body></html>")

