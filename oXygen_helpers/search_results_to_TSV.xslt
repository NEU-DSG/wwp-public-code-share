<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.oxygenxml.com/ns/report"
  version="2.0">
  
  <xsl:output method="text"/>
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>search_results_to_TSV.xslt</xd:p>
      <xd:p>Read in the saved results of an oXygen search, write out
      the same in TSV format for easy ingestion into a spreadsheet program.</xd:p>
      <xd:p><xd:b>written:</xd:b> 2018-02-05</xd:p>
      <xd:p><xd:b>by:</xd:b> Syd Bauman</xd:p>
      <xd:p><xd:b>copyleft 2018</xd:b> Syd Bauman and Northeastern University</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xd:doc>
    <xd:desc>number of significant digits — pattern for format number that has
    the same number of 0s as the number of incidents.</xd:desc>
  </xd:doc>
  <xsl:variable name="nsd_incidents" select="translate( count( /report/incident ) cast as xs:string, '123456789','000000000')"/>
  <xsl:variable name="nsd_lineNums"  select="translate( max( /report/incident/location/*/line/xs:integer(.) ) cast as xs:string, '123456789','000000000')"/>
  
  <xd:doc>
    <xd:desc>When we find the root report element, <xd:ol>
      <xd:li>generate a copy of it (in $report) that has been decorated with
      a @pos attribute on each incident element that gives its sequential
      position. (This is the "addSeq" mode.)</xd:li>
      <xd:li>output a header row with field names separated by tabs</xd:li>
      <xd:li>process all the incidents listed in $report (sorted by description)</xd:li>
    </xd:ol>
    </xd:desc>
  </xd:doc>
  <xsl:template match="/report">
    <xsl:variable name="report">
      <xsl:apply-templates select="." mode="addSeq"/>
    </xsl:variable>
    <xsl:call-template name="hdrRow"/>
    <xsl:apply-templates select="$report//incident">
      <xsl:sort select="normalize-space( ./description )"/> 
    </xsl:apply-templates>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>generate a header row for our TSV document: field
    names separated by horizontal tab characters.</xd:desc>
  </xd:doc>
  <xsl:template name="hdrRow">
    <xsl:text>seq&#x09;desc&#x09;file path&#x09;file name&#x09;start line&#x09;start col&#x09;end line&#x09;end col&#x09;XPath</xsl:text>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>In first pass (mode addSeq) most everything just gets copied.</xd:desc>
  </xd:doc>
  <xsl:template match="@*|node()" mode="addSeq">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  <xd:doc>
    <xd:desc>The exception in the first pass (mode addSeq) is that incident elements
    get decorated with a new @pos attribute that gives their ordinal number within
    the input file.</xd:desc>
  </xd:doc>
  <xsl:template match="incident" mode="addSeq">
    <xsl:copy>
      <xsl:attribute name="pos" select="count( preceding-sibling::incident ) + 1"/>
      <xsl:apply-templates select="@*|node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>When we process an incident, generate an output row for it:
    fields of interest separated by tabs.</xd:desc>
  </xd:doc>
  <xsl:template match="incident">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:value-of select="format-number( @pos, $nsd_incidents )"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="normalize-space(description)"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="replace( systemID, '^(.*)/[^/]+$','$1')"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="tokenize( base-uri(/),'/')[last()]"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="if ( location/start/line castable as xs:integer ) then format-number( location/start/line, $nsd_lineNums ) else ''"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="location/start/col"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="if ( location/end/line castable as xs:integer ) then format-number( location/end/line, $nsd_lineNums ) else ''"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="location/end/col"/>
    <xsl:text>&#x09;</xsl:text>
    <xsl:value-of select="replace( xpath_location,'^(/[A-Za-z0-9.:_-]+)\[1\]','$1')"/>
  </xsl:template>

</xsl:stylesheet>
