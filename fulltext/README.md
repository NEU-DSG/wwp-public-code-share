# Full Text

This directory contains scripts and stylesheets which aid in creating plaintext from XML. Because TEI layers meaning onto documents' textual content, TEI files can be used to make informed selections of content significant for research, analysis, and various other purposes.


## Tools

### The XSLT

The XSLT stylesheet `fulltext.xsl` takes a single document encoded according to the conventions of the Women Writers Project (based on the conventions of TEI). The XML is modified such that, within the main content, most serializers could extract plaintext from the document’s text nodes.

### The XQueries

The XQuery scripts `fulltext2table` are used to extract plaintext from XML text nodes in the simplest possible manner. These scripts were designed for the XML output of `fulltext.xsl`.
