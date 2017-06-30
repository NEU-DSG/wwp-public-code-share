<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  version="2.0">

  <!-- Copyleft 2017 Syd Bauman and the Women Writers Project -->

  <!-- identity transform template(s) -->
  <xsl:template match="node()">
    <xsl:if test="not(ancestor::*)">
      <xsl:text>&#x0A;</xsl:text>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <!-- nuke <namespace> element -->
  <xsl:template match="namespace"/>

  <!-- add new @selector to each <rendition> -->
  <xsl:template match="rendition">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Note: we do not add a @scheme attribute, as the default syntax
           for @selector *is* CSS, but specifying a @scheme of "css"
           implies the content is in CSS, which it may not be -->
      <xsl:attribute name="selector">
        <xsl:variable name="id" select="concat('#', normalize-space( @xml:id ) )"/>
        <xsl:value-of select="string-join( ../namespace/tagUsage[@render eq $id]/@gi, ', ')"/>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
