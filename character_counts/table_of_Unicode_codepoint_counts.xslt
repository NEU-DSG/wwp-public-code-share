<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:out="http://www.w3.org/1999/XSL/Transform-NOT!"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:ucd="http://www.unicode.org/ns/2003/ucd/1.0"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:yaps="http://www.wwp.northeastern.edu/ns/yaps"
  xmlns:html="http://www.w3.org/1999/xhtml"
  version="3.0">
  
  <xsl:output method="xhtml" indent="yes" encoding="UTF-8" html-version="5"/>
  <xsl:param name="UCD" select="'https://raw.githubusercontent.com/behnam/unicode-ucdxml/master/ucd.nounihan.grouped.xml'"/>
  <xsl:param name="debug" select="false()" as="xs:boolean"/>
  <xsl:param name="attrs" select="1" as="xs:integer"/>
  <xsl:param name="whitespace" select="0" as="xs:integer"/>
  <xsl:param name="fold" select="0" as="xs:integer"/>
  <xsl:param name="skip" select="3" as="xs:integer"/>
  <xsl:param name="fileName" select="tokenize(document-uri(/), '/')[last()]"/>
  <xd:doc>
    <xd:desc>protect open paren, protect close paren: these variable should be set to
    any single character you *know* will not be in the document. Only used for WWP.</xd:desc>
  </xd:doc>
  <xsl:param name="pop" select="'&#xFF08;'"/>
  <xsl:param name="pcp" select="'&#xFF09;'"/>
  <xd:doc>
    <xd:desc>rendition ladder (open|close) paren: escape sequence to match an
    open or close paren in a WWP rendition ladder</xd:desc>
  </xd:doc>
  <xsl:variable name="rlop" select="'\\\('"/>
  <xsl:variable name="rlcp" select="'\\\)'"/>
  <xsl:param name="me" select="base-uri(/)"/>
  <xsl:variable name="myself" select="tokenize( $me,'/')[last()]"/>
  <xsl:variable name="andI" select="substring( $myself, 1, string-length( $myself )-5 )"/>
  <xsl:variable name="ucd">
    <xsl:choose>
      <xsl:when test="doc-available($UCD)">
        <xsl:copy-of select="document($UCD)"/>
      </xsl:when>
      <xsl:otherwise>
        <ucd:char>Unicode character name not available</ucd:char>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:template match="@*|node()" mode="#all" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/">
    <!-- pass1: generate a copy of input, handling skip= and attrs= -->
    <xsl:variable name="content">
      <xsl:apply-templates select="node()" mode="sa"/>
    </xsl:variable>
    <xsl:if test="$debug">
      <xsl:result-document href="/tmp/{$andI}_debug_content.xml" indent="no" method="xml">
        <xsl:sequence select="$content"/>
      </xsl:result-document>
    </xsl:if>
    <!--
      We now have a reduced version of entire document in $content.
      Turn it into a big string, collapsing whitespace as requested
    -->
    <xsl:variable name="bigString">
      <xsl:choose>
        <xsl:when test="$whitespace eq 0">
          <xsl:value-of select="translate( normalize-space( $content ), '&#x20;', '')"/>
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
    <xsl:if test="$debug">
      <xsl:result-document href="/tmp/{$andI}_debug_bigString1.txt" indent="no" method="text">
        <xsl:sequence select="$bigString"/>
      </xsl:result-document>
    </xsl:if>
    <!-- Case-fold alphabetic characters as requested -->
    <xsl:variable name="bigString">
      <xsl:choose>
        <xsl:when test="$fold eq 0">
          <xsl:value-of select="$bigString"/>
        </xsl:when>
        <xsl:when test="$fold eq 1">
          <xsl:value-of
            select="translate( $bigString, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"
          />
        </xsl:when>
        <xsl:when test="$fold eq 2">
          <xsl:value-of
            select="translate( lower-case( $bigString ), '&#x017F;', 's')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes" select="'Invalid fold param '||$fold"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$debug">
      <xsl:result-document href="/tmp/{$andI}_debug_bigString2.txt" indent="no" method="text">
        <xsl:sequence select="$bigString"/>
      </xsl:result-document>
    </xsl:if>
    <!-- Convert the entire big string into a sequence of (decimal) codepoints -->
    <xsl:variable name="seq" select="string-to-codepoints($bigString)"/>
    <!--
      Convert sequence of (decimal) codes into a variable that maps the
      decimal codepoint into a count thereof. That is,
      $count_by_decimal_char_num(44) returns the number of commas in the
      (counted portion of) the input document.
    -->
    <xsl:variable name="count_by_decimal_char_num" as="map( xs:integer, xs:integer )">
      <xsl:map>
        <xsl:for-each select="distinct-values($seq)">
          <xsl:map-entry key="." select="count($seq[. eq current()])"/>
        </xsl:for-each>
      </xsl:map>
    </xsl:variable>
    <!-- Generate output -->
    <html>
      <head>
        <xsl:variable name="title" select="'chars in '||$fileName"/>
        <title><xsl:value-of select="'Character counts in '||$fileName"/></title>
        <meta name="generated_by" content="table_of_Unicode_codepoint_counts.xslt"/>
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
          th, td {
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
        <h2>Character Counts in <xsl:value-of select="$fileName"/></h2>
        <p>Character counts in <tt><xsl:value-of
          select="$fileName"/></tt><a href="#fn1">¹</a>, using the
          following parameters (see documentation for what they mean):</p>
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
              <th>character name</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="map:keys($count_by_decimal_char_num)">
              <xsl:variable name="hexNum" select="wf:decimal2hexDigits(.) ! translate(., '&#x20;', '') => string-join()"/>
              <xsl:variable name="hexNum4digit" select="substring('0000', string-length($hexNum) + 1)||$hexNum"/>
              <tr>
                <td class="cnt">
                  <xsl:value-of select="$count_by_decimal_char_num(.)"/>
                </td>
                <td class="Ucp">
                  <xsl:value-of select="'U+'||$hexNum4digit"/>
                </td>
                <td class="chr">
                  <xsl:value-of select="codepoints-to-string(.)"/>
                </td>
                <td class="ucn">
                  <xsl:variable name="thisChar"
                    select="$ucd/ucd:ucd/ucd:repertoire/ucd:group/ucd:char[@cp eq $hexNum4digit]"/>
                  <xsl:choose>
                    <xsl:when test="$thisChar[@na  and  normalize-space(@na1) ne '']">
                      <xsl:value-of select="$thisChar/@na||' or '||$thisChar/@na1"/>
                    </xsl:when>
                    <xsl:when test="$thisChar[@na or @na1]">
                      <xsl:value-of select="( $thisChar/@na, $thisChar/@na1 )[1]"/>
                    </xsl:when>
                    <xsl:when test="$thisChar/parent::ucd:group[@na or normalize-space(@na1) ne '']">
                      <xsl:choose>
                        <xsl:when test="$thisChar/parent::ucd:group[@na and normalize-space(@na1) ne '']">
                          <xsl:value-of
                            select="$thisChar/parent::ucd:group/@na||' or '||$thisChar/parent::ucd:group/@na1"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="$thisChar/parent::ucd:group/@na"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>Unicode name not available</xsl:otherwise>
                  </xsl:choose>
                </td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <p>This table generated <xsl:value-of select="current-dateTime()"/>.</p>
        <hr/>
        <p name="fn1">¹ <xsl:value-of select="document-uri(/)"/></p>
      </body>
    </html>
  </xsl:template>
  
  <!-- Handle mode "skip" and "attrs" here in mode "sa" -->
  <xsl:template mode="sa" match="( processing-instruction() | comment() )[$skip eq 0]">
    <xsl:copy/>
  </xsl:template>
  <xsl:template mode="sa" match="( processing-instruction() | comment() )[$skip gt 0]"/>
  <xsl:template mode="sa" match="(tei:teiHeader|wwp:teiHeader|yaps:teiHeader|html:head)[$skip ge 2]" />
  <xsl:template mode="sa" match="(tei:fw|tei:figDesc|wwp:mw|wwp:figDesc)[$skip ge 3]"/>
  <xsl:template mode="sa" match="wwp:note[@type and (@type ne 'authorial')][$skip ge 3]"/>
  <xsl:template mode="sa" match="(tei:sic|tei:orig|tei:abbr|wwp:sic|wwp:orig|wwp:abbr)[$skip ge 4]"/>
  <xsl:template mode="sa" match="tei:choice[tei:unclear|tei:supplied ][$skip ge 4]" >
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="sa" match="@*[$attrs eq 0]"/>
  <xsl:template mode="sa" match="tei:*/@*[$attrs eq 1]">
    <xsl:if test="
         self::attribute(baseForm)
      or self::attribute(lemma)
      or self::attribute(orig)
      or ( self::attribute(assertedValue) and ../@locus eq 'value' )
      or ( self::attribute(expand) and not( parent::classRef ) )
      "><xsl:copy/></xsl:if>
  </xsl:template>
  <xsl:template mode="sa" match="@*[$attrs eq 9]">
    <xsl:value-of select="wf:padme(.)"/>
  </xsl:template>
  
  <!--
    This function modified from the template at
    http://www.dpawson.co.uk/xsl/sect2/N5121.html#d6617e511
  -->
  <xsl:function name="wf:decimal2hexDigits" as="xs:string+">
    <xsl:param name="number" as="xs:integer"/>
    <xsl:variable name="remainder" select="$number mod 16" as="xs:integer"/>
    <xsl:variable name="result" select="floor($number div 16) cast as xs:integer" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$result gt 0">
        <xsl:value-of select="wf:decimal2hexDigits($result)"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$remainder lt 10">
        <xsl:value-of select="$remainder cast as xs:string"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="temp" select="($remainder - 10) cast as xs:string"/>
        <xsl:value-of select="translate($temp, '012345', 'ABCDEF')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="wf:padme" as="xs:string">
    <xsl:param name="stringIN"/>
    <xsl:value-of select="'&#x20;'||$stringIN||'&#x20;'"/>
  </xsl:function>

<!--  <xsl:template name="generator">
        <out:template match="@*" mode="skip0 skip1 skip2 skip3 skip4" priority="2">
          <out:apply-templates select=".">
            <xsl:attribute name="_mode">
              <xsl:text>{'attrs'||$attrs}</xsl:text>
            </xsl:attribute>
          </out:apply-templates>
        </out:template>
        <out:template match="@*" mode="attrs0"/>
          <xsl:choose>
            <xsl:when test="$scheme eq 'TEI'">
              <out:template match="@*" mode="attrs1">
                <out:choose>
                  <out:when test="self::attribute(assertedValue) and ../@locus eq 'value'">
                    <out:value-of select="wf:padme(.)"/>
                  </out:when>
                  <out:when test="self::attribute(baseForm) | self::attribute(lemma) | self::attribute(orig)">
                    <!-\- could use "name(.) = ('baseForm','lemma','orig')" instead -\->
                    <out:value-of select="wf:padme(.)"/>
                  </out:when>
                  <out:when test="self::attribute(expand)  and  not(parent::classRef)">
                    <out:value-of select="wf:padme(.)"/>
                  </out:when>
                </out:choose>
              </out:template>
            </xsl:when>
            <xsl:when test="$scheme eq 'WWP'">
              <out:apply-templates select="@rend[contains(., 'pre(')]" mode="WWPattrs1">
                <out:with-param name="keyword" select="'pre'"/>
              </out:apply-templates>
              <out:apply-templates select="@rend[contains(., 'post(')]" mode="WWPattrs1">
                <out:with-param name="keyword" select="'post'"/>
              </out:apply-templates>
            </xsl:when>
            <xsl:when test="$scheme eq 'XHTML'"></xsl:when>
            <xsl:when test="$scheme eq 'yaps'"></xsl:when>
          </xsl:choose>
        <out:template match="@*" mode="attrs9">
          <out:value-of select="wf:padme(.)"/>
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
        <xsl:if test="$scheme eq 'WWP'">
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
          <out:template match="@rend" mode="WWPattrs1" priority="2">
            <out:param name="keyword"/>
            <out:variable name="kwsrch" select="concat('^.*', $keyword, '\(([^)]+)\).*$')"/>
            <out:variable name="paren_protected"
              select="replace(replace(., $rlop, $pop), $rlcp, $pcp)"/>
            <out:variable name="keyw" select="
              if ( contains( $paren_protected, $keyword ) ) then
                 replace( $paren_protected, $kwsrch, '$1')
              else
                 ''"/>
            <out:attribute>
              <xsl:attribute name="name" select="'{$keyword}'"/>
              <xsl:attribute name="select" select='"replace($keyw, &apos;#(rule|ornament)&apos;, &apos;&apos;)"'/>
            </out:attribute>
          </out:template>
        </xsl:if>
  </xsl:template>
-->
</xsl:stylesheet>
