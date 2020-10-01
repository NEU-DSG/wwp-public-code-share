<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  >

  <!--
    IANA_language_registry_in_XML.xslt
    Written by Syd Bauman. See near end-of-file for change log.
    © 2019 by Syd Bauman and the Women Writers Project
    Available under the terms of the MIT License.
  -->

  <!--
      Input (to XSLT engine): does not matter, input is not read
      Input (read in): A copy of the IANA Language Subtag Registry converted to JSON.
         The default is the version maintained on GitHub by Matthew Caruana Galizia, to
         whom a big thanks. However, you can provide a different version (or a local
         copy of @mattcg’s) as a parameter.
      Output 1: The result of calling json-to-xml(), umodified
      Output 2: The same structure as #1, but use element names that reflect the input
      Output 3: The same information as #2 (and thus #1) converted to a different,
                more “semantic” XML structure.
      Parameter $input = URL of input JSON
      Parameter $direct_out = URL for storing output 1
      Parameter $syntactic_out = URL for storing output 2, 
      Parameter $semantic_out = URL for storing otuput 3
      Parameter $output:
                “direct” or 1 = put output 1 on STDOUT[^1]
                “syntactic” or 2 = put output 2 on STDOUT[^1]
                “semantic” or 3 = put output 3 on STDOUT[^1]
                “all” or 4 = write output 1 to $direct_out, and
                                   output 2 to $syntactic_out, and
                                   output 3 to $semantic_out [default]
  -->

  <!-- See also: https://www.w3.org/wiki/IANA_Language_Subtag_Registry_in_SKOS -->
  <!-- See also: https://r12a.github.io/app-subtags/ -->

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="output_base" select="'/tmp/IANA_language_subtag_registry_'"/>
  <xsl:param name="debug" select="true()" static="yes"/>
  <xsl:param name="input"
    select="'https://raw.githubusercontent.com/mattcg/language-subtag-registry/master/data/json/registry.json'"/>
  <xsl:param name="direct_out" select="$output_base||'direct.xml'"/>
  <xsl:param name="syntactic_out" select="$output_base||'syntactic.xml'"/>
  <xsl:param name="semantic_out" select="$output_base||'semantic.xml'"/>
  <xsl:param name="output" select="'all'"/>
  <xsl:variable name="outplace" as="xs:integer">
    <xsl:choose>
      <xsl:when test="$output cast as xs:string = ('1','direct')">1</xsl:when>
      <xsl:when test="$output cast as xs:string = ('2','syntactic')">2</xsl:when>
      <xsl:when test="$output cast as xs:string = ('3','semantic')">3</xsl:when>
      <xsl:when test="$output cast as xs:string = ('4','all')">4</xsl:when>
      <xsl:otherwise>
        <xsl:message>Unrecognized value of 'output' (<xsl:value-of select="$output"/>); using “all”.</xsl:message>
        <xsl:sequence select="4"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:template match="/">
    <!-- First step: get the real input file, and convert to XML: -->
    <xsl:variable name="direct" as="document-node()">
      <xsl:try select="json-to-xml( unparsed-text( $input ) )">
        <xsl:catch>
          <xsl:message terminate="yes" select="'ERROR: Cannot read input document ('||$input||')'"/>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    <!-- Process the output of the first step in "syntactic" mode to generate output 2. -->
    <xsl:variable name="syntactic" as="element()">
      <xsl:if test="$outplace gt 1">
        <xsl:apply-templates select="$direct/fn:array" mode="syntactic"/>
      </xsl:if>
    </xsl:variable>
    <!--
      If asked for output 3, then process output of mode "syntactic" in "semantic" mode
      to generate output 3.
    -->
    <xsl:variable name="semantic" as="element()?">
      <xsl:if test="$outplace gt 2">
        <xsl:apply-templates select="$syntactic" mode="semantic"/>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$outplace eq 1">
        <xsl:copy-of select="$direct"/>
      </xsl:when>
      <xsl:when test="$outplace eq 2">
        <xsl:copy-of select="$syntactic"/>
      </xsl:when>
      <xsl:when test="$outplace eq 3">
        <xsl:copy-of select="$semantic"/>
      </xsl:when>
      <xsl:when test="$outplace eq 4">
        <xsl:result-document href="{$direct_out}">
          <xsl:copy-of select="$direct"/>
        </xsl:result-document>
        <xsl:result-document href="{$syntactic_out}">
          <xsl:copy-of select="$syntactic"/>
        </xsl:result-document>
        <xsl:result-document href="{$semantic_out}">
          <xsl:copy-of select="$semantic"/>
        </xsl:result-document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">Internal error; outplace=<xsl:value-of select="$outplace"/>.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Debugging: warn about anything unmatched -->
  <xsl:template match="*|@*" mode="#all">
    <xsl:variable name="msg" select="' UNMATCHED: '||name(.)||' '"/>
    <xsl:message select="$msg"/>
    <xsl:comment select="$msg"/>
  </xsl:template>
  
  <!-- ************************** -->
  <!-- *** pass 1 = syntactic *** -->
  <!-- ************************** -->

  <!-- 
       The outermost <array> (in the XSLT functions namespace) becomes
       an outermost <language-subtag-registry> in no namespace. 
  -->
  <xsl:template match="/fn:array" mode="syntactic">
    <xsl:element name="language-subtag-registry">
      <!-- Add a timestamp -->
      <xsl:attribute name="generated" select="fn:current-dateTime()"/>
      <xsl:apply-templates mode="syntactic"/>
    </xsl:element>
  </xsl:template>
  
  <!-- 
       Each <map> becomes a <Record>, adding an @n to record its 
       position in the original list.
  -->
  <xsl:template match="fn:map" mode="syntactic">
    <xsl:element name="Record">
      <xsl:attribute name="n" select="position()"/>
      <xsl:apply-templates mode="syntactic"/>
    </xsl:element>
  </xsl:template>

  <!-- 
       Each <string> child of a <map> becomes an element whose GI
       is the value of its @key attribute.
  -->
  <xsl:template match="fn:map/fn:string[@key]" mode="syntactic">
    <xsl:element name="{@key}">
      <xsl:apply-templates mode="syntactic"/>
    </xsl:element>
  </xsl:template>

  <!--
      <array> children of a <map> are themselves dropped, but their
      children are processed.
  -->
  <xsl:template match="fn:array" mode="syntactic" name="suicide">
    <xsl:apply-templates mode="syntactic"/>
  </xsl:template>

  <!-- 
       The children of the dropped <array> each become an output
       element whose GI is the value of the <array>'s @key.
  -->
  <xsl:template match="fn:array/fn:string" mode="syntactic">
    <xsl:element name="{parent::fn:array/@key}">
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!-- ************************* -->
  <!-- *** pass 2 = semantic *** -->
  <!-- ************************* -->

  <!-- 
       Copy over the outermost <language-subtag-registry> element
       generated by the "syntactic" pass, including its timestamp.
  -->
  <xsl:template match="language-subtag-registry" mode="semantic">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="semantic">
        <!--
            This slightly complex double-sorting is designed to get letters
            to sort before digits. In truth it only gets (sub)tags that *start*
            with digits to sort after letters, but that's good enough for my
            purposes here.
        -->
        <!-- 
             first sort on any digits, numerically (lumping all values without
             any digits together at 0)
        -->
        <xsl:sort select="if ( matches( (Tag|Subtag),'^[0-9]' ) )
                          then xs:integer( replace( (Tag|Subtag), '[^0-9]','') )
                          else 0"/>
        <!--
            then sort on the string value, but force any that start with
            a digit to sort after the last alphabetical-starting record
        -->
        <xsl:sort select="replace( Tag|Subtag, '^[0-9]+','ZZZZZZ$0')" case-order="lower-first"/>
      </xsl:apply-templates>
      <!-- Whitespace that makes output look better (at least w/ my processor :-) -->
      <xsl:text>&#x0A;&#x0A;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <!--
      Each <Record> becomes an element based on the value of its child <Type>
  -->
  <xsl:template match="Record" mode="semantic">
    <!-- Whitespace that makes output look better (at least w/ my processor :-) -->
    <xsl:text>&#x0A;&#x0A;&#x20;&#x20;&#x20;</xsl:text>
    <xsl:element name="{Type}">
      <!-- 
           NOTE: the templates that match the children of <Record>
           (other than <Comments> and <Description>) must not generate
           content, as an attribute is added after them. Typically
           each should generate an attribute, but generating nothing
           or an error message would work, too.
      -->
      <xsl:apply-templates mode="semantic"
          select="child::* except ( Type, Comments, Description )"/>
      <!-- Copy over any attributes, i.e., the serial number -->
      <xsl:copy-of select="@*"/>
      <!-- Process the prose -->
      <xsl:apply-templates select="Description|Comments" mode="semantic"/>
    </xsl:element>
  </xsl:template>

  <!--
      Each child of an <Record> (except for the prose elements) becomes
      an attribute.
  -->
  <xsl:template match="Record/*" mode="semantic" priority="2">
    <xsl:attribute name="{lower-case(name(.))}" select="."/>
  </xsl:template>

  <!--
      The prose elements <Description> and <Comments> just become a
      lower-caes copy of themselves
  -->
  <xsl:template match="Description|Comments" mode="semantic" priority="3">
    <xsl:element name="{lower-case(name(.))}">
      <!-- Never anything other than text, so no need to apply templates -->
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:element>
  </xsl:template>

  <!--
      Notes
      =====
      [^1] Or wherever your XSLT engine puts the main output.
      [^2] Note that this stylesheet is written as a standard 2-pass micropipeline
           using different modes. The different modes are not strictly necessary,
           as the first pass only matches elements in the fn: namespace, and the
           second only matches things in no namespace.
      [^3] See https://github.com/mattcg/language-subtag-registry/issues/6
    -->
  
  <!-- 
    Change Log
    ====== ===
    2020-07-23: Updates by sdb:
      * Per suggestion Ash Clark, include the umodified XML returned by
        json-to-xml() as an output.
      * Add this change log.
      * Change GI for record from <Entry> to <Record>, because it is called
        a record in RFC 5646.
    2019-11-25: Updates by sdb:
       * Remove "collect all <Comments> together" code, as @mattcg has fixed the
         bug that required that hack
       * Allow for only one of the output files to STDOUT, based on a parameter.
       * Allow user to ask for one or the other or both kinds of output
       * Udpate README to match
    2019-11-14: Written by Syd Bauman (“sdb”)
  -->
</xsl:stylesheet>
