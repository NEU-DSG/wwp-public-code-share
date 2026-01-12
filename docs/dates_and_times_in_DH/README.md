# Dates and Times in DH
## An annotated application profile of ISO 8601:2019 for use with TEI and other DH systems

This directory holds the development copy of a technical report by Syd Bauman, including its source, ancillary files, and publishable output. As the development version, it may be in some parts incorrect, incomplete, invalid, or even (gasp!) ill-formed. On the other hand, it may have corrections and improvements over the published version.

The published version is currently available (in XHTML5 only) on the [WWP website](FIXME!!). It was sponsored by the Northeastern University [Digital Scholarship Group](https://dsg.northeastern.edu/) and has been published on the [WWP](https://www.wwp.neu.edu/) [website](FIXME!!).

Sarah Connell, Caitlin Pollack, and Karin Bredenberg provided document review and copy editing.

* [dates_and_times_in_DH.tei](dates_and_times_in_DH.tei) — The source document. If you are used to TEI, there are advantages to reading the source directly. On the other hand, the encoded temporal expression patterns are **very** hard to read in the TEI; much easier to read in the HTML.
* [dates_and_times_in_DH.xslt](dates_and_times_in_DH.xslt) — The driver XSLT file which, along with the [TEI Stylesheets](https://github.com/TEIC/Stylesheets), generates the output HTML.
* [dates_and_times_in_DH.xhtml](dates_and_times_in_DH.xhtml) — The output HTML. (Also available on the [WWP website](FIXME!!).)
* [dates_and_times_in_DH.css](dates_and_times_in_DH.css) — The custom CSS used by the HTML file. (It may be called by the HTML, or it may be copied into the HTML, depending on how the processing of the TEI is performed. In either case the default [TEI CSS](https://www.tei-c.org/release/xml/tei/stylesheet/tei.css) and common [WWP styles](https://www.wwp.neu.edu/utils/includes/styles.ssi) are also used. 
* [dates_and_times_in_DH.odd](dates_and_times_in_DH.odd) — The TEI customization ODD file that defines the schema to which dates_and_times_in_DH.tei should conform.
* [dates_and_times_in_DH.rnc](dates_and_times_in_DH.rnc) — The Relax NG (compact syntax) schema generated from dates_and_times_in_DH.odd.
* [dates_and_times_in_DH.rng](dates_and_times_in_DH.rng) — The Relax NG (XML syntax) schema generated from dates_and_times_in_DH.odd.
* [dates_and_times_in_DH.isosch](dates_and_times_in_DH.isosch) — The Schematron schema generated from dates_and_times_in_DH.odd.
* [dates_and_times_in_DH.doc.html](dates_and_times_in_DH.doc.html) — The schema documentation generated from dates_and_times_in_DH.odd.
* [dates_and_times_in_DH_regex_generator.perl](dates_and_times_in_DH_regex_generator.perl) — An experimental Perl program that generates both a regular expression for testing that a temporal expression is valid with respect to this profile, and a test suite (in either Relax NG or XSLT) for testing said regular expression.

Output for the WWP website can be generated with
~~~bash
$ saxon -xsl:./dates_and_times_in_DH.xslt -s:./dates_and_times_in_DH.tei -o:./dates_and_times_in_DH.xhtml cssInlineFiles='/ABSOLUTE/PATH/TO/dates_and_times_in_DH.css' numberBackFigures='true' showTitleAuthor='true' generationComment='true' verbose='true' footnoteBackLink='true' "?wwp=true()"
~~~
