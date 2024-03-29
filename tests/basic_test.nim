import strutils
import unittest

import proton

proc stripWhitespace(content:string): string =
    var lines: seq[string] = @[]
    for line in splitLines(content):
        lines.add(strip(line, true, true))
    return join(lines)


proc compare(c1:string, c2:string) =
    var fc1 = open(c1)
    var sc1 = stripWhitespace(readAll(fc1))
    close(fc1)

    var fc2 = open(c2)
    var sc2 = stripWhitespace(readAll(fc2))
    close(fc2)

    assert(sc1 == sc2, "" & c1 & " is not equal to expected " & c2)
    echo "" & c2 & " is okay"


proc writeandcompare(tmp:Template, fname:string, compareto:string) =
    var f = open(fname, fmWrite)
    print(f, tmp)
    close(f)
    if compareto != "":
        compare(compareto, fname)


suite "Proton tests":
    setup:
        echo "\n"

    test "basic functionality":
        var tmp = gettemplate("../proton/resources/basic.xhtml")
        setvalue(tmp, "title", "Basic Xhtml Page")
        setvalue(tmp, "content", "Content goes here")
        setvalue(tmp, "link", "Link goes here")
        setattribute(tmp, "link", "href", "http://www.duckduckgo.com")

        var f = open("tmp/basic1.xhtml", fmWrite)
        print(f, tmp)
        close(f)
        compare("../proton/resources/basic-result.xhtml", "tmp/basic1.xhtml")

        var tmp2 = gettemplate("../proton/resources/basic.xhtml")

        var f2 = open("tmp/basic2.xhtml", fmWrite)
        print(f2, tmp2)
        close(f2)
        compare("../proton/resources/basic-unprocessed-result.xhtml", "tmp/basic2.xhtml")

    test "basic functionality - write to sequence":
        var tmp = gettemplate("../proton/resources/basic.xhtml")
        setvalue(tmp, "title", "Basic Xhtml Page")
        setvalue(tmp, "content", "Content goes here")
        setvalue(tmp, "link", "Link goes here")
        setattribute(tmp, "link", "href", "http://www.duckduckgo.com")

        var s: seq[string] = @[]
        print(s, tmp)

        var output = join(s, "")

        var f = open("tmp/basic1seq.xhtml", fmWrite)
        write(f, output)
        close(f)
        compare("../proton/resources/basic-result.xhtml", "tmp/basic1seq.xhtml")

    test "basic - append":
        var tmp = gettemplate("../proton/resources/basic-append.xhtml")

        setvalue(tmp, "title", "Append Title")
        setvalue(tmp, "content", "Append Content")

        setvalue(tmp, "head", """<meta name="description" content="append description" />""", INDEX_ALL, true)
        setvalue(tmp, "content", """<p>some additional content</p>""", INDEX_ALL, true)

        var f = open("tmp/basic-append.xhtml", fmWrite)
        print(f, tmp)
        close(f)
        compare("../proton/resources/basic-append-result.xhtml", "tmp/basic-append.xhtml")

    test "hiding 1":
        var tmp = gettemplate("../proton/resources/hiding.xhtml")
        setvalue(tmp, "title", "Hiding Xhtml Page")
        hide(tmp, "hidden-element")

        writeandcompare(tmp, "tmp/hiding.xhtml", "../proton/resources/hiding-result.xhtml")

    test "hiding 2":
        var tmp = gettemplate("../proton/resources/hiding2.xhtml")
        setvalue(tmp, "title", "Navigation Example")
        hide(tmp, "autopayments")
        hide(tmp, "exchange")
        hide(tmp,"transactions")

        writeandcompare(tmp, "tmp/hiding2.xhtml", "../proton/resources/hiding-result2.xhtml")

    test "hiding 3":
        var tmp = gettemplate("../proton/resources/hiding3.xhtml")
        setvalue(tmp, "title", "Hiding Xhtml Page")

        var tmp2 = gettemplate("../proton/resources/hiding-include.xhtml")

        replace(tmp, "replaced-element", tmp2)

        setvalue(tmp, "not-hidden", "Not hidden content")
        hide(tmp, "hidden-element")

        writeandcompare(tmp, "tmp/hiding3.xhtml", "../proton/resources/hiding-result3.xhtml")

    test "replace with html content":
        var tmp = gettemplate("../proton/resources/basic.xhtml")
        replaceHtml(tmp, "content", "<p>test</p>")

        writeandcompare(tmp, "tmp/basic-replace-html.xhtml", "../proton/resources/basic-replace-html-result.xhtml")

    test "repeat 1":
        var tmp = gettemplate("../proton/resources/repeat.xhtml")

        setvalue(tmp, "title", "Repeating Xhtml Page")
        setattribute(tmp, "link", "href", "http://www.duckduckgo.com")
        setvalue(tmp, "link", "This is a link to DuckDuckGo")
        repeat(tmp, "list-item", 5)

        var x = 0
        while x < 5:
            setvalue(tmp, "list-item", "test" & x.`$`, indexof(x))
            x += 1

        writeandcompare(tmp, "tmp/repeat.xhtml", "../proton/resources/repeat-result.xhtml")

    test "repeat 2":
        var tmp = gettemplate("../proton/resources/repeat2.xhtml")

        repeat(tmp, "posts", 5)

        writeandcompare(tmp, "tmp/repeat2.xhtml", "../proton/resources/repeat-result2.xhtml")

    test "replace with html content 1":
        var tmp = gettemplate("../proton/resources/repeat3.xhtml")
        repeat(tmp, "posts", 3)
        replaceHtml(tmp, "post-content", "<p>test1</p>")

        writeandcompare(tmp, "tmp/repeat3-1.xhtml", "../proton/resources/repeat3-1-result.xhtml")

    test "replace with html content 2":
        var tmp = gettemplate("../proton/resources/repeat3.xhtml")
        repeat(tmp, "posts", 3)
        replaceHtml(tmp, "post-content", "<p>test1</p>", indexof(0))
        replaceHtml(tmp, "post-content", "<p>test2</p>", indexof(1))
        replaceHtml(tmp, "post-content", "<p>test3</p>", indexof(2))

        writeandcompare(tmp, "tmp/repeat3-2.xhtml", "../proton/resources/repeat3-2-result.xhtml")

    test "append html content":
        var tmp = gettemplate("../proton/resources/basic-append.xhtml")

        tmp.setvalue("title", "Append Title")
        tmp.setvalue("content", "Append Content")

        tmp.appendHtml("head", "<meta name=\"description\" content=\"append description\" />")
        tmp.appendHtml("content", "<p>some additional content</p>")

        writeandcompare(tmp, "tmp/basic-append.xhtml", "../proton/resources/basic-append-result.xhtml")

    test "prepend html content":
        var tmp = gettemplate("../proton/resources/basic-append.xhtml")

        tmp.setvalue("title", "Append Title")
        tmp.setvalue("content", "Append Content")

        tmp.prependHtml("head", "<meta name=\"description\" content=\"append description\" />")
        tmp.prependHtml("content", "<p>some additional content</p>")

        writeandcompare(tmp, "tmp/basic-prepend.xhtml", "../proton/resources/basic-prepend-result.xhtml")

    test "replace and append content":
        var tmp = gettemplate("../proton/resources/replace-append.xhtml")
        var replace_content = gettemplate("../proton/resources/replace-append-content.xhtml")
        replace(tmp, "head", replace_content, INDEX_ALL, true)

        writeandcompare(tmp, "tmp/replace-append.xhtml", "../proton/resources/replace-append-result.xhtml")