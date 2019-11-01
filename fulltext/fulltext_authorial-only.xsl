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


<!--  TEMPLATES  -->
  
  <!-- Wrap content in an element intended to signal non-authorial content. -->
  <xsl:template name="add-intervention-wrapper">
    <xsl:param name="content" as="node()*"/>
    <xsl:variable name="wrapperGi" 
      select="if ( self::speaker | self::elision | self::label ) then 'ab' else 'div'"/>
    <xsl:element name="{$wrapperGi}">
      <xsl:attribute name="type" select="concat($intervention-name,'Wrapper')"/>
      <xsl:call-template name="set-provenance-attributes">
        <xsl:with-param name="subtype" select="'add-element'"/>
      </xsl:call-template>
      <xsl:copy-of select="$content"/>
    </xsl:element>
  </xsl:template>


<!-- MODE: #default -->
  
  <!-- Delete the text content of these elements. -->
  <xsl:template
    match="div[@type = ('advert', 'contents', 'corrigenda', 'frontispiece', 'docAuthorization', 'colophon', 'index')]
         | list[@type = ('errata', 'subscriber', 'toc')]
         | titleBlock" priority="20">
    <xsl:call-template name="add-intervention-wrapper">
      <xsl:with-param name="content" as="node()*">
        <xsl:apply-templates select="." mode="text2attr">
          <xsl:with-param name="intervention-type" select="$intervention-name" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="castList | advertisement | speaker | elision | figDesc | label" priority="20">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:call-template name="set-provenance-attributes">
        <xsl:with-param name="subtype" select="'del-content'"/>
      </xsl:call-template>
    </xsl:copy>
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
        <xsl:call-template name="add-intervention-wrapper">
          <xsl:with-param name="content" as="node()*">
            <xsl:call-template name="read-as-copy">
              <xsl:with-param name="intervention-type" select="$intervention-name" tunnel="yes"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
<!--  MODE: unifier  -->
  
  <!-- Strip away the intervention wrapper; it's no longer necessary. -->
  <xsl:template match="ab[@type eq concat($intervention-name,'Wrapper')] 
     | div[@type eq concat($intervention-name,'Wrapper')]" mode="unifier">
    <xsl:apply-templates mode="unifier">
      <xsl:with-param name="note-to-attributes" select="true()" as="xs:boolean" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- If $move-notes-to-anchors is toggled on, copy a note after its anchor. However, if the note 
    appears inside non-authorial content, its contents are moved into attributes. -->
  <xsl:template match="*[@corresp][not(self::note)][$move-notes-to-anchors]" mode="unifier" priority="50">
    <xsl:param name="note-to-attributes" select="false()" as="xs:boolean" tunnel="yes"/>
    <xsl:variable name="note-insertion" as="node()*">
      <xsl:call-template name="insert-preprocessed-note"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
    <xsl:choose>
      <xsl:when test="$note-to-attributes">
        <xsl:apply-templates select="$note-insertion" mode="text2attr"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$note-insertion"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>