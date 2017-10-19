<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  exclude-result-prefixes="xs math"
  version="2.0">
  
  <xd:doc>
    <xd:desc>
      <xd:p>This is a short XSLT stylesheet which takes an input XML file and adds its
        filepath as an entry to a collection catalog. This might be useful for 
        creating a virtual corpus of files which don't correspond exactly to a 
        single directory structure.</xd:p>
      <xd:p>Author: Ashley M. Clark</xd:p>
    </xd:desc>
    <xd:param name="catalog-filepath">A required parameter containing the filepath for 
      a collection catalog. The catalog file does not have to exist, but should 
      after the first pass.</xd:param>
  </xd:doc>
  
  <xsl:output indent="yes"/>
  <xsl:param name="catalog-filepath" as="xs:anyURI" required="yes"/>
  
  <!-- If the catalog file already exists, a copy of it will be placed in this 
    global variable. -->
  <xsl:variable name="catalog" as="node()?">
    <xsl:if test="doc-available($catalog-filepath)">
      <xsl:copy-of select="doc($catalog-filepath)"/>
    </xsl:if>
  </xsl:variable>
  
  <xd:doc>
    <xd:desc>
      <xd:p>Create a new &lt;collection&gt; wrapper and an entry for the input 
        document. If the catalog file already exists, its entries are copied in as 
        well.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <!-- The entry for this input document. -->
    <xsl:variable name="docRefs" as="node()+">
      <doc href="{ base-uri() }"/>
    </xsl:variable>
    <!-- Create a new collection catalog wrapper. -->
    <collection stable="true">
      <xsl:choose>
        <!-- If the catalog exists, copy its entries here. -->
        <xsl:when test="exists($catalog)">
          <xsl:copy-of select="$catalog//doc"/>
        </xsl:when>
        <!-- If the catalog did not already exist at the given filepath, output a 
          message letting us know. If the transformation scenario was set up to save 
          its output to that filepath, this message should only come up the first 
          time it runs. -->
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
