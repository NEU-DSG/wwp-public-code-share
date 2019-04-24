<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:out="http://www.w3.org/1999/XSL/Transform-NOT!"
  xmlns:doc="http://www.oxygenxml.com/ns/doc/xsl-NOT!"
  xmlns:in="http://www.example.edu/no_matter,_input_not_actually_read"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  version="3.0">
  
  <xsl:namespace-alias stylesheet-prefix="out" result-prefix="xsl"/>
  <xsl:namespace-alias stylesheet-prefix="doc" result-prefix="xd"/>
  <xsl:output method="xml" indent="yes"/>
  <xsl:param name="UCD"
    select="'https://raw.githubusercontent.com/behnam/unicode-ucdxml/master/ucd.nounihan.grouped.xml'"/>
  <xsl:param name="WWPns" select="'http://www.wwp.northeastern.edu/ns/textbase'"/>
  <xsl:param name="TEIns" select="'http://www.tei-c.org/ns/1.0'"/>

  <xsl:template match="/">
    <xsl:result-document href="WWP.xslt">

      <xsl:comment> *************** </xsl:comment>
      <xsl:comment> * DO NOT EDIT * </xsl:comment>
      <xsl:comment> *************** </xsl:comment>
      <xsl:comment> *
     * This program generated from XSLT source; to make changes edit source, then
     * run the source program, and use the newly generated output in place of this.   
     * </xsl:comment>
      <out:stylesheet version="3.0"
        xpath-default-namespace="{$WWPns}"
        xmlns="http://www.w3.org/1999/xhtml"
        xmlns:map="http://www.w3.org/2005/xpath-functions/map"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:wf="http://www.wwp.northeastern.edu/ns/functions">

        <doc:doc scope="stylesheet">
          <doc:desc>
            <doc:p><doc:b>Created:</doc:b> 2019-04-20, based very heavily on my
              ~/Documents/WWP/allChars.xslt, itself begun 2014-02-09</doc:p>
            <doc:p><doc:b>Author:</doc:b> syd</doc:p>
            <doc:p>Read in a WWP file and write out an HTML table the characters therein. What
              counts as a character is based on the various parameters, below.</doc:p>
            <doc:ul>
              <doc:li>attrs: <doc:ul>
                  <doc:li>attrs=0 means drop <doc:i>all</doc:i> attributes</doc:li>
                  <doc:li>attrs=1 means keep pre() and post() of @rend only [default]</doc:li>
                  <doc:li>attrs=9 means keep <doc:i>all</doc:i> attributes</doc:li>
                </doc:ul></doc:li>
              <doc:li>whitespace: <doc:ul>
                  <doc:li>whitespace=0 means strip whitespace [default]</doc:li>
                  <doc:li>whitespace=1 means all whitespace normalized; presumption is space between
                    attr values</doc:li>
                  <doc:li>whitespace=3 means no normalization at all</doc:li>
                </doc:ul>
              </doc:li>
              <doc:li>fold: <doc:ul>
                  <doc:li>fold=0 means no case folding [default]</doc:li>
                  <doc:li>fold=1 means case folding (upper to lower, A-Z only)</doc:li>
                  <doc:li>fold=2 means case folding (including Greek, etc.) and long-s folded to
                    s</doc:li>
                </doc:ul>
              </doc:li>
              <doc:li>skip: <doc:ul>
                  <doc:li>skip=0 means process the entire document including PIs and
                    comments</doc:li>
                  <doc:li>skip=1 means process the entire document excluding PIs and
                    comments</doc:li>
                  <doc:li>skip=2 means strip out the &lt;teiHeader>(s), too</doc:li>
                  <doc:li>skip=3 means strip out &lt;fw>, &lt;figDesc>, and non-authorial notes,
                    too</doc:li>
                  <doc:li>skip=4 means 3 + also take &lt;corr> over &lt;sic>, &lt;expan> over
                    &lt;abbr>, &lt;reg> over &lt;orig> (including processing VUJIs) and first
                    &lt;supplied> or &lt;unclear> in a &lt;choice>. [default]</doc:li>
                </doc:ul>
              </doc:li>
            </doc:ul>
          </doc:desc>
        </doc:doc>

        <out:param name="debug" select="false()" as="xs:boolean"/>
        <out:param name="attrs" select="1" as="xs:integer"/>
        <out:param name="whitespace" select="0" as="xs:integer"/>
        <out:param name="fold" select="0" as="xs:integer"/>
        <out:param name="skip" select="3" as="xs:integer" static="yes"/>
        <out:param name="fileName" select="tokenize(document-uri(/), '/')[last()]"/>
        <out:param name="UCD" select='{"&apos;"||$UCD||"&apos;"}'/>
        <doc:doc>
          <doc:desc>The following 2 parameters (protect open paren &amp; protected close paren)
            should each be set to a character string that will
            <doc:b>never</doc:b> occur in an input document</doc:desc>
        </doc:doc>
        <out:param name="pop" select="'&#xFF08;'"/>
        <out:param name="pcp" select="'&#xFF09;'"/>
        <doc:doc>
          <doc:desc>rendition ladder (open|close) paren:</doc:desc>
        </doc:doc>
        <out:variable name="rlop" select="'\\\('"/>
        <out:variable name="rlcp" select="'\\\)'"/>

        <out:output method="xhtml" indent="yes"/>

        <out:template match="/">
          <xsl:text>&#x0A;</xsl:text>
          <xsl:comment> pass1: generate a copy of input, handling skip= and attrs= </xsl:comment>
          <xsl:text>&#x0A;</xsl:text>
          <out:variable name="content">
            <out:apply-templates select="node()">
              <xsl:attribute name="_mode">
                <xsl:text>{'skip'||$skip}</xsl:text>
              </xsl:attribute>
            </out:apply-templates>
          </out:variable>
          <xsl:text>&#x0A;</xsl:text>
          <xsl:comment> We now have a reduced version of entire document in $content Turn it into a big string, collapsing whitespace as requested </xsl:comment>
          <xsl:text>&#x0A;</xsl:text>
          <out:variable name="bigString">
            <out:choose>
              <out:when test="$whitespace eq 0">
                <out:value-of select="translate(normalize-space($content), '&#x20;', '')"/>
              </out:when>
              <out:when test="$whitespace eq 1">
                <out:value-of select="normalize-space($content)"/>
              </out:when>
              <out:when test="$whitespace eq 3">
                <out:value-of select="$content"/>
              </out:when>
              <out:otherwise>
                <out:message terminate="yes" select="'Invalid whitespace param ' || $whitespace"/>
              </out:otherwise>
            </out:choose>
          </out:variable>
          <!-- Case-fold alphabetic characters as requested -->
          <out:variable name="bigString">
            <out:choose>
              <out:when test="$fold eq 0">
                <out:value-of select="$bigString"/>
              </out:when>
              <out:when test="$fold eq 1">
                <out:value-of
                  select="translate($bigString, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"
                />
              </out:when>
              <out:when test="$fold eq 2">
                <out:value-of select="translate(lower-case($bigString), '&#x017F;', 's')"/>
              </out:when>
              <out:otherwise>
                <out:message terminate="yes" select="'Invalid fold param ' || $fold"/>
              </out:otherwise>
            </out:choose>
          </out:variable>
          <!-- Convert the entire big string into a sequence of (decimal) codepoints -->
          <out:variable name="seq" select="string-to-codepoints($bigString)"/>
          <!--
      Convert sequence of (decimal) codes into a variable that maps the
      decimal codepoint into a count thereof. That is,
      $count_by_decimal_char_num(44) returns the number of commas in the
      (counted portion of) the input document.
    -->
          <out:variable name="count_by_decimal_char_num" as="map( xs:integer, xs:integer )">
            <out:map>
              <out:for-each select="distinct-values($seq)">
                <out:map-entry key="." select="count($seq[. eq current()])"/>
              </out:for-each>
            </out:map>
          </out:variable>
          <!-- Generate output -->
          <html>
            <head>
              <out:variable name="title" select="'chars in ' || $fileName"/>
              <title>
                <out:value-of select="$fileName"/>
              </title>
              <meta name="generated_by" content="tableOfChars.xslt"/>
              <meta name="generated_at" content="{current-dateTime()}"/>
              <script type="application/javascript" src="http://www.wwp.neu.edu/utils/bin/javascript/sorttable.js"/>
              <style type="text/css">
                body {
                  margin: 1em 1em 1em 3em;
                  padding: 1em 1em 1em 3em;
                }
                thead {
                  background-color: #DEE3E6;
                }
                th,
                td {
                  padding: 0.5ex;
                }
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
                }</style>
            </head>
            <body>
              <h2>Character Counts in <out:value-of select="$fileName"/></h2>
              <p>Character counts in <out:value-of select="base-uri(/)"/>, using the following
                parameteres (see documentation for what they mean):</p>
              <ul>
                <li><span class="param">attrs</span> = <out:value-of select="$attrs"/></li>
                <li><span class="param">whitespace</span> = <out:value-of select="$whitespace"
                  /></li>
                <li><span class="param">fold</span> = <out:value-of select="$fold"/></li>
                <li><span class="param">skip</span> = <out:value-of select="$skip"/></li>
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
                  <out:for-each select="map:keys($count_by_decimal_char_num)">
                    <tr>
                      <td class="cnt">
                        <out:value-of select="$count_by_decimal_char_num(.)"/>
                      </td>
                      <td class="Ucp">
                        <out:variable name="hexNum"
                          select="wf:decimal2hexDigits(.) ! translate(., '&#x20;', '') => string-join()"/>
                        <out:variable name="hexNum4digit"
                          select="substring('0000', string-length($hexNum) + 1) || $hexNum"/>
                        <out:value-of select="'U+' || $hexNum4digit"/>
                      </td>
                      <td class="chr">
                        <out:value-of select="codepoints-to-string(.)"/>
                      </td>
                    </tr>
                  </out:for-each>
                </tbody>
              </table>
              <p>This table generated <out:value-of select="current-dateTime()"/>.</p>
            </body>
          </html>
        </out:template>

        <out:template match="@* | node()" mode="#all">
          <out:copy>
            <out:choose>
              <out:when test="$attrs eq 0"/>
              <out:when test="$attrs eq 1">
                <out:apply-templates select="@rend[contains(., 'pre(')]" mode="attrs1">
                  <out:with-param name="keyword" select="'pre'"/>
                </out:apply-templates>
                <out:apply-templates select="@rend[contains(., 'post(')]" mode="attrs1">
                  <out:with-param name="keyword" select="'post'"/>
                </out:apply-templates>
              </out:when>
              <out:when test="$attrs eq 9">
                <out:apply-templates select="@*" mode="#current"/>
              </out:when>
            </out:choose>
            <out:apply-templates select="node()" mode="#current"/>
          </out:copy>
        </out:template>
        <out:template match="processing-instruction() | comment()" mode="skip0" priority="2">
          <out:value-of select="."/>
        </out:template>
        <out:template match="comment() | processing-instruction()" mode="skip1 skip2 skip3 skip4"
          priority="2"/>
        <out:template match="teiHeader" mode="skip2 skip3 skip4" priority="2"/>
        <out:template match="fw | note[@type and (@type ne 'authorial')] | figDesc"
          mode="skip3 skip4" priority="2"/>
        <out:template match="sic | orig | abbr" mode="skip4" priority="2"/>
        <out:template match="choice[unclear | supplied]" mode="skip4" priority="2">
          <out:apply-templates select="*[1]" mode="#current"/>
        </out:template>
        <out:template match="vuji" mode="skip4" priority="2">
          <out:choose>
            <out:when test=". eq 'i'">
              <out:text>j</out:text>
            </out:when>
            <out:when test=". eq 'I'">
              <out:text>J</out:text>
            </out:when>
            <out:when test=". eq 'j'">
              <out:text>i</out:text>
            </out:when>
            <out:when test=". eq 'J'">
              <out:text>I</out:text>
            </out:when>
            <out:when test=". eq 'u'">
              <out:text>v</out:text>
            </out:when>
            <out:when test=". eq 'U'">
              <out:text>V</out:text>
            </out:when>
            <out:when test=". eq 'v'">
              <out:text>u</out:text>
            </out:when>
            <out:when test=". eq 'V'">
              <out:text>U</out:text>
            </out:when>
            <out:when test=". eq 'vv'">
              <out:text>w</out:text>
            </out:when>
            <out:when test=". eq 'VV'">
              <out:text>W</out:text>
            </out:when>
            <out:otherwise>
              <out:message select="'I don’t know what to do with VUJI content “' || . || '”.'"/>
              <out:value-of select="."/>
            </out:otherwise>
          </out:choose>
        </out:template>
        <out:template match="@rend" mode="attrs1" priority="2">
          <out:param name="keyword"/>
          <out:variable name="kwsrch" select="concat('^.*', $keyword, '\(([^)]+)\).*$')"/>
          <out:variable name="paren_protected"
            select="replace(replace(., $rlop, $pop), $rlcp, $pcp)"/>
          <out:variable name="keyw"
            select="
              if (contains($paren_protected, $keyword)) then
                replace($paren_protected, $kwsrch, '$1')
              else
                ''"/>
          <out:attribute>
            <xsl:attribute name="name" select="'{$keyword}'"/>
            <xsl:attribute name="select" select='"replace($keyw, &apos;#(rule|ornament)&apos;, &apos;&apos;)"'/>
          </out:attribute>
            
            
            name="{$keyword}" select="replace($keyw, '#(rule|ornament)', '')"
        </out:template>

        <!--
    This function modified from the template at
    http://www.dpawson.co.uk/xsl/sect2/N5121.html#d6617e511
  -->
        <out:function name="wf:decimal2hexDigits" as="xs:string+">
          <out:param name="number" as="xs:integer"/>
          <out:variable name="remainder" select="$number mod 16" as="xs:integer"/>
          <out:variable name="result" select="floor($number div 16) cast as xs:integer"
            as="xs:integer"/>
          <out:choose>
            <out:when test="$result gt 0">
              <out:value-of select="wf:decimal2hexDigits($result)"/>
            </out:when>
            <out:otherwise/>
          </out:choose>
          <out:choose>
            <out:when test="$remainder &lt; 10">
              <out:value-of select="$remainder cast as xs:string"/>
            </out:when>
            <out:otherwise>
              <out:variable name="temp" select="($remainder - 10) cast as xs:string"/>
              <out:value-of select="translate($temp, '012345', 'ABCDEF')"/>
            </out:otherwise>
          </out:choose>
        </out:function>

      </out:stylesheet>
    </xsl:result-document>
    
  </xsl:template>
  
</xsl:stylesheet>