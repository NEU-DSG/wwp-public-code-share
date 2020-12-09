<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
    xmlns:wf="http://www.wwp.northeastern.edu/ns/functions" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xsl wwp wf tei"
    xmlns="http://www.wwp.northeastern.edu/ns/textbase"
    xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
    version="3.0">
<!-- In the section above, there is a list of different namespaces for this XSLT script. It was 
    created to work with the Women Writers Online Corpus, can work for any TEI-based corpus. To change 
    it, simply change the "xmlns" to the namespace for tei by replacing the URL for the WWP textbase 
    to that of TEI: "http://www.tei-c.org/ns/1.0". Then, carry this change down to the next line for 
    the xpath-default-namespace as well. Replacing the namespace to the TEI from WWP will allow for 
    the XSLT to use XPATH and encoding from the TEI for the tokenizer script below. -->
    
<!--
    ELEMENT TOKENIZER
    
    Author: Laura Johnson with Ashley M. Clark, Northeastern University Women Writers Project
    See https://github.com/NEU-DSG/wwp-public-code-share/tree/main/fulltext/Element-Tokenizer-README.md
    
    This XSLT can be used to tokenize the contents of different elements in an XML document or XML 
    corpus. This XSLT was created for the Women Writers Online corpus or, specifically, for the 
    <persName> and <placeName> elements. It works by chaining transformations together, starting with 
    normalizing all spaces in the content of the declared element. The chained transformations (each 
    replacing different characters in the element contents with either nothing or, when applicable, an 
    underscore) are used to remove unneccesary punctuation and tokenize the entire element contents. 
    In the training of word embedding models using word2vec, underscores are not removed. By replacing 
    spaces and other characters (when appropriate) with underscores, the entire content of the 
    specified element are treated as a single token in the model training process. This retains the 
    information of the element as a single "unit" or token and makes it searchable and analyzable in 
    the final model. To use and adapt this XSLT, follow the commented steps below.
    
    MIT License
    
    Copyright (c) 2020 Northeastern University Women Writers Project
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  -->
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <!-- The first line in this <xsl:template> is matching the contents for the named element in the 
      parentheses. In the example below, the tokenizer is matching the content of the <persName> element. 
      To alter this XSLT, simply replace the section below with your desired elements. For example: 
      <xsl:template match="( elementName )">. To match (or tokenize) more than one element, simply use a 
      "|" character to separate the element names. For example: 
          <xsl:template match="(placeName | persName)">
      For multiple elements, make sure to close both the parentheses and quotation marks. -->
    
    <xsl:template match="(persName)">
        
        <!-- In this section, the tokenizer uses different named variables to link a series of 
          transformations together, one after another. This series of transformations regularizes 
          special characters within the element contents and replaces unnecessary characters with either 
          nothing ('') or an undescore ('_') when appropriate. For instance, the variable "asterisks" 
          replaces the special character of an asterisk "*" with nothing ('') because this special 
          character is not just unecessary, but needs to be removed to tokenize the element contents. -->
        <xsl:variable name="spaceless" select="normalize-space(.)"/>
        <xsl:variable name="asterisks" select="replace($spaceless, '\*+', '')"/>
        <xsl:variable name="one-hyphen" select="replace($asterisks, '-+', '_')"/>
        <xsl:variable name="one-em" select="replace($one-hyphen, '[—―]+', '_')"/>
        
        <!-- To declare another variable for replacing additional special characters as needed, follow 
          the following form to chain another transformation to the tokenizer. When you create another 
          variable, you will need to replace the final variable name in the sequence in the following 
          lines (more information below).
              <xsl:variable name="variable-name" select="replace($last-variable-name, 'insert-regular-expression', '_')"/>
          For example:
              <xsl:variable name="ampersand" select="replace($one-hyphen, '&+', '_')"/> -->
        
        <xsl:copy>
            <xsl:variable name="underscore" select="replace($one-em, '\s+', '_')"/>
            <xsl:value-of select="replace($underscore, '_+', '_')"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
