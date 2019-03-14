# <tagsDecl>

This directory holds routines that operate on or help with the TEI
`&lt;tagsDecl>`.

[fsrd]:
## [find_specific_renditional_defaults.xslt](./find_specific_renditional_defaults.xslt)

An XSLT 3.0 program that, given an input TEI document and a list of element names, prints out the default rendition
for each of the element names specified.

### sample commandline

The following command reads in all files in INPUTdir/ (even non-XML files, which of course generate an error message)
and writes out the default renditions for `<fw>`, `<pb>`, `<milestone>`, and `<div>`. You can specify ‘*’ as an element name to get them all.
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
* The `@scheme` attribute is ingored. This means renditional defaults are listed whether CSS (the default) or not. I think this is a good thing. But it also means the user is not told whether which scheme is being used for any particular file and selector combination. (I think this is a bad thing. Notice, e.g., that the 3rd line of sample output above is not CSS, but there is no formal indication, you just have to know by looking.)

[gtD]:
## [generate_tagsDecl.xslt](./generate_tagsDecl.xslt)
