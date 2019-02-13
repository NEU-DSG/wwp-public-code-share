<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!-- generate_tagsDecl.xslt -->
<!-- Read in a TEI P5 document and write out a <tagsDecl> element that -->
<!-- reflects its encoding. -->
<!-- Copyleft 2009 by Syd Bauman and the Women Writers Project -->
<!-- Based very heavily on James Cummings' Count-Elements.xsl at -->
<!-- http://wiki.tei-c.org/index.php/Count-Elements.xsl 2009-07-06 -->
<!-- Updated 2018-12-04 by Syd: improve how we collect <text> elements to
     examine. (We were missing those nested in teiCorpus/teiCorpus.) -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:tei="http://www.tei-c.org/ns/1.0">
  
  <xsl:output method="xml" indent="yes"/>
  
  <!-- Generate a key for element names (local). --> 
  <!-- A Perlese example of the use of this key would be-->
  <!-- $gis{emph}, which reference would return a nodeset -->
  <!-- of all the <*:emph> nodes, I think -->
  <xsl:key name="gis" use="local-name()" match="//tei:TEI/tei:text//*"/>
  <!-- Generate a key for element namespaces. --> 
  <!-- A Perlese example of the use of this key would be-->
  <!-- $nss{svg}, which reference would return a nodeset -->
  <!-- of all the namespace URIs of <*:svg> nodes, I think -->
  <xsl:key name="nss" use="namespace-uri()" match="//tei:TEI/tei:text//*"/>
  
  <xsl:template match="/">
    <!-- Since the <tagsDecl> talks about the elements "occurring within the -->
    <!-- outermost <text> element of a TEI document", we only want to match the -->
    <!-- outermost <text> element(s), i.e. children of <TEI>, regardless of -->
    <!-- how deeply nested within <teiCorpus> elements that <TEI> is. -->
    <xsl:apply-templates select="//tei:TEI/tei:text"/>
  </xsl:template>
  
  <xsl:template match="tei:text">
    <!-- generate an output tagging declaration for each input <text> -->
    <tagsDecl>
      <!-- process each node that is the first one in a set of nodes with the same namespace -->
      <xsl:for-each select="//*[generate-id(.)=generate-id(key('nss',namespace-uri(.))[1])]">
        <!-- keep sorted by said namesapce -->
        <xsl:sort select="namespace-uri()"/>
        <!-- and remember said namespace for easy reference -->
        <xsl:variable name="ns" select="namespace-uri()"/>
        <!-- output a <namespace> element in which to list the
	     elements used in this namespace -->
        <namespace name="{$ns}">
          <!-- process each node that has this namespace and is the
	       first one in the set of nodes with the same local name -->
          <xsl:for-each select="//*[namespace-uri(.)=$ns][generate-id(.)=generate-id(key('gis',local-name(.))[1])]">
            <!-- sort by the local name -->
            <xsl:sort select="local-name()"/>
            <!-- output a <tagUsage> element that gives counts for the number -->
            <!-- of similarly named descendants of <text> and number of those -->
            <!-- that are identified with xml:id=. -->
            <tagUsage gi="{local-name(.)}"
              occurs="{count( key('gis', local-name(.) ) )}"
              withId="{count( key('gis', local-name(.) )[@xml:id] )}"/>
          </xsl:for-each>
        </namespace>
      </xsl:for-each>
    </tagsDecl>
  </xsl:template>
  
</xsl:stylesheet>
