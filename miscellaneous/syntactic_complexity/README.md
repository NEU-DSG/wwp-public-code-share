# syntactic_complexity

Programs pertaining to the task of attempting to determine how complex
an XML document is by looking at its syntax. 

## table_of_complexity_counts.xslt

This routine reads in a set of XML files and generates an XHTML table
that lists for each a set of counts and calculations of its XML
structures that might give insight to its complexity.

It was originally written for “It’s Complicated: Holistic Approaches
for Considering Complexity in XML Documents” by Sarah Connell and Syd
Bauman, presented at _Balisage_ 2026.

### usage

The program wants to know how big each input file is _before_ it is
parsed. Thus this program reads as its primary input an XML file that
lists each of the files in the input directory including its
size. This input XML file is easily generated with `xmlstarlet
ls`. The files that are read in and processed are determined by
looking for all the files selected by the `$dataSel` parameter
(default is `select=*.xml;`) that are in the same directory as the
primary input file.

So a typical invocation might look like
~~~
$ cd /path/to/directory/of/interest/
$ xmlstarlet list | xmllint --format - > /path/to/files.list && java -jar /path/to/saxon-he-MM.m.jar -xsl:/path/to/syntactic_complexity/table_of_complexity_counts.xslt -s:/path/to/files.list -o:/path/to/OUTPUT.xhtml --parserFeature?uri=http%3A//apache.org/xml/features/nonvalidating/load-external-dtd:false
~~~
* The `xmllint --format` bit is just to make the files.list file look better.
* The `--parseFeature` bit is to avoid bombing if the DTD is not
  readable. (After all, we have no need to check for validity.)

---

Brought to you by the [Women Writers Project](http://www.wwp.northeastern.edu/), part of the [Digital Scholarship Group](http://www.dsg.northeastern.edu/), [Northeastern University Libraries](http://library.northeastern.edu/).

© 2019–2024 Syd Bauman and the Women Writers Project; available under the terms of the MIT License:

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
