# corpus creation and manipulation

Programs having to do with generating corpus files or manipulating them

## combine_TEIs_into_a_corpus.xslt

This program reads in **every** `*.xml` file (presumably TEI files) in
the same directory as the input file, and generates a single TEI
corpus file (that does not use `<teiCorpus>`, but rather `<TEI>`, as
the outermost element) as output.

You will need to change certain bits to get this to work nicely for your project:
* In the template named "prolog" the paths to the schemas and stylesheet need to be corrected; of course you might want to delete them instead.
* In the template named "header" lots of information will have to be added or changed. (E.g., the default header asserts that the DSG is the publisher, and gives our address.)
