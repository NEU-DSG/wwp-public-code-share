# table_of_Unicode_codepoint_counts

Read in an XML file, write out a table of each character that appears as content in said document, sorted by frequency. The table can be re-sorted by clicking on a column header.

What is defined as “content” is controlled by a variety of parameters and depends somewhat on the markup language in which the input document is expressed. E.g., a parameter can be set to ignore metadata, but (at present) only metadata in TEI, XHTML, YAPS, and WWP documents is recognized as such and ignored.

The parameters are:

 * **UCD**, a URI: The URI of a copy of the Unicode character database in XML format. This URI is used to look up character names. The rest of the program (i.e., counting) still works even if this URI is set to garbage, but one column of the table will be useless.[[1]](#one)
 
* **debug**, a boolean: `true()` means to write debugging output files to `/tmp/`. They have names based on the input filename with `_debug_SOMETHING.xml` appended.
* **attrs**, `0`, `1`, or `9`: control which attribute values are included for counting:
  * 0: drop all attributes
  * 1: keep only pre() and post() of @rend _[default]_
  * 9: keep all attributes
* **fold**, `0`, `1`, or `2`: control whether case is significant (`T` and `t` are different characters) or not (`T` and `t` are both counted as `t`):
  * 0: no case folding _[default]_
  * 1: case folding (upper to lower, but A–Z only)
  * 2: case folding (including Greek, etc.) and also fold LATIN SMALL LETTER LONG S into LATIN SMALL LETTER S
* **skip**, `0`, `1`, `2`, `3`, or `4`: control which portions of the document are excluded prior to counting.
  * 0: process entire document, including comments and processing instructions
  * 1: process entire document excluding comments and processing instructions
  * 2: do 1, and also strip out metadata ( `<teiHeader>` or `<html:head>`)
  * 3: do 2, and also strip out printing artifacts, etc. ( `<tei:fw>`, `<wwp:mw>`, `<figDesc>`) _[default]_
  * 4: do 3, and also take `<corr>` over `<sic>`, `<expan>` over `<abbr>`, `<reg>` over `<orig>` and the first `<supplied>` or `<unclear>` in a `<choice>` (only makes sense for TEI and WWP; and for WWP this means counting the regularized version of each `<vuji>` character)
* **whitespace**, `0`, `1`, or `3`: control how whitespace characters are counted:
  * 0: strip all whitespace _[default]_
  * 1: normalize whitespace
  * 3: keep all whitespace

So, e.g., using Saxon on the bash commandline:

```bash
 $ java -jar /usr/local/bin/saxon9he.jar -xsl:table_of_Unicode_codepoint_counts.xslt -s:../PATH/TO/adams.jews.xml -o:/tmp/adams.jews.CC.html ?debug="true()" attrs=0 fold=2 skip=4 whitespace=0
```

The quotation marks around the boolean value of $debug are required to protect the parentheses from being interprted by the shell.

---

## Notes

### one

**[1]** The default $UCD is currently `https://raw.githubusercontent.com/behnam/unicode-ucdxml/master/ucd.nounihan.grouped.xml` which is a bit problematic, as that is version 6.2.0 of Unicode. (The current version is 12.1.0). If you need a newer version, or need some Unihan characters, you can point to a different copy of the Unicode database via this parameter.

I have not yet found one readily available lying around the web, i.e. available directly by URL. (If you know of one, feel free to let us know.) The ones [provided by the Unicode Consortium](https://www.unicode.org/Public/UCD/latest/ucdxml/) are ZIPped, and thus cannot be used directly by URL. But if you are using Saxon you can download a copy of the database (e.g., [the complete latest version](https://www.unicode.org/Public/UCD/latest/ucdxml/ucd.all.grouped.zip)), and point to the downloaded ZIP file using the prefix `jar:` and the suffix `/!filename`, where _filename_ is the name of the file in the ZIP archive you would like to read. In the UCD case, there is only 1 file in each archive. Thus, e.g. `UCD='jar:file:/tmp/ucd.nounihan.grouped.zip!/ucd.nounihan.grouped.xml'`. (Note that the single straight quotation marks around the parameter value protect the `!` from being interpreted as a history command by the bash shell &#x2014; your shell may vary.)

---

Brought to you by the [Women Writers
Project](http://www.wwp.northeastern.edu/), part of the [Digital
Scholarship Group](http://www.dsg.northeastern.edu/), [Northeastern
University Libraries](http://library.northeastern.edu/).

© 2019 Syd Bauman and the Women Writers Project; available under the terms of the MIT License:

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
