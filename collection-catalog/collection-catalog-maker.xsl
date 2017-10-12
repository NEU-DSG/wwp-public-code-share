<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  exclude-result-prefixes="xs math"
  version="2.0">
  
  <xsl:param name="catalog-filepath" as="xs:anyURI" required="yes"/>
  
  <xsl:variable name="catalog" as="node()?">
    <xsl:if test="doc-available($catalog-filepath)">
      <xsl:copy-of select="doc($catalog-filepath)"/>
    </xsl:if>
  </xsl:variable>
  
  <xsl:output indent="yes"/>
  
  <xsl:template match="/">
    <xsl:variable name="docRefs" as="node()+">
      <doc href="{ base-uri() }"/>
    </xsl:variable>
    
    <collection stable="true">
      <xsl:choose>
        <xsl:when test="exists($catalog)">
          <xsl:copy-of select="$catalog//doc"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>Could not find the catalog at 
            <xsl:value-of select="$catalog-filepath"/>. 
            A new one should be created.</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:copy-of select="$docRefs"/>
    </collection>
  </xsl:template>
  
</xsl:stylesheet>
