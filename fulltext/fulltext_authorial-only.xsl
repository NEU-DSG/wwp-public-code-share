<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  exclude-result-prefixes="xs xsl wwp wf"
  xmlns="http://www.wwp.northeastern.edu/ns/textbase"
  xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
  version="2.0">
  
  <!-- 
    This stylesheet customizes the behavior of the fulltextBot to remove non-authorial paratexts 
    and some other elements.
    
    Authors: Sarah Connell and Ashley M. Clark, Northeastern University Women Writers Project
    See https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
    
    Changelog:
      2019-10-29: Created this stylesheet from Sarah Connell's .
    
    MIT License
    
    Copyright (c) 2019 Northeastern University Women Writers Project
    
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
  
  <!-- The fulltextBot does most of the heavy lifting; we're just adding some custom behavior.
    IMPORTANT: make sure that the path and filename of the fulltextBot XSLT match the version you 
    want to use. -->
  <xsl:import href="fulltext.xsl"/>
  
  <xsl:output encoding="UTF-8" indent="no"/>
  <xsl:preserve-space elements="*"/>
  
  <!-- Delete these elements. -->
  <xsl:template
    match="div[@type = ('advert', 'contents', 'corrigenda', 'frontispiece', 'docAuthorization', 'colophon', 'index')]
         | list[@type = ('errata', 'subscriber', 'toc')]
         | titleBlock | castList | advertisement | speaker | elision | figDesc | label
           " priority="20"/>
  
  <!-- Only include content which was written by the author of the current document. -->
  <xsl:template match="*[@hand] | *[@author]" priority="21">
    <xsl:variable name="attrData" select="(@hand | @author)/normalize-space()"/>
    <xsl:variable name="persRefs" select="replace(tokenize($attrData, '\s'), '^(#|p:)', '')"/>
    <xsl:variable name="wwoAuthor" 
      select="/TEI/teiHeader/fileDesc/titleStmt/author[1]/persName/@ref/substring-after(., 'p:')"/>
    <xsl:if test="$persRefs = $wwoAuthor">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>