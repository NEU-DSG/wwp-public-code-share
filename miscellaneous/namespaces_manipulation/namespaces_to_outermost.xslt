<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:h="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="3.0">
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created:</xd:b> 2020-12-06 by Syd Bauman</xd:p>
      <xd:p><xd:b>Status:</xd:b> “Copyleft” 2020 by Syd Bauman and the WWP</xd:p>
      <xd:p><xd:b>Licensing:</xd:b> Available under the terms of the MIT License</xd:p>
      <xd:p><xd:b>Idea:</xd:b> I have an XML document that has 465
        top-level elements (i.e., <h:tt>/*/*</h:tt>), each of which has the exact
      same set of a dozen namespace declarations. While it is
      technically correct, it is both ugly and wasteful of disc space
      to declare each of them 465 times instead of once on the
      outermost element (i.e., on <h:tt>/*</h:tt> itself). In response, this
      routine is designed to read in an XML document and declare all
      the namespaces therein on the outermost element.</xd:p>
      <xd:p>Note that this will not always “work”, in the sense that
      if a particular namespace prefix is bound to multiple namespace
      URIs in the same document (or perhaps if a given namespace URI
      is bound to multiple prefixes), then some of the namespace
      declarations can not be “promoted” to the outermost element, and
      get left where they were.</xd:p>
      <xd:p>Note that this is at first blush very easy thing to do,
      but I suspect the easy way inefficiently generates thousands of
      namespace nodes which overwrite one another. Moreover, it just
      fails if the same namespace prefix is bound to two or more
      different namespace URIs in the input document. See the template
      <xd:ref name="demo_of_easy_unused_method"/> for the easy but
      fragile and possibly slow method. (I have compared, and the
      output is the same when it works, which is usually. I have not
      actually run them head-to-head against any significant sized
      input to see if one is really a lot slower than the
      other.)</xd:p>
      <xd:p>Instead, the method used here tries to generate only 1
      node for each existing namespace.</xd:p>
    </xd:desc>
    <xd:param name="indent">Unless set to "no", "0", or "false", the
    output will be indented per your XSLT engine’s whim.</xd:param>
  </xd:doc>

  <xsl:param name="indent" select="'yes'" static="yes"/>
  <xsl:key name="NSnodes" match="namespace-node()" use="name(.)"/>
  <xsl:output method="xml" _indent="{$indent}"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xd:doc>
    <xd:desc>Prettify output by inserting newlines in front of root-level nodes</xd:desc>
  </xd:doc>
  <xsl:template match="/comment()|/processing-instruction()">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy/>
  </xsl:template>

  <xd:doc>
    <xd:desc>Process outermost element</xd:desc>
  </xd:doc>
  <xsl:template match="/*">
    <xsl:variable name="me" select="."/>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:for-each select="//namespace-node()/name(.) => distinct-values()">
        <xsl:sort/>
        <xsl:variable name="prefix" select="."/>
        <xsl:for-each select="$me">
          <xsl:namespace name="{$prefix}" select="key('NSnodes', $prefix )[1]"/>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xd:doc>
    <xd:desc><xd:b>Not used!</xd:b> This template is here just to
    demonstrate the easy, but at least broken, if not slow inefficient
    way to do the same thing. This method fails if the same namespace
    prefix is bound to more than one different namespace URIs in the
    intput document.</xd:desc>
  </xd:doc>
  <xsl:template match="/*" priority="-100" name="demo_of_easy_unused_method">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:for-each select="//namespace-node()">
        <xsl:namespace name="{name(.)}" select="."/>
      </xsl:for-each>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
