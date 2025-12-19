<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>INPUT</xd:b> is the output of
        <xd:pre>svn log --xml --verbose https://liblab2.neu.edu/svn/DSG/wwp/website/trunk</xd:pre>
        or a similar command.</xd:p>
      <xd:p><xd:b>OUTPUT</xd:b> is much the same information, somewhat more readable. In
      particular, &lt;path> elements of .xhtml files are just summarized, rather than
      listed.</xd:p>
      <xd:p>Created 2025-05-10 by Syd Bauman</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output method="xml" indent="yes"/>
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xsl:template match="logentry">
    <entry rev="{@revision}" author="{author}" when="{replace( date, '\.[0-9]+Z','')}">
      <xsl:apply-templates select="* except ( author | date )"/>
    </entry>
  </xsl:template>
  
  <xsl:template match="paths">
    <xsl:variable name="me" select="."/>
    <!-- For each of the actions ('M', 'A', 'D', 'R') … -->
    <xsl:for-each select="path/@action ! string() => distinct-values()">
      <xsl:variable name="action" select="."/>
      <!-- … collect all the child <path> elements with that @action … -->
      <xsl:variable name="PATHs" as="element(path)*">
        <xsl:apply-templates select="$me/path[ @action eq $action ]">
          <xsl:sort/>
        </xsl:apply-templates>
      </xsl:variable>
      <!-- … and output them wrapped in a container. -->
      <paths action="{$action}">
        <xsl:variable name="numGen" select="count( $PATHs[ matches( ./text(),'\.xhtml$') ] )"/>
        <!-- The number of generated files, since we use the .xhtml suffix for generated files
          and .html for hand-written files. -->
        <!-- If there are any generated files, just report the number of them -->
        <xsl:if test="$numGen gt 0">
          <path count="{$numGen}">*.xhtml</path>
        </xsl:if>
        <!-- Other (non-generated) files all get reported. -->
        <xsl:sequence select="$PATHs[ not( matches( ./text(),'\.xhtml$') ) ]"/>
      </paths>
    </xsl:for-each>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>When processing a &lt;path>, copy it over except ignore some uninteresting attrs.</xd:desc>
  </xd:doc>
  <xsl:template match="path">
    <xsl:copy>
      <xsl:apply-templates select="@* except ( @prop-mods, @text-mods, @action, @kind[ . eq 'file'] )"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>When processing the <xd:i>content</xd:i> of a &lt;path>, abbreviate the path.</xd:desc>
  </xd:doc>
  <xsl:template match="path/text()">
    <xsl:sequence select="replace( ., '/wwp/website/trunk/','[WW]/')"/>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Chomp &lt;msg> text.</xd:desc>
  </xd:doc>
  <xsl:template match="msg/text()">
    <xsl:sequence select="replace( ., '&#x0A;+$','')"/>
  </xsl:template>
  
</xsl:stylesheet>
