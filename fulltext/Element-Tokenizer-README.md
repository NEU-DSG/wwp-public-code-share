# XML Element Tokenization for Word Embedding Models

**By Laura Johnson**

The “Element Tokenizer” is a simple XSLT that tokenizes the content of elements in XML documents. Developed to tokenize specific data for creating word embedding models using [the wordVectors R wrapper for the Women Writers Vector Toolkit](https://github.com/NEU-DSG/wwp-public-code-share/tree/master/WordVectors), this script replaces special characters (including spaces, asterisks, and hyphens) with underscores in the content of the elements specified. The wordVectors algorithm does not remove underscores when it cleans a corpus, thus allowing for content connected by underscores to be treated as single tokens in the word embedding model training process.

Tokenization is an essential and helpful process from natural language processing that is used in many forms of computational text analysis. This element tokenizer only works on XML data; meaning, it requires XML input data and generates XML output data. It is meant to be used as an additional step in the data preparation process for word embedding models and other computational processes. For scripts that transform XML data to plain text, please see the [Full Text scripts and stylesheets](https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext) created by the Women Writers Project team.

This document contains a brief overview about the Element Tokenizer including background and purpose, information about the special characters it replaces, and a short guide on how to use it. This is a working edition of this script and will be updated as it is used. If you do use it for tokenizing the contents of elements in XML documents for textual analysis and have suggestions on how to improve it, please let us know.

## Background and Purpose
The Element Tokenizer was developed for the [Women Writers Project](https://wwp.northeastern.edu) to tokenize the content of `<persName>` and `<placeName>` elements in the [Women Writers Online](https://wwp.northeastern.edu/wwo/) corpus. It is also part of the ongoing research and output for the [Women Writers Vector Toolkit](https://wwp.northeastern.edu/lab/wwvt/index.html) and the [Word Vectors for the Thoughtful Humanist Institute](https://wwp.northeastern.edu/outreach/seminars/neh_wem.html), a series of institutes sponsored by the National Endowment for the Humanities as part of their Institutes for Advanced Topics in the Digital Humanities program. This tokenizer was used to develop three tokenized versions of the WWO corpus: 1) tokenized `<persName>` elements, 2) tokenized `<placeName>` elements, 3) both tokenized `<placeName>` and `<persName>` elements. Tokenizing the content of these elements allows for person and place names with multiple words to be treated as one token. For example, the name Margaret Cavendish can be treated as one token “margaret_cavendish” instead of the two tokens “margaret” and “cavendish” as it was previously. The same applies to place names. Instead of being treated as “new” and “england,” this tool allows word embedding models to treat “new_england” as one token.

## Element Tokenizer in Practice
Following conversations with scholars learning about word embedding models and using the wordVectors script, the Element Tokenizer was developed to potentially allow for more specific queries and the creation of more specialized word embedding models. Being able to tokenize the contents of an entire element instead of individual words could allow for more specific queries and exploration of key concepts related to such things as names, subjects, places, phrases, and more.

However, the Element Tokenizer can be used in more applications than just in the training of word embedding models. Though it is relatively simple, the tokenizer works by chaining transformations and can be easily adapted and added to in order to fit the needs of a particular data-cleaning project or the characters and encoding practices of a different corpus. Combined with the other XSLT and XQUERY scripts in the WWP directory, the element tokenizer could be of interest in other textual analysis applications.

## What does the Tokenizer remove?

Developed using the content of the Women Writers Online corpus, the Element Tokenizer works by regularizing a series of special characters in a chain of transformation and replacing them with underscores. There are two distinct outcomes in this transformation. First, the tokenizer replaces spaces (and other special characters used between words) with underscores in the content of the specified elements because algorithms in natural language processing distinguish between tokens with spaces. Second, the tokenizer regulates the content of the specified element because this is not a one-for-one exchange. Instead, the tokenizer replaces multiple special characters with only one underscore. The characters that are replaced include:
+ Hyphens
+ Em Dashes
+ Asterisks
+ Spaces
+ Underscores

The tokenizer chains these transformations by declaring new variables for additional special characters in sequence. This means that the tokenizer processes all of the special characters before replacing them with underscores. These special characters were chosen specifically for the contents of the `<persName>` and `<placeName>` elements of the WWO corpus and do not include other punctuation because that either was not included or is cleaned in the model training process. However, the Element Tokenizer has been annotated and directions for writing additional lines of code for different characters are included in comments.

# Using the Element Tokenizer
The Element Tokenizer is the XSLT script `tokenizer.xq`, located in this folder. It is meant as a personal workspace and you can customize it to suit your needs and corpus. If you have cloned the wwp-public-code-share GitHub repository, it is advised that you do not change this file directly. Instead, make a copy of the tokenizer to work in. This way you can easily retrieve any future changes that we make with a simple `git pull`.

When working with (and customizing) this tokenizer, there are three components that you will want to pay close attention to:
1. the XML namespace declaration
2. the element name(s)
3. the variable name(s) for special characters

## Namespaces
Namespaces are identifiers that specify what kind of XML is being used in a document. There are different namespaces for different kinds of XML encoding schemes. For example, TEI is a flavor of XML created and managed by [the Text Encoding Initiative](https://tei-c.org/). The TEI namespace is `http://www.tei-c.org/ns/1.0`, or "tei" for short. At the top of an XSLT document, the namespace might look like the following:

    xmlns:tei="http://www.tei-c.org/ns/1.0"

Developed using Women Writers Online XML, the Element Tokenizer has the WWP namespace. This can be seen below:

    xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"

Depending on what corpus you are using, you can set the default namespace for the XSLT by changing the URL in the quotation marks for the following section:

    xmlns="http://www.wwp.northeastern.edu/ns/textbase"
    xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"

Changing from the WWP to the TEI namespace would look like this:

    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"

This might seem like a small step, but it can be very important. Certain corpora (like the WWP’s) use customized XML encoding and this affects the names of certain elements.

Essentially, in this step you are telling the XSLT, first, that the output XML should be associated with such-and-such namespace (`xmlns="http://example.org/ns"`); and second, that XPath instructions in the XSLT are, by default, associated with such-and-such namespace (`xpath-default-namespace="http://example.org/ns"`).

It is a good idea to always check namespaces. The element tokenizer utilizes the WWP namespace by default, but can be easily changed following the above steps.

## Element Names
The next section that is important to pay attention to for the Element Tokenizer is the element name. The default element name for the tokenizer is `<persName>`. To tokenize the contents of different elements, simply change the element name. For example:

`<xsl:template match="(placeName)">`

In addition, you can use the | to indicate more than one element to tokenize. For example:

`<xsl:template match="(persName | placeName | orgName)">`

Changing the element names will apply the tokenization transformation to the contents of the element in question. This tokenizer was developed for `<persName>` and `<placeName>` contents. So, if you are going to use it on other elements, it is a good idea to look at the contents of those elements to see if there are additional special characters that need to be regularized or replaced (see below). This can be done with the [WWP Counting Robot](https://github.com/NEU-DSG/wwp-public-code-share/tree/master/counting_robot) or a simple XPath for the element across the corpus.

## Declaring Additional Variables

To declare another variable to replace additional special characters as needed, follow the following form to chain another transformation to the tokenizer. When you create another variable, you will need to replace the final variable name in the sequence in the following lines:

`<xsl:variable name="variable-name" select="replace($last-variable-name, 'insert-regular-expression', '_')"/>`

For example, the following line creates a new variable named “ampersand” to replace any“&” in the element contents with an underscore.

`<xsl:variable name="ampersand" select="replace($one-hyphen, '&+', '_')"/>`

For special characters that separate words or important information in an element, replace the special characters with underscores. If the special characters are extra punctuation or would be considered a mess when the corpus is cleaned in word2vec, it is best to replace it with nothing (`''`).

Finally, the last step in adding another variable is to change the final variable name in the last two lines of the code. The final variable should always be the following line:

`<xsl:value-of select="replace($underscore, '_+', '_')"/>`

This code effectively replaces multiple underscores with just one, cleaning up any instances in the above transformations that might have resulted in replacing multiple special characters with multiple underscores.

## Setting up the Transformation
In order to run this transformation, you will need to set up a transformation scenario in [Oxygen](https://www.oxygenxml.com/). In addition, it is important to note that this XSLT takes XML input data and produces XML data as the output. The difference is that the contents of specific elements have been cleaned and tokenized. The directions below are used to create an “XML transformation with XSLT” in oXygen. These directions have been adapted from [the directions to set up XQuery transformations](https://github.com/NEU-DSG/wwp-public-code-share/blob/master/docs/setup-xquery.md) on the WWP Github.
1. Click on the button that has a wrench with a small play button symbol. Or, you can use the shortcut `Command + Shift + C` (Mac) or `Ctrl + Shift + C` (Windows).
2. Create a new transformation scenario by selecting “New”. Make sure to choose the “XML transformation with XSLT” option.
3. In the window that opens, name the transformation something to describe the process like “element-tokenizer” or “tokenizer.”
4. Select “Global Options” for storage, so that you won’t have to make this transformation scenario again for other oXygen projects.
5. In the box that reads “XSL URL” click the folder button and navigate the the location on your computer where you saved the Element Tokenizer file.
6. Click the “Output” button toward the top.
7. Make sure that the option “Save as” is selected. Click the folder button to navigate to your folder of choice.
8. Once you have the folder, type in a character to the “Save as” box. This will bring up the location address in the box. Delete the character you typed.
9. Click on the green arrow button. From the dropdown list, choose the option that reads “${cfn} current filename WITHOUT extension.”
10. Add the end of the line, add text that will distinguish that the files have been transformed. For example `.../${cfn}_tokenized` and then add the `.xml` extension to save it as an XML file.
11. Make sure the “Open in Editor” option is unchecked.
12. Hit “OK.”
13. Hit “Save and Close.”

The transformation scenario has now been saved in Oxygen and can be used to transform whatever files that you want with the Element Tokenizer. To do so, simply control- or right-click on the folder in the Project Menu in Oxygen and choose “Transform with” and choose the scenario you just created.

# Credit and Thanks
This XSLT was developed by Laura Johnson and Ash Clark as part of the “Word Vectors for the Thoughtful Humanist” series at Northeastern University. “Word Vectors for the Thoughtful Humanist” has been made possible in part by a major grant from the National Endowment for the Humanities: Exploring the human endeavor. Any views, findings, conclusions, or recommendations expressed in this project, do not necessarily represent those of the National Endowment for the Humanities.
