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
      2019-10-29: Created this stylesheet from XPaths gathered during Sarah Connell's research.
    
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
  
  <!-- Override the standard fulltextBot name with a custom one. -->
  <xsl:variable name="fulltextBot" select="concat('fulltextBot-',$fulltextBotVersion,'-authorial')"/>
  <!-- The name of the phenomenon upon which we are performing changes (deleting content, etc.). -->
  <xsl:variable name="intervention-name" select="'nonauthorialParatext'"/>
  
  <!-- Delete these elements. -->
  <xsl:template
    match="div[@type = ('advert', 'contents', 'corrigenda', 'frontispiece', 'docAuthorization', 'colophon', 'index')]
         | list[@type = ('errata', 'subscriber', 'toc')]
         | titleBlock | castList | advertisement | speaker | elision | figDesc | label
           " priority="20">
    <xsl:variable name="wrapperGi" 
      select="if ( self::speaker | self::elision | self::label ) then 'ab' else 'div'"/>
    <!-- Add a wrapper element which can be tested when <note>s are moved. -->
    <xsl:element name="{$wrapperGi}">
      <xsl:attribute name="type" select="$intervention-name"/>
      <xsl:call-template name="set-provenance-attributes">
        <xsl:with-param name="subtype" select="'add-element'"/>
      </xsl:call-template>
      <xsl:apply-templates select="." mode="text2attr">
        <xsl:with-param name="intervention-type" select="$intervention-name" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>
  
  <!-- Follow the WWO author's decision when choosing to hide a child of <subst>. -->
  <xsl:template match="subst" priority="20">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Only include content which was written by the author of the current document. Deleted text, 
    however, is only removed if the WWO author has been identified as making that deletion. -->
  <xsl:template match="*[@hand] | *[@author]" priority="21">
    <xsl:variable name="attrData" select="(@hand | @author)/normalize-space()"/>
    <xsl:variable name="persRefs" select="replace(tokenize($attrData, '\s'), '^(#|p:)', '')"/>
    <xsl:variable name="wwoAuthor" 
      select="/TEI/teiHeader/fileDesc/titleStmt/author[1]/persName/@ref/substring-after(., 'p:')"/>
    <xsl:variable name="isAuthorial" select="$persRefs = $wwoAuthor"/>
    <xsl:variable name="isDeletion" select="exists(self::del)" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="($isAuthorial and not($isDeletion)) or (not($isAuthorial) and $isDeletion)">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="read-as-copy">
          <xsl:with-param name="intervention-type" select="$intervention-name" tunnel="yes"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>