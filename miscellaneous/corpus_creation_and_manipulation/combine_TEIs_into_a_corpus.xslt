<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  exclude-result-prefixes="#all" version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Written:</xd:b> 2022-09-22, based heavily on combine_TEIs_into_teiCorpus.xslt</xd:p>
      <xd:p><xd:b>Author:</xd:b> syd</xd:p>
      <xd:p><xd:b>input:</xd:b> any one of the files to be combined</xd:p>
      <xd:p><xd:b>output:</xd:b> combination of all the *.xml files in
      the same directory as the input document, assembled as a TEI
      corpus with a (pretty much) blank header.</xd:p>
    </xd:desc>
  </xd:doc>

  <xd:doc>
    <xd:p>Output is indented XML</xd:p>
    <xd:p>WARNING: In some (rare, in my limited experience) mixed-content cases
          the indent=yes causes problems (by inserting unwanted whitespace).</xd:p>
  </xd:doc>
  <xsl:output method="xml" indent="yes"/>

  <xd:doc>
    <xd:desc>Anything in input not otherwise matched herein is copied to output</xd:desc>
  </xd:doc>
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xd:doc>
    <xd:desc>Name of this program</xd:desc>
  </xd:doc>
  <xsl:variable name="pgm" select="tokenize( static-base-uri(),'/')[last()]"/>
  
  <xd:doc>
    <xd:desc>Version # of this program</xd:desc>
  </xd:doc>
  <xsl:variable name="version" select="'0.6.1'"/>

  <xd:doc>
    <xd:desc>Today’s date</xd:desc>
  </xd:doc>
  <xsl:param name="today" select="current-date() => xs:string() => substring( 1, 10 )" as="xs:string"/>
  
  <xd:doc>
    <xd:desc>Generate set of input documents</xd:desc>
  </xd:doc>
  <xsl:param name="input_directory" select="replace( base-uri(/), '^(.*/)[^/]+$','$1')" as="xs:string"/>
  <xsl:variable name="input_URI" select="iri-to-uri( concat( $input_directory,'?select=*.xml') )" as="xs:string"/>
  <xsl:variable name="input_documents" as="document-node()*">
    <xsl:sequence select="collection( $input_URI )"/>
  </xsl:variable>

  <xd:doc>
    <xd:p>main match-the-supplied-input-document template.
      This is run once, not once for each input file we read from $documents.
    (It applies another template once for each input file. :-)</xd:p>
  </xd:doc>
  <xsl:template match="/">
    <xsl:call-template name="prolog"/>
    <TEI xmlns="http://www.tei-c.org/ns/1.0">  <!-- what, no @version? -->
      <xsl:call-template name="header"/>
      <xsl:apply-templates select="$input_documents/*"/>
    </TEI>
  </xsl:template>

  <xd:doc>
    <xd:desc>Match the outermost TEI of a collected document and
    process it in the standard identity shallow-copy way, but remember
    its sequence number and pass it on.</xd:desc>
  </xd:doc>
  <xsl:template match="/TEI">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()">
        <xsl:with-param tunnel="yes" select="position()" name="seq"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Generate prolog, i.e. the PIs at top-of-file. Note that we
    are not copying them from an input file, as a) the desired values are
    likely different for our corpus output, and b) the input files might
    be different from each other, so which one would we pick?</xd:desc>
  </xd:doc>
  <xsl:template name="prolog" as="node()+">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:processing-instruction name="xml-stylesheet"> type="text/xsl" href="/path/to/default/stylesheet.xslt"</xsl:processing-instruction>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:processing-instruction name="xml-model"> type="application/relax-ng-compact-syntax" href="/path/to/schema.rnc"</xsl:processing-instruction>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:processing-instruction name="xml-model"> type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron" href="/path/to/schema.sch"</xsl:processing-instruction>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xd:doc>
    <xd:desc>Generate output TEI corpus header</xd:desc>
  </xd:doc>
  <xsl:template name="header" as="element(teiHeader)">
    <teiHeader>
      <fileDesc>
        <titleStmt>
          <title type="main">A Corpus of <xsl:value-of select="tokenize( $input_directory, '/')[last()-1]||'/'"/></title>
        </titleStmt>
        <publicationStmt>
          <publisher>Northeastern University Digital Scholarship Group</publisher>
          <address>
            <addrLine>SL 213</addrLine>
            <addrLine>Notheastern University</addrLine>
            <addrLine>360 Huntington Avenue</addrLine>
            <addrLine>Boston, MA  02115-5005</addrLine>
            <addrLine>USA</addrLine>
            <addrLine>url:mailto:dsg@neu.edu</addrLine>
            <addrLine>url:https://dsg.northeastern.edu/</addrLine>
          </address>
          <date when="{$today}"/>
        </publicationStmt>
        <sourceDesc>
          <p>FIX ME</p>
          <p>If this <gi>sourceDesc</gi> has not been fixed, see the
            <gi>sourceDesc</gi>s of the individual <gi>TEI</gi>
            documents, below.</p>
        </sourceDesc>
      </fileDesc>
      <encodingDesc>
        <appInfo>
          <application ident="{$pgm}" version="{$version}">
            <label>combined</label>
            <desc xsl:expand-text="yes">
              Combined all *.xml files in {$input_directory} into one corpus file.
              <date when="{current-dateTime()}"/>
            </desc>
          </application>
        </appInfo>
      </encodingDesc>
    </teiHeader>
  </xsl:template>

  
  <xd:doc>
    <xd:desc>
      <xd:p>Fix pointers</xd:p>
      <xd:p>Assumptions: 1) every pointer that needs to be fixed is in
        an attribute value that either starts with a ‘#’ or contains the
        string “ #”; and 2) there are no other attribute values that
        meet that criteria.</xd:p>
    </xd:desc>
    <xd:param name="seq">The sequence number of this XML document in the collection
      of documents we read in (and thus a unique number for this document); a tunnel
      parameter.</xd:param>
  </xd:doc>
  <xsl:template match="@*[ starts-with( normalize-space(.), '#') or contains( normalize-space(.), '&#x20;#') ]">
    <xsl:param name="seq" tunnel="yes"/>
    <xsl:variable name="disambiguator" as="xs:string" select="wf:generate_disambiguation_prefix( $seq )"/>
    <xsl:attribute name="{name(.)}">
      <xsl:variable name="disambiguated_values" as="xs:string*">
        <xsl:for-each select="tokenize(.)">
          <xsl:choose>
            <xsl:when test="starts-with( ., '#')">
              <xsl:sequence select="'#'||$disambiguator||substring( ., 2 )"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:sequence select="string-join( $disambiguated_values, '&#x20;')"/>
    </xsl:attribute>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Fix IDs (i.e., the things pointers point at)</xd:desc>
    <xd:param name="seq">The sequence number of this XML document in the collection
      of documents we read in (and thus a unique number for this document); a tunnel
      parameter.</xd:param>
  </xd:doc>
  <xsl:template match="@xml:id">
    <xsl:param name="seq" tunnel="yes"/>
    <xsl:variable name="disambiguator" as="xs:string" select="wf:generate_disambiguation_prefix( $seq )"/>
    <xsl:attribute name="{name(.)}">
      <xsl:sequence select="$disambiguator||normalize-space(.)"/>
    </xsl:attribute>
  </xsl:template>

  <xd:doc>
    <xd:desc>Subroutine for generating prefixes. (We use a subroutine so that
      a) the code in above templates is shorter and easier to read, and
      b) so that they are guaranteed to use the same algorithm.)</xd:desc>
    <xd:param name="seq">The sequence number of this XML document in the collection
      of documents we read in (and thus a unique number for this document); a tunnel
      parameter.</xd:param>
  </xd:doc>
  <xsl:function name="wf:generate_disambiguation_prefix" as="xs:string">
    <xsl:param name="seq"/>
    <!-- Ascertain how many digits are needed to hold the largest number we will have to generate: -->
    <xsl:variable name="numDigits" as="xs:integer"
                  select="count( $input_documents ) => math:log10() => floor() => xs:integer() + 1"/>
    <!-- Generate a picture string that is that number of 0s in a row: -->
    <xsl:variable name="pictureString" as="xs:string" select="substring('0000000000', 1, $numDigits )"/>
    <!-- Generate prefix:
          * an ‘f’
          * the sequence number of this document (with leading zeroes)
          * an underscore -->
    <xsl:sequence select="'f'||format-integer( $seq, $pictureString )||'_'"/>
  </xsl:function>

</xsl:stylesheet>
