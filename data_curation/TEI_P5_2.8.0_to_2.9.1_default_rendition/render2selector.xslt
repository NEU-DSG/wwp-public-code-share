<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="#all"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  version="2.0">

  <!--
      render2selector.xslt
      Copyleft 2017 Syd Bauman and the Digital Scholarship Group,
      Northeastern University Libraries

      Convert TEI P5 default rendition specifications from
      tagUsage/@render format to rendition/@selector format.

      Read in a TEI P5 version 2.8.0 (or earlier) format file, and
      write out the same file with the mechanism used to indicate
      default values for @rend updated to the new (version 2.9.1 or
      later) mechnism.

      Up to version 2.8.0 the mechanism was to specify the default
      rendition in a <rendition> that was pointed at by the @render of
      a <tagUsage> whose @gi matched the name of the element whose
      default rendition is being specified. I.e., to specify that the
      default @rend of the <head> element is "align(center)", we could
      have used
      | <tagsDecl>
      |   <rendition xml:id="rend.head">align(center)</rendition>
      |   <namespace name="http://www.tei-c.org/ns/1.0">
      |     <tagUsage gi="head" render="#rend.head"/>
      |   </namespace>
      | </tagsDecl>
      For versions 2.9.1 and later we would instead say
      | <tagsDecl>
      |   <rendition selector="head">align(center)</rendition>
      | </tagsDecl>
      
      This version of the program handles multiple <namespace> elements and multiple
      <TEI> elements (in a <teiCorpus>.
  -->
  
  <xsl:key name="namespace_elements" match="/TEI/teiHeader/encodingDesc/tagsDecl/namespace" use="true()"/>
  <xsl:key name="namespace_elements" match="/teiCorpus/TEI/teiHeader/encodingDesc/tagsDecl/namespace" use="true()"/>

  <!--
    generate a sequence of <sch:ns> elements that store the prefix and associated namespace-URI
    for each declared namespace. We'd like to just get every namespace declared in the whole doc-
    ument, but that seems much harder, and might take awhile. So for now we're just picking the
    namespaces that are in force for the first <namespace> element.
  -->
  <xsl:variable name="NSs" as="element()+">
    <xsl:variable name="me" select="key('namespace_elements', true() )[1]"/>
    <xsl:for-each select="in-scope-prefixes($me)">
      <sch:ns prefix="{.}" uri="{namespace-uri-for-prefix(.,$me)}"/>
    </xsl:for-each>
  </xsl:variable>

  <!-- Identity transform: -->
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

  <!-- Nuke any <namespace> that does not have any reason to exist other than @render -->
  <xsl:template match="namespace[not(tagUage/@occurs | tagUsage/@withId | tagUsage/text()[not(normalize-space(.) eq '')])]"/>
  <!-- (And the whitespace following it) -->
  <xsl:template match="text()[ preceding-sibling::*[1][self::namespace[not(tagUage/@occurs | tagUsage/@withId | tagUsage/text()[not(normalize-space(.) eq '')])]]]"/>

  <!-- Add a @selector to <rendition> (unless it already has one) -->
  <xsl:template match="rendition[@xml:id][not(@selector)]">
    <!-- My $idrf (IDentifier ReFerence) is like my ID (which is my @xml:id after whitespace
         normalization), but it has a '#' in front, just as references to me do. -->
    <xsl:variable name="idrf" select="concat('#', normalize-space(@xml:id))"/>
    <!-- Collect all the values of @gi for all the <tagUsage> elements for elements in the
         TEI namespace that point to this <rendition> -->
    <xsl:variable name="TEI_gis" as="item()*"
      select="key('namespace_elements', true() )[normalize-space(@name) eq 'http://www.tei-c.org/ns/1.0']/tagUsage[normalize-space(@render) eq $idrf]/@gi/normalize-space()"/>
    <!-- Collect all the values of @gi for all the <tagUsage> elements for elements *not* in the
         TEI namespace that point to this <rendition> -->
    <xsl:variable name="other_gis" as="item()*">
      <xsl:for-each select="key('namespace_elements', true() )[normalize-space(@name) ne 'http://www.tei-c.org/ns/1.0']">
        <xsl:variable name="nsuri" select="normalize-space(@name)"/>
        <xsl:for-each select="tagUsage[normalize-space(@render) eq $idrf]">
          <!-- If we have a prefix for this URI, use it; if not, generate a prefix and warn user -->
          <xsl:variable name="prefix">
            <xsl:choose>
              <xsl:when test="($NSs)[@uri eq $nsuri]">
                <!-- Select the @prefix of the 1st <sch:ns> that has the right @uri (as there
                     might be more than one). -->
                <xsl:value-of select="($NSs)[@uri eq $nsuri][1]/@prefix"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="temp_prefix" select="concat('ns', parent::namespace/count( preceding::namespace ) )"/>
                <xsl:message>Warning: using prefix '<xsl:value-of
                  select="$temp_prefix"/>' for namespace URI <xsl:value-of
                  select="$nsuri"/></xsl:message>
                <xsl:value-of select="$temp_prefix"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <!-- actual syntax in CSS is prefix|gi -->
          <xsl:value-of select="concat( $prefix, '|', normalize-space( @gi ) )"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <!-- OK, now that we've collected the elements to which this default rendition
         should apply, go ahead and output this <rendition> with its new @selector -->
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Note: we do not add a @scheme attribute, as the default syntax for
           @selector *is* CSS, but specifying a @scheme of "css" implies the
           content is in CSS, and we don't know that that is the case -->
      <xsl:attribute name="selector">
        <xsl:value-of select="string-join( distinct-values( ( $TEI_gis, $other_gis ) ), ', ')"/>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="rendition[@selector]">
    <xsl:message>This &lt;rendition> (#<xsl:value-of
        select="
          if (@xml:id) then
            @xml:id
          else
            count(preceding::rendition) + 1"
      />) already has a @selector, so I'm not going to mess with it.
      (Are you sure you should be running render2selector on this file?)</xsl:message>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
