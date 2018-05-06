<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
  exclude-result-prefixes="#all"
  xmlns=""
  version="2.0">
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>This is a short XSLT stylesheet which takes an input XML file and adds its
        filepath as an entry to a collection catalog. This might be useful for 
        creating a virtual corpus of files which don't correspond exactly to a 
        single directory structure.</xd:p>
      <xd:p>Author: Ashley M. Clark, Northeastern University Women Writers Project</xd:p>
      <xd:p>Version: 0.1</xd:p>
      <xd:p>Changelog:</xd:p>
      <xd:ul>
        <xd:li>2017-11-16, v0.1: Added an &lt;xsl:if> statement which can be used to determine 
          if the current input document meets some criteria for inclusion in the catalog. 
          The default test is just `true()`. Added namespace declarations.</xd:li>
        <xd:li>2017-10-12: Created this file.</xd:li>
      </xd:ul>
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
    <!-- If the catalog did not already exist at the given filepath, output a 
      message letting us know. If the transformation scenario was set up to save 
      its output to that filepath, this message should only come up the first 
      time it runs. -->
    <xsl:if test="not(exists($catalog))">
      <xsl:message>
        <xsl:text>Could not find the catalog at </xsl:text>
        <xsl:value-of select="$catalog-filepath"/>. 
        <xsl:text>A new one should be created.</xsl:text>
      </xsl:message>
    </xsl:if>
    
    <!-- Always create a new collection catalog wrapper. -->
    <collection stable="true">
      <!-- If the catalog exists, copy its entries here. -->
      <xsl:if test="exists($catalog)">
        <xsl:copy-of select="$catalog//*:doc"/>
      </xsl:if>
      <!-- If the XPath in @test evaluates to true, the entry for the current input 
        document will be added to the collection. -->
      <xsl:if test="true()">
        <xsl:copy-of select="$docRefs"/>
      </xsl:if>
    </collection>
  </xsl:template>
  
</xsl:stylesheet>
