# language_identification

Programs having to do with “language identification”. This directory is named after [section 2.12](https://www.w3.org/TR/xml/#sec-lang-tag) of the XML Spec.

## IANA language registry in XML

The only program herein at the moment is IANA_lang_registry_in_XML.xslt. When run this program writes one or three output files, depending on the supplied `output` parameter. Each output file contains the information from the IANA registry of language subtags re-formatted to XML. The registry is the official list of language codes used as the value of `@xml:lang` (i.e., `en` for English, `de` for German, `url` for Urali).

If only one of the thrree possible outputs is requested, it is sent to STDOUT, or wherever your XSLT engine puts the main output. If all three of the outputs are requested, the output file names can be modified by a parameter, but by default the outputs are to:

 *  `/tmp/IANA_language_subtag_registry_direct.xml`: A direct 1-for-1 mapping of the registry into XML as per `fn:json-to-xml()`.

 *  `/tmp/IANA_language_subtag_registry_syntactic.xml`: The same information using element names (instead of the `@key` attribute) to differentiate fields.

 * `/tmp/IANA_language_subtag_registry_semantic.xml`: The same information in a somewhat more natural (at least, to me :-) XML structure.

Note that the program does not process the input XML in any way; since the XSLT engine requires you provide an input XML, you can choose any well-formed XML file you want. (Probably a really really huge one is not a good idea.) The input that is actually read is a version of the IANA registry that has been converted to JSON. By default the version read is the one maintained on GitHub by [Matthew Caruana Galizia](https://github.com/mattcg), to whom a big thanks. However, you can provide a different version (or a local copy of @mattcg’s) as a parameter.

### parameters

Default is listed in square brackets.

+ `input` = The URL of the input JSON document<br/>[`https://raw.githubusercontent.com/mattcg/language-subtag-registry/master/data/json/registry.json`]
+ `direct_out` = the URL of the “direct” output when `all` are requested<br/>[`/tmp/IANA_language_subtag_registry_direct.xml`]
+ `syntactic_out` = the URL of the “syntactic” output when `all` are requested<br/>[`/tmp/IANA_language_subtag_registry_syntactic.xml`]
+ `semantic_out` = the URL of the “semantic” output when `all` are requested<br/>[`/tmp/IANA_language_subtag_registry_semantic.xml`]
+ `output` = which format should be output [`all`]; note that if the parameter is a number it can be either a one-character string or an xs:integer:
    * `1` or `direct` = The registry as converted to XML by `fn:json-to-xml()`.
    * `2` or `syntactic` = The registry in XML using the same structure as in the JSON, but using more intelligent element names.
    * `3` or `semantic` = The registry in a more “XMLish” format, taking advantage of XML structure and of attributes.
    * `4` or `all` = All of the above outputs.

---

Brought to you by the [Women Writers Project](http://www.wwp.northeastern.edu/), part of the [Digital Scholarship Group](http://www.dsg.northeastern.edu/), [Northeastern University Libraries](http://library.northeastern.edu/).

© 2019 Syd Bauman and the Women Writers Project; available under the terms of the MIT License:

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
