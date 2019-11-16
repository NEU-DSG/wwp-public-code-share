<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  >

  <!--
    IANA_language_registry_in_XML.xslt
    Written 2019-11-14 by Syd Bauman
    © 2019 by Syd Bauman and the Women Writers Project
    Available under the terms of the MIT License.
  -->

  <!--
      Input (to XSLT engine): does not matter, input is not read
      Input (read in): A copy of the IANA Language Subtag Registry converted to JSON.
         The default is the version maintained on GitHub by Matthew Caruana Galizia, to
         whom a big thanks. However, you can provide a different version (or a local
         copy of @mattcg’s) as a parameter.
      Output 1: The information from the input JSON converted to XML in a direct 1-to-1
         manner.
      Output 2: The information from output 1 converted to a different, more “semantic”
         XML structure.
      Parameter $input = URL of input JSON
      Parameter $direct_out = URL for storing output 1
      Parameter $xmlified_out = URL for storing otuput 2

      In a future version I expect to give the user a choice of which
      output to generate via a parameter; the chosen output will go to
      STDOUT, the other will not be generated.

      Note that this stylesheet is written as a standard 2-pass micropipeline
      using different modes. The different modes are not strictly necessary,
      as the first pass only matches elements in the fn: namespace, and the
      second only matches things in no namespace.
  -->

  <!-- See also: https://www.w3.org/wiki/IANA_Language_Subtag_Registry_in_SKOS -->
  <!-- See also: https://r12a.github.io/app-subtags/ -->

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="input"
             select="'https://raw.githubusercontent.com/mattcg/language-subtag-registry/master/data/json/registry.json'"/>
  <xsl:param name="direct_out"
             select="'/tmp/IANA_language_subtag_registry_syntactic.xml'"/>
  <xsl:param name="xmlified_out"
             select="'/tmp/IANA_language_subtag_registry_semantic.xml'"/>
  
  <xsl:template match="/">
    <!-- First step: get the real input file, and convert to XML: -->
    <xsl:try select="doc-available( $input )">
      <xsl:catch>
        <xsl:message terminate="yes"
                     select="'ERROR: Cannot read input document ('||$input||')'"/>
      </xsl:catch>
    </xsl:try>
    <xsl:variable name="original" select="json-to-xml( unparsed-text( $input ) )"/>
    <!-- 
         Process the output of the first step in "pass1" mode to generate
         output1.
    -->
    <xsl:variable name="direct">
      <xsl:apply-templates select="$original/fn:array" mode="pass1"/>
    </xsl:variable>
    <xsl:result-document href="{$direct_out}">
      <xsl:copy-of select="$direct"/>
    </xsl:result-document>
    <!--
        Process output of mode "pass1" in "pass2" mode to generate
        output2.
    -->
    <xsl:result-document href="{$xmlified_out}">
      <xsl:apply-templates select="$direct" mode="pass2"/>
    </xsl:result-document>
  </xsl:template>

  <!-- Debugging: warn about anything unmatched -->
  <xsl:template match="*|@*" mode="#all">
    <xsl:variable name="msg" select="' UNMATCHED: '||name(.)||' '"/>
    <xsl:message select="$msg"/>
    <xsl:comment select="$msg"/>
  </xsl:template>
  
  <!-- ************** -->
  <!-- *** pass 1 *** -->
  <!-- ************** -->

  <!-- 
       The outermost <array> (in the XSLT functions namespace) becomes
       an outermost <language-subtag-registry> in no namespace. 
  -->
  <xsl:template match="/fn:array" mode="pass1">
    <xsl:element name="language-subtag-registry">
      <!-- Add a timestamp -->
      <xsl:attribute name="generated" select="fn:current-dateTime()"/>
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>
  
  <!-- 
       Each <map> becomes an <Entry>, adding an @n to record its 
       position in the original list.
  -->
  <xsl:template match="fn:map" mode="pass1">
    <xsl:element name="Entry">
      <xsl:attribute name="n" select="position()"/>
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>

  <!-- 
       Each <string> child of a <map> becomes an element whose GI
       is the value of its @key attribute.
  -->
  <xsl:template match="fn:map/fn:string[@key]" mode="pass1">
    <xsl:element name="{@key}">
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>

  <!--
      <array> children of a <map> are themselves dropped, but their
      children are processed.
  -->
  <xsl:template match="fn:array" mode="pass1" name="suicide">
    <xsl:apply-templates mode="pass1"/>
  </xsl:template>

  <!-- 
       The children of the dropped <array> each become an output
       element whose GI is the value of the <array>'s @key.
  -->
  <xsl:template match="fn:array/fn:string" mode="pass1">
    <xsl:element name="{parent::fn:array/@key}">
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!-- ************** -->
  <!-- *** pass 2 *** -->
  <!-- ************** -->

  <!-- 
       Copy over the outermost <language-subtag-registry> element
       generated by "pass1", including its timestamp.
  -->
  <xsl:template match="language-subtag-registry" mode="pass2">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="pass2">
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
            a digit to sort after the last alphabetical-starting entry
        -->
        <xsl:sort select="replace( Tag|Subtag, '^[0-9]+','ZZZZZZ$0')" case-order="lower-first"/>
      </xsl:apply-templates>
      <!-- Whitespace that makes output look better (at least w/ my processor :-) -->
      <xsl:text>&#x0A;&#x0A;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <!--
      Each <Entry> becomes an element based on the value of its child <Type>
  -->
  <xsl:template match="Entry" mode="pass2">
    <!-- Whitespace that makes output look better (at least w/ my processor :-) -->
    <xsl:text>&#x0A;&#x0A;&#x20;&#x20;&#x20;</xsl:text>
    <xsl:element name="{Type}">
      <!-- 
           NOTE: the templates that match the children of <Entry>
           (other than <Comments> and <Description>) must not generate
           content, as an attribute is added after them. Typically
           each should generate an attribute, but generating nothing
           or an error message would work, too.
      -->
      <xsl:apply-templates mode="pass2"
          select="child::* except ( Type, Comments, Description )"/>
      <!-- Copy over the serial number -->
      <xsl:copy-of select="@*"/>
      <!-- Process the prose -->
      <!--
          Note: the input JSON does not (yet?) properly separate
          multi-line entries. Here we presume that every set of
          <Description>s should be multiple elements (which is true
          for the vast majority) and every set of <Coments> should be
          a single element (which is true for most of them).
      -->
      <xsl:apply-templates select="Description" mode="pass2"/>
      <xsl:if test="Comments">
        <xsl:element name="comments">
          <xsl:apply-templates select="Comments" mode="pass2"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!--
      Each child of an <Entry> (except for the prose elements) becomes
      an attribute.
  -->
  <xsl:template match="Entry/*" mode="pass2" priority="2">
    <xsl:attribute name="{lower-case(name(.))}" select="."/>
  </xsl:template>

  <!--
      The prose element <Description> just becomes a lower-caes copy
      of itself
  -->
  <xsl:template match="Description" mode="pass2" priority="3">
    <xsl:element name="{lower-case(name(.))}">
      <!-- Never anything other than text, so no need to apply templates -->
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!--
      The content of prose elements <Comments> are all tucked into a
      single <Comments>, so here we just about the content.
  -->
  <xsl:template match="Comments" mode="pass2" priority="3">
    <xsl:value-of select="."/>
    <xsl:if test="position() lt last()">
      <xsl:text>&#x20;</xsl:text>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
