
# &lt;tagsDecl>

This directory holds routines that operate on or help with the TEI `<tagsDecl>`.

## Table of Contents
* [find specific renditional defaults](#find_specific_renditional_defaultsxslt)
* [generate tagsDecl](#generate_tagsDeclxslt)
* [replace tagsDecl](#replace_tagsDeclxslt)
* [generate a regexp to validate `@selector`](#CSS3_selector_regex_generatorperl)

## [find_specific_renditional_defaults.xslt](./find_specific_renditional_defaults.xslt)

An XSLT 3.0 program that, given an input TEI document and a list of element names, prints out the default rendition
for each of the element names specified.

### sample commandline

The following command reads in all files in INPUTdir/ (even non-XML files, which of course generate an error message)
and writes out the default renditions for `<fw>`, `<pb>`, `<milestone>`, and `<div>`. You can specify `*` as an element name to get them all.
```bash
`$ java -jar /path/to/saxon9he.jar -xsl:https://raw.githubusercontent.com/NEU-DSG/wwp-public-code-share/master/tagsDecl/find_specific_renditional_defaults.xslt -s:INPUTdir/ -o:/tmp/OUTPUTdir/ '?GIs=("fw","pb","milestone","div")'`
```
Note that the useful output is sent to the message area; the actual output files in /tmp/OUTPUTdir/ can be summarily discarded.

### sample output

```
---------working_files/pniraqvfu.yrggref.xml | selector=persName | font-style: italic; 
---------working_files/cvk.fcnavfujvirf.xml | selector=persName | font-style: italic; 
---------working_files/pnyypbgg.yrggref.xml | selector=div | pre(#rule) 
---------working_files/unljbbq.ybir03.xml | selector=persName | font-variant: small-caps; 
---------working_files/qnivrf.frpbaqpbzvat.xml | selector=hi | font-style: italic; 
---------working_files/qnivrf.frpbaqpbzvat.xml | selector=persName | font-style: italic; 
---------working_files/qnivrf.frpbaqpbzvat.xml | selector=name | font-style: italic; 
---------working_files/qnivrf.nccrny1649.xml | selector=hi | font-style: normal; 
---------working_files/qnivrf.nccrny1649.xml | selector=persName | font-style: normal; 
---------working_files/sntr.snzr.xml | selector=persName | font-style: italic; 
---------working_files/sntr.snzr.xml | selector=hi | font-style: italic; 
---------working_files/craavatgba.hasbeghangr.xml | selector=hi | font-style: italic; 
---------working_files/qnivrf.wryrgvra.xml | selector=persName | font-style: italic; 
---------working_files/qnivrf.wryrgvra.xml | selector=name | font-style: italic; 
---------working_files/qnivrf.wryrgvra.xml | selector=hi | font-style: italic; 
```
* Which element names to search for is specified by the `$GIs` parameter.
* The output goes to STDERR, not STDOUT.
* The `@scheme` attribute is ingored. This means renditional defaults are listed whether CSS (the default) or not. I think this is a good thing. But it also means the user is not told which scheme is being used for any particular file and selector combination. (I think this is a bad thing. Notice, e.g., that the 3rd line of sample output above is not CSS, but there is no formal indication, you just have to know by looking.)

## [generate_tagsDecl.xslt](./generate_tagsDecl.xslt)

This is an XSLT 1.0 program that reads in a TEI P5 document and writes
out a complete `&lt;tagsDecl>` element that reflects its encoding.
(The `&lt;tagUsage>` elements are sorted by each element’s local name.)

While there may still be some uses for this program, it has generally
been superceded by [replace tagsDecl](#replace_tagsDeclxslt).

This program does NOT add an `&lt;application>` notification in the `&lt;teiHeader>`.

## [replace_tagsDecl.xslt](./replace_tagsDecl.xslt)

This is an XSLT 3.0 program that reads in a TEI P5 document and writes
out the same document with the entire `&lt;tagsDecl>` overwritten by a
new one.
(The `&lt;tagUsage>` elements are sorted by number of occurences.)

This means that if the input document does not have a `&lt;tagsDecl>`
at all, this program is little more than a very expensive no-op. (So
you might want to add an empty `&lt;tagsDecl>` by hand before you run
this for the first time on a particular file.)

Unlike [generate_tagsDecl.xslt](./generate_tagsDecl.xslt) this program
was _not_ written with speed in mind. Nonetheless, it runs quite
quickly (3⅔ s on the largest WWP file we have, 3.0 MiB).

This program adds a proper `&lt;application>` notification in the `&lt;teiHeader>`.

## [CSS3_selector_regex_generator.perl](./CSS3_selector_regex_generator.perl)

This is a Perl program that generates a regular expression which can be used in your ODD file to validate that the value of an attribute (in particular, the `@selector` attribute of `<rendition>`) is proper CSS3.

It also generates a RELAX NG grammar (or an XSLT program) that can be used to test the regular expression.

Just run the Perl program. It takes no parameters nor input. It writes the regular expression alone to STDERR and as part of a self-testing RELAX NG grammer to STDOUT. Thus a typical invocation might be `CSS3_selector_regex_generator.perl 2> ~/Documents/selector_regex.txt > /tmp/test_selector_regex.rng`.
