<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  >
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created:</xd:b> 2019-04-20, based very heavily on
        my ~/Documents/WWP/allChars.xslt, istelf begun 2014-02-09</xd:p>
      <xd:p><xd:b>Author:</xd:b> syd</xd:p>
      <xd:p>Read in a WWP file and write out an HTML table the characters therein.
        What counts as a character is based on the various parameters, below.</xd:p>
      <xd:ul>
        <xd:li>attrs:
        <xd:ul>
          <xd:li>attrs=0 means drop <xd:i>all</xd:i> attributes</xd:li>
          <xd:li>attrs=1 means keep pre() and post() of @rend only [default]</xd:li>
          <xd:li>attrs=9 means keep <xd:i>all</xd:i> attributes</xd:li>
        </xd:ul></xd:li>
      <xd:li>whitespace:
        <xd:ul>
          <xd:li>whitespace=0 means strip whitespace [default]</xd:li>
          <xd:li>whitespace=1 means all whitespace normalized; presumption is space between attr values</xd:li>
          <xd:li>whitespace=3 means no normalization at all</xd:li>
        </xd:ul>
      </xd:li>
      <xd:li>fold:
        <xd:ul>
          <xd:li>fold=0 means no case folding [default]</xd:li>
          <xd:li>fold=1 means case folding (upper to lower, A-Z only)</xd:li>
          <xd:li>fold=2 means case folding (including Greek, etc.) and long-s folded to s</xd:li>
        </xd:ul>
      </xd:li>
      <xd:li>skip:
        <xd:ul>
          <xd:li>skip=0 means process the entire document including PIs and comments</xd:li>
          <xd:li>skip=1 means process the entire document excluding PIs and comments</xd:li>
          <xd:li>skip=2 means strip out the &lt;teiHeader>(s), too</xd:li>
          <xd:li>skip=3 means strip out &lt;fw>, &lt;figDesc>, and non-authorial notes, too</xd:li>
          <xd:li>skip=4 means 3 + also take &lt;corr> over &lt;sic>,
            &lt;expan> over &lt;abbr>, &lt;reg> over &lt;orig> (including processing VUJIs)
            and first &lt;supplied> or &lt;unclear> in a &lt;choice>. [default]</xd:li>
        </xd:ul>
      </xd:li>
      </xd:ul>
    </xd:desc>
  </xd:doc>
  
  <xsl:param name="debug" select="false()" as="xs:boolean"/>
  <xsl:param name="attrs" select="1" as="xs:integer"/>
  <xsl:param name="whitespace" select="0" as="xs:integer"/>
  <xsl:param name="fold" select="0" as="xs:integer"/>
  <xsl:param name="skip" select="3" as="xs:integer" static="yes"/>
  <xsl:param name="fileName" select="tokenize( document-uri(/),'/')[last()]"/>
  <xd:doc>
    <xd:desc>The following 2 parameters should each be set to a character
    string that will <xd:b>never</xd:b> occur in an input document</xd:desc>
  </xd:doc>
  <xsl:param name="pop" select="'&#xFF08;'"/> <!-- protected open paren -->
  <xsl:param name="pcp" select="'&#xFF09;'"/> <!-- protected close paren -->
  <xsl:variable name="rlop" select="'\\\('"/> <!-- rendition ladder open paren -->
  <xsl:variable name="rlcp" select="'\\\)'"/> <!-- rendition ladder close paren -->

  <xsl:output method="xhtml" indent="yes"/>

  <xsl:template match="/">
    <!-- pass1: generate a copy of input, handling skip= and attrs= -->
    <xsl:variable name="content">
      <xsl:apply-templates select="node()" _mode="{'skip'||$skip}"/>
    </xsl:variable>
    <!-- We now have a reduced version of entire document in $content -->
    <!-- Turn it into a big string, collapsing whitespace as requested -->
    <xsl:variable name="bigString">
      <xsl:choose>
        <xsl:when test="$whitespace eq 0">
          <xsl:value-of select="translate( normalize-space( $content ),'&#x20;','')"/>
        </xsl:when>
        <xsl:when test="$whitespace eq 1">
          <xsl:value-of select="normalize-space( $content )"/>
        </xsl:when>
        <xsl:when test="$whitespace eq 3">
          <xsl:value-of select="$content"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes" select="'Invalid whitespace param '||$whitespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Case-fold alphabetic characters as requested -->
    <xsl:variable name="bigString">
      <xsl:choose>
        <xsl:when test="$fold eq 0">
          <xsl:value-of select="$bigString"/>
        </xsl:when>
        <xsl:when test="$fold eq 1">
          <xsl:value-of select="translate( $bigString,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
        </xsl:when>
        <xsl:when test="$fold eq 2">
          <xsl:value-of select="translate( lower-case( $bigString ), '&#x017F;','s' )"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes" select="'Invalid fold param '||$fold"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Convert the entire big string into a sequence of (decimal) codepoints -->
    <xsl:variable name="seq" select="string-to-codepoints( $bigString )"/>
    <!--
      Convert sequence of (decimal) codes into a variable that maps the
      decimal codepoint into a count thereof. That is,
      $count_by_decimal_char_num(44) returns the number of commas in the
      (counted portion of) the input document.
    -->
    <xsl:variable name="count_by_decimal_char_num" as="map( xs:integer, xs:integer )">
      <xsl:map>
        <xsl:for-each select="distinct-values( $seq )">
          <xsl:map-entry key="." select="count( $seq[ . eq current() ] )"/>
        </xsl:for-each>
      </xsl:map>
    </xsl:variable>
    <!-- Generate output -->    
    <html>
      <head>
        <xsl:variable name="title" select="'chars in '||$fileName"/>
        <title><xsl:value-of select="$fileName"/></title>
        <meta name="generated_by" content="tableOfChars.xslt"/>
        <meta name="generated_at" content="{current-dateTime()}"/>
        <script type="application/javascript" src="http://www.wwp.neu.edu/utils/bin/javascript/sorttable.js"/>
        <style type="text/css">
          body { margin: 1em 1em 1em 3em; padding: 1em 1em 1em 3em; }
          thead { background-color: #DEE3E6; }
          th, td { padding: 0.5ex; }
          td.Ucp {
             text-align: center;
             }
          td.chr {
             text-align: center;
             }
          td.cnt {
             font-family: monospace;
             text-align: right;
             padding-right: 1.0em;
             }
        </style>
      </head>
      <body>
        <h2>Character Counts in <xsl:value-of select="$fileName"/></h2>
        <p>Character counts in <xsl:value-of select="base-uri(/)"/>, using
        the following parameteres (see documentation for what they mean):</p>
        <ul>
          <li><span class="param">attrs</span> = <xsl:value-of select="$attrs"/></li>
          <li><span class="param">whitespace</span> = <xsl:value-of select="$whitespace"/></li>
          <li><span class="param">fold</span> = <xsl:value-of select="$fold"/></li>
          <li><span class="param">skip</span> = <xsl:value-of select="$skip"/></li>
        </ul>
        <p>Click on a column header to sort by that column.</p>
        <table class="sortable" border="1">
          <thead>
            <tr>
              <th>count</th>
              <th>codepoint</th>
              <th>character</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="map:keys($count_by_decimal_char_num)">
              <tr>
                <td class="cnt"><xsl:value-of select="$count_by_decimal_char_num(.)"/></td>
                <td class="Ucp">
                  <xsl:variable name="hexNum" select="wf:decimal2hexDigits(.)!translate(.,'&#x20;','') => string-join()"/>
                  <xsl:variable name="hexNum4digit" select="substring('0000', string-length($hexNum) +1)||$hexNum"/>
                  <xsl:value-of select="'U+'||$hexNum4digit"/>
                </td>
                <td class="chr"><xsl:value-of select="codepoints-to-string(.)"/></td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <p>This table generated <xsl:value-of select="current-dateTime()"/>.</p>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="@*|node()" mode="#all">
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$attrs eq 0"/>
        <xsl:when test="$attrs eq 1">
          <xsl:apply-templates select="@rend[contains(.,'pre(')]" mode="attrs1">
            <xsl:with-param name="keyword" select="'pre'"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="@rend[contains(.,'post(')]" mode="attrs1">
            <xsl:with-param name="keyword" select="'post'"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$attrs eq 9">
          <xsl:apply-templates select="@*" mode="#current"/>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="processing-instruction()|comment()" mode="skip0" priority="2">
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="comment()|processing-instruction()" mode="skip1 skip2 skip3 skip4" priority="2"/>
  <xsl:template match="teiHeader" mode="skip2 skip3 skip4" priority="2"/>
  <xsl:template match="fw|note[@type and (@type ne 'authorial')]|figDesc" mode="skip3 skip4" priority="2"/>
  <xsl:template match="sic|orig|abbr" mode="skip4" priority="2"/>
  <xsl:template match="choice[unclear|supplied]" mode="skip4" priority="2">
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  <xsl:template match="vuji" mode="skip4" priority="2">
    <xsl:choose>
      <xsl:when test=". eq 'i'"><xsl:text>j</xsl:text></xsl:when>
      <xsl:when test=". eq 'I'"><xsl:text>J</xsl:text></xsl:when>
      <xsl:when test=". eq 'j'"><xsl:text>i</xsl:text></xsl:when>
      <xsl:when test=". eq 'J'"><xsl:text>I</xsl:text></xsl:when>
      <xsl:when test=". eq 'u'"><xsl:text>v</xsl:text></xsl:when>
      <xsl:when test=". eq 'U'"><xsl:text>V</xsl:text></xsl:when>
      <xsl:when test=". eq 'v'"><xsl:text>u</xsl:text></xsl:when>
      <xsl:when test=". eq 'V'"><xsl:text>U</xsl:text></xsl:when>
      <xsl:when test=". eq 'vv'"><xsl:text>w</xsl:text></xsl:when>
      <xsl:when test=". eq 'VV'"><xsl:text>W</xsl:text></xsl:when>
      <xsl:otherwise>
        <xsl:message select="'I don’t know what to do with VUJI content “'||.||'”.'"/>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@rend" mode="attrs1" priority="2">
    <xsl:param name="keyword"/>
    <xsl:variable name="kwsrch" select="concat('^.*', $keyword, '\(([^)]+)\).*$')"/>
    <xsl:variable name="paren_protected" select="replace( replace( ., $rlop, $pop), $rlcp, $pcp)"/>
    <xsl:variable name="keyw" select="if ( contains( $paren_protected, $keyword ) ) then replace( $paren_protected, $kwsrch,'$1') else ''"/>
    <xsl:attribute name="{$keyword}" select="replace( $keyw, '#(rule|ornament)','')"/>
  </xsl:template>
  
  <!--
    This function modified from the template at
    http://www.dpawson.co.uk/xsl/sect2/N5121.html#d6617e511
  -->
  <xsl:function name="wf:decimal2hexDigits" as="xs:string+">
    <xsl:param name="number" as="xs:integer"/>
    <xsl:variable name="remainder" select="$number mod 16" as="xs:integer"/>
    <xsl:variable name="result" select="floor( $number div 16 ) cast as xs:integer" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$result gt 0">
        <xsl:value-of select="wf:decimal2hexDigits( $result )"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$remainder &lt; 10">
        <xsl:value-of select="$remainder cast as xs:string"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="temp" select="( $remainder - 10 ) cast as xs:string"/>
        <xsl:value-of select="translate( $temp, '012345', 'ABCDEF')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
