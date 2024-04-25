<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="#all"
  >

  <!--
    IANA_language_registry_in_XML.xslt
    Written 2019-11-14 by Syd Bauman
    © 2019 by Syd Bauman and the Women Writers Project
    Available under the terms of the MIT License.
  -->

  <!--
      Input (to XSLT engine): does not matter, input is not read
      Input (read in): A copy of the IANA Language Subtag Registry.
      Output: The information from the input converted to a “semantic” XML structure.
      Parameter $input = URL of input (default is https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
      Parameter $output = URL for storing output (default is /tmp/IANA_language_registry.xml)
      Parameter $separator = a string you *know* does not occur in the input (default is ␞␞)
  -->

  <!-- See also: https://www.w3.org/wiki/IANA_Language_Subtag_Registry_in_SKOS -->
  <!-- See also: https://r12a.github.io/app-subtags/ -->

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="input" as="xs:string"
             select="'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry'"/>
  <xsl:param name="output" as="xs:string"
             select="'/tmp/IANA_language_subtag_registry.xml'"/>
  <xsl:param name="separator" as="xs:string"
             select="'␞␞'"/>
  
  <xsl:template match="/" name="xsl:initial-template">
    <!-- First step: can we read the input? -->
    <xsl:variable name="idunno" as="xs:boolean">
      <xsl:try select="fn:unparsed-text-available( $input )">
        <xsl:catch>
          <xsl:message terminate="yes"
            select="'ERROR: Cannot read input document ('||$input||')'"/>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    <!-- Read in input as a set of text lines: -->
    <xsl:variable name="original_lines" select="unparsed-text-lines( $input )" as="xs:string+"/>
    <!-- Convert to a single line, remembering where line boundries occur by changing them to $separator: -->
    <xsl:variable name="origs_as_line"  select="string-join( $original_lines, $separator ) => normalize-space()" as="xs:string"/>
    <!-- Join continued lines with previous by removing preceding $separator (and space character): -->
    <xsl:variable name="joined_as_line" select="fn:replace( $origs_as_line, $separator||'&#x20;', '&#x20;')" as="xs:string"/>
    <xsl:variable name="separated" select="tokenize( $joined_as_line, '%%')" as="xs:string+"/>
    <xsl:variable name="grouped" as="element(thing1)+">
      <xsl:for-each select="$separated">
        <thing1>
          <xsl:for-each select="fn:tokenize( ., $separator )">
            <xsl:if test="fn:normalize-space(.) ne ''">
              <record><xsl:sequence select="."/></record>
            </xsl:if>
          </xsl:for-each>
        </thing1>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="parsed" as="element(thing2)+">
      <xsl:for-each select="$grouped">
        <thing2>
          <xsl:apply-templates select="record"/>
        </thing2>
      </xsl:for-each>
    </xsl:variable>
    <xsl:result-document href="{$output}">
      <language-subtag-registry count="{count($parsed)}" generated="{fn:current-dateTime()}" source="{$input}" sourceDate="{$parsed/thing2[1]/file-date}">
        <xsl:apply-templates select="$parsed[type]"/>
      </language-subtag-registry>
    </xsl:result-document>

    <xsl:result-document href="/tmp/debug.xml">
      <debug>
        <grouped>
          <xsl:copy-of select="$grouped"/>
        </grouped>
        <parsed>
          <xsl:copy-of select="$parsed"/>
        </parsed>
      </debug>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="record">
    <xsl:variable name="gi" select="fn:substring-before( ., ':') => fn:lower-case()" as="xs:string"/>
    <xsl:variable name="content" select="fn:substring-after( ., ':') => fn:normalize-space()"/>
    <xsl:element name="{$gi}"><xsl:value-of select="$content"/></xsl:element>
  </xsl:template>
  
  <xsl:template match="thing2">
    <xsl:element name="{type}">
      <xsl:attribute name="n" select="fn:position()"/>
      <xsl:for-each select="* except ( type, description, comments )">
        <xsl:attribute name="{name(.)}" select="normalize-space(.)"/>
      </xsl:for-each>
      <xsl:copy-of select="description|comments"/>
    </xsl:element>
  </xsl:template>
  
</xsl:stylesheet>
<!--
    <registry>
      <xsl:variable name="regex" select="$separator||'[A-Z][a-zA-Z-]+:'"/>
      <xsl:for-each select="$separated">
        <xsl:analyze-string select="." regex="{$regex}"></xsl:analyze-string>
      </xsl:for-each>
    </registry>


    <xsl:variable name="original_elems">
      <xsl:for-each select="$original_lines">
        <line fake="{matches( ., '^\s')}">
          <xsl:sequence select="."/>
        </line>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="condensed_strings" as="xs:string+">
      <xsl:iterate select="$original_elems/line[ @fake eq 'false']">
        <xsl:sequence
          select="fn:string-join( following-sibling::line[ following-sibling::line[ @fake eq 'true'][1] >> . ]!normalize-space(.), '&#x20;')"/>
      </xsl:iterate>
    </xsl:variable>
    <xsl:variable name="direct" as="element(entry)+">
      <xsl:for-each-group select="$condensed_strings" group-starting-with=".[matches(.,'%%')]">
        <entry>
          <xsl:for-each select="fn:current-group()[fn:matches(.,'^[A-Z]:')]">
            <xsl:variable name="category" select="fn:lower-case( fn:substring-before( .,':') )"/>
            <xsl:variable name="content"  select="fn:normalize-space( fn:substring-after( .,':') )"/>
            <xsl:element name="{$category}">
              <xsl:sequence select="$content"/>
            </xsl:element>
          </xsl:for-each>
        </entry>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:result-document href="/tmp/debug.txt">
      <debug>
        <original_lines cnt="{fn:count($original_lines)}">
          <xsl:sequence select="$original_lines"/>
        </original_lines>
        <original_elems cnt="{fn:count($original_elems)}">
          <xsl:sequence select="$original_elems"/>
        </original_elems>
        <condensed_string cnt="{fn:count($condensed_strings)}">
          <xsl:sequence select="$condensed_strings"/>
        </condensed_string>
      </debug>
    </xsl:result-document>
    <registry>
      <xsl:apply-templates select="$direct/entry[type]"/>
    </registry>
  </xsl:template>
  
  <xsl:template match="entry">
    <xsl:variable name="gi" select="type!fn:string()" as="xs:NCName"/>
    <xsl:element name="{$gi}">
      <xsl:for-each select="* except ( type, description )">
        <xsl:attribute name="{name(.)}" select="normalize-space(.)"/>
      </xsl:for-each>
      <xsl:copy-of select="description"/>
    </xsl:element>
  </xsl:template>
--><!--
  <!-\- Debugging: warn about anything unmatched -\->
  <xsl:template match="*|@*" mode="#all">
    <xsl:variable name="msg" select="' UNMATCHED: '||name(.)||' '"/>
    <xsl:message select="$msg"/>
    <xsl:comment select="$msg"/>
  </xsl:template>
  
  <!-\- ************** -\->
  <!-\- *** pass 1 *** -\->
  <!-\- ************** -\->

  <!-\- 
       The outermost <array> (in the XSLT functions namespace) becomes
       an outermost <language-subtag-registry> in no namespace. 
  -\->
  <xsl:template match="/fn:array" mode="pass1">
    <xsl:element name="language-subtag-registry">
      <!-\- Add a timestamp -\->
      <xsl:attribute name="generated" select="fn:current-dateTime()"/>
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>
  
  <!-\- 
       Each <map> becomes an <Entry>, adding an @n to record its 
       position in the original list.
  -\->
  <xsl:template match="fn:map" mode="pass1">
    <xsl:element name="Entry">
      <xsl:attribute name="n" select="position()"/>
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>

  <!-\- 
       Each <string> child of a <map> becomes an element whose GI
       is the value of its @key attribute.
  -\->
  <xsl:template match="fn:map/fn:string[@key]" mode="pass1">
    <xsl:element name="{@key}">
      <xsl:apply-templates mode="pass1"/>
    </xsl:element>
  </xsl:template>

  <!-\-
      <array> children of a <map> are themselves dropped, but their
      children are processed.
  -\->
  <xsl:template match="fn:array" mode="pass1" name="suicide">
    <xsl:apply-templates mode="pass1"/>
  </xsl:template>

  <!-\- 
       The children of the dropped <array> each become an output
       element whose GI is the value of the <array>'s @key.
  -\->
  <xsl:template match="fn:array/fn:string" mode="pass1">
    <xsl:element name="{parent::fn:array/@key}">
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!-\- ************** -\->
  <!-\- *** pass 2 *** -\->
  <!-\- ************** -\->

  <!-\- 
       Copy over the outermost <language-subtag-registry> element
       generated by "pass1", including its timestamp.
  -\->
  <xsl:template match="language-subtag-registry" mode="pass2">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="pass2">
        <!-\-
            This slightly complex double-sorting is designed to get letters
            to sort before digits. In truth it only gets (sub)tags that *start*
            with digits to sort after letters, but that's good enough for my
            purposes here.
        -\->
        <!-\- 
             first sort on any digits, numerically (lumping all values without
             any digits together at 0)
        -\->
        <xsl:sort select="if ( matches( (Tag|Subtag),'^[0-9]' ) )
                          then xs:integer( replace( (Tag|Subtag), '[^0-9]','') )
                          else 0"/>
        <!-\-
            then sort on the string value, but force any that start with
            a digit to sort after the last alphabetical-starting entry
        -\->
        <xsl:sort select="replace( Tag|Subtag, '^[0-9]+','ZZZZZZ$0')" case-order="lower-first"/>
      </xsl:apply-templates>
      <!-\- Whitespace that makes output look better (at least w/ my processor :-) -\->
      <xsl:text>&#x0A;&#x0A;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <!-\-
      Each <Entry> becomes an element based on the value of its child <Type>
  -\->
  <xsl:template match="Entry" mode="pass2">
    <!-\- Whitespace that makes output look better (at least w/ my processor :-) -\->
    <xsl:text>&#x0A;&#x0A;&#x20;&#x20;&#x20;</xsl:text>
    <xsl:element name="{Type}">
      <!-\- 
           NOTE: the templates that match the children of <Entry>
           (other than <Comments> and <Description>) must not generate
           content, as an attribute is added after them. Typically
           each should generate an attribute, but generating nothing
           or an error message would work, too.
      -\->
      <xsl:apply-templates mode="pass2"
          select="child::* except ( Type, Comments, Description )"/>
      <!-\- Copy over the serial number -\->
      <xsl:copy-of select="@*"/>
      <!-\- Process the prose -\->
      <!-\-
          Note: the input JSON does not (yet?) properly separate
          multi-line entries. Here we presume that every set of
          <Description>s should be multiple elements (which is true
          for the vast majority) and every set of <Coments> should be
          a single element (which is true for most of them).
      -\->
      <xsl:apply-templates select="Description" mode="pass2"/>
      <xsl:if test="Comments">
        <xsl:element name="comments">
          <xsl:apply-templates select="Comments" mode="pass2"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-\-
      Each child of an <Entry> (except for the prose elements) becomes
      an attribute.
  -\->
  <xsl:template match="Entry/*" mode="pass2" priority="2">
    <xsl:attribute name="{lower-case(name(.))}" select="."/>
  </xsl:template>

  <!-\-
      The prose element <Description> just becomes a lower-caes copy
      of itself
  -\->
  <xsl:template match="Description" mode="pass2" priority="3">
    <xsl:element name="{lower-case(name(.))}">
      <!-\- Never anything other than text, so no need to apply templates -\->
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!-\-
      The content of prose elements <Comments> are all tucked into a
      single <Comments>, so here we just about the content.
  -\->
  <xsl:template match="Comments" mode="pass2" priority="3">
    <xsl:value-of select="."/>
    <xsl:if test="position() lt last()">
      <xsl:text>&#x20;</xsl:text>
    </xsl:if>
  </xsl:template>-->
