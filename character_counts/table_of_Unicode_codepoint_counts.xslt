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
  <xsl:param name="fold" select="0" as="xs:integer"/>
  <xsl:param name="skip" select="3" as="xs:integer"/>
  <xsl:param name="whitespace" select="0" as="xs:integer"/>
  <xsl:param name="fileName" select="tokenize(document-uri(/), '/')[last()]"/>
  <xd:doc>
    <xd:desc>protect open paren, protect close paren: these variable should be
    set to any single character you *know* will not be in the input document.
    Only used for WWP.</xd:desc>
  </xd:doc>
  <xsl:param name="pop" select="'&#xFF08;'"/>
  <xsl:param name="pcp" select="'&#xFF09;'"/>
  <xd:doc>
    <xd:desc>rendition ladder (open|close) paren for search, and rendition ladder
      (open|close) paren for replace: escape sequence to match an open or close
      paren in a rendition ladder. Only used for WWP.</xd:desc>
  </xd:doc>
  <xsl:variable name="rlops" select="'\\\('"/>
  <xsl:variable name="rlcps" select="'\\\)'"/>
  <xsl:variable name="rlopr" select="'\\('"/>
  <xsl:variable name="rlcpr" select="'\\)'"/>
  <xd:doc>
    <xd:desc>Me, myself, and I: 
    <xd:ul>
      <xd:li><xd:i>me</xd:i>: complete URI to the input document</xd:li>
      <xd:li><xd:i>myself</xd:i>: filename component of $me with extension</xd:li>
      <xd:li><xd:i>andI</xd:i>: filename component of $me without extension</xd:li>
    </xd:ul></xd:desc>
  </xd:doc>
  <xsl:param name="me" select="base-uri(/)"/>
  <xsl:variable name="myself" select="tokenize( $me,'/')[last()]"/>
  <xsl:variable name="andI" select="replace( $myself, '\.[^.]*$','')"/>
  <xsl:variable name="input" select="/"/>
  <xsl:variable name="ucdTemp">
    <xsl:choose>
      <xsl:when test="not( $UCD castable as xs:anyURI )">
        <xsl:message terminate="no">Warning: Invalid $UCD — not a URI</xsl:message>
      </xsl:when>
      <xsl:when test="doc-available($UCD)">
        <xsl:copy-of select="document($UCD)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Warning: Unicode Character Database URI (<xsl:value-of select="$UCD"/>) not readable.</xsl:message>
        <ucd:char>Unicode character name not available</ucd:char>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="ucd">
    <xsl:choose>
      <xsl:when test="count( $ucdTemp/ucd:ucd/ucd:repertoire/ucd:group/ucd:char ) ge 128">
        <xsl:copy-of select="$ucdTemp"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no">Warning: $UCD (<xsl:value-of select="$UCD"/>) does not seem to be a valid Unicode Character Database (grouped).</xsl:message>
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
    <!-- 
      Die early if there's an unprocessable param (just because dying
      at the right time takes a long time, at least in $whitespace case).
    -->
    <xsl:choose>
      <xsl:when test="not( $attrs = (0, 1, 9) )">
        <xsl:message terminate="yes">Invalid $attrs — should be 0, 1, or 9</xsl:message>
      </xsl:when>
      <xsl:when test="not( $fold = ( 0 to 2 ) )">
        <xsl:message terminate="yes">Invalid $fold — should be 0, 1, or 2</xsl:message>
      </xsl:when>
      <xsl:when test="not( $skip = ( 0 to 4 ) )">
        <xsl:message terminate="yes">Invalid $skip — should be 0, 1, 2, 3, or 4</xsl:message>
      </xsl:when>
      <xsl:when test="not( $whitespace = (0, 1, 3) )">
        <xsl:message terminate="yes">Invalid $whitespace: should be 0, 1, or 3</xsl:message>
      </xsl:when>
    </xsl:choose>
    <!-- pass1: generate a copy of input, handling the $skip and $attrs parameters -->
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
          <xsl:map-entry key="." select="count($seq[ . eq current() ])"/>
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
          <xsl:text disable-output-escaping="yes">
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
            }
            .val { font-family: monospace; font-size: 120%; }
            dt { font-weight: bold; font-size: 120%; font-family: monospace; margin: 1ex 0em 0em 0em; }
            li.true::marker { color: green; }
            li.false::marker { color: red; }
            li.true { list-style-type: square; }
            li.false { color:  grey; font-size: 97%; }
            li.true { color: black; font-size: 103%; }
          </xsl:text>
        </style>
      </head>
      <body>
        <h2>Character Counts in <xsl:value-of select="$fileName"/></h2>
        <p>Character counts in <tt><xsl:value-of
          select="$fileName"/></tt><a href="#fn1">¹</a>, using the
          following parameters:</p>
        <dl>
          <dt><span class="param">attrs</span></dt>
          <dd>
            <ul>
              <li class="{$attrs eq 0}"><span class="val">0</span>: drop <emph>all</emph> attributes</li>
              <li class="{$attrs eq 1}"><span class="val">1</span>: 
                <xsl:choose>
                  <xsl:when test="$input/tei:*">
                    keep all attributes except:
                    <ul>
                      <li>@assertedValue iff @locus is "value"</li>
                      <li>@baseForm</li>
                      <li>@expand, other than on &lt;classRef&gt;</li>
                      <li>@lemma</li>
                      <li>@orig</li>
                    </ul>
                  </xsl:when>
                  <xsl:when test="$input/wwp:* | $input/yaps:*">
                    keep only pre() and post() of @rend
                  </xsl:when>
                  <xsl:when test="$input/html:*">
                    keep only @title and @alt
                  </xsl:when>
                </xsl:choose> [default]
              </li>
              <li class="{$attrs eq 9}"><span class="val">9</span>: keep <emph>all</emph> attributes</li>
            </ul>
          </dd>
          <dt><span class="param">fold</span></dt>
          <dd>
            <ul>
              <li class="{$fold eq 0}"><span class="val">0</span>: no case folding [default]</li>
              <li class="{$fold eq 1}"><span class="val">1</span>: case folding (upper to lower, but A–Z <em>only</em>)</li>
              <li class="{$fold eq 2}"><span class="val">2</span>: case folding (including Greek, etc.) and also fold LATIN SMALL LETTER LONG S
                into LATIN SMALL LETTER S</li>
            </ul>
          </dd>
          <dt><span class="param">skip</span></dt>
          <dd>
            <ul>
              <li class="{$skip eq 0}"><span class="val">0</span>: process entire document, including comments and processing instructions</li>
              <li class="{$skip eq 1}"><span class="val">1</span>: process entire document <em>excluding</em> comments and processing instructions</li>
              <li class="{$skip eq 2}"><span class="val">2</span>: do 1, and also strip out metadata (<tt>&lt;teiHeader></tt> or <tt>&lt;html:head></tt>)</li>
              <li class="{$skip eq 3}"><span class="val">3</span>: do 2, and also strip out printing artifacts, etc. (<tt>&lt;tei:fw></tt>, <tt>&lt;wwp:mw></tt>, <tt>&lt;figDesc></tt>) [default]</li>
              <li class="{$skip eq 4}"><span class="val">4</span>: do 3, and also take <tt>&lt;corr&gt;</tt> over <tt>&lt;sic&gt;</tt>, <tt>&lt;expan&gt;</tt> over
                <tt>&lt;abbr&gt;</tt>, <tt>&lt;reg&gt;</tt> over <tt>&lt;orig&gt;</tt> and the first <tt>&lt;supplied&gt;</tt> or
                <tt>&lt;unclear&gt;</tt> in a <tt>&lt;choice&gt;</tt> (only makes sense for TEI and WWP; and for WWP this
                means counting the regularized version of each <tt>&lt;vuji></tt> character)</li>
            </ul>
          </dd>
          <dt><span class="param">whitespace</span></dt>
          <dd>
            <ul>
              <li class="{$whitespace eq 0}"><span class="val">0</span>: strip all whitespace [default]</li>
              <li class="{$whitespace eq 1}"><span class="val">1</span>: normalize whitespace</li>
              <li class="{$whitespace eq 3}"><span class="val">3</span>: keep all whitespace</li>
            </ul>
          </dd>
        </dl>
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
              <xsl:sort order="descending" select="$count_by_decimal_char_num(.)"/>
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
                  <xsl:variable as="element(ucd:char)" name="char"
                    select="($ucd/ucd:ucd/ucd:repertoire/ucd:group/ucd:char[@cp eq $hexNum4digit],$ucd/*)[1]"/>
                  <xsl:value-of select="wf:unicodeCharName($char)"/>
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
  <xsl:template mode="sa" match="tei:choice[tei:unclear|tei:supplied][not(tei:sic|tei:corr|tei:orig|tei:reg|tei:abbr|tei:expan)][$skip ge 4]" >
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  <xsl:template mode="sa" match="wwp:choice[wwp:unclear|wwp:supplied][$skip ge 4]" >
    <!--
      We don't have to be so precise for the WWP <choice>, because the WWP content model is
      much more restrictive than TEI, and does not allow bizarre combinations like
      <choice><sic/><expan/><supplied/></choice>, anyway
    -->
    <xsl:apply-templates select="*[1]" mode="#current"/>
  </xsl:template>
  <xsl:template mode="sa" match="wwp:vuji[$skip ge 4]">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template mode="sa" match="wwp:vuji/text()[$skip ge 4]">
    <xsl:choose>
      <xsl:when test=". eq 'VV' or . eq 'Vv'">W</xsl:when>
      <xsl:when test=". eq 'vv'">w</xsl:when>
      <xsl:otherwise><xsl:value-of select="translate( ., 'VUJIvuji','UVIJuvij')"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="sa" match="@*[$attrs eq 0]"/>
  <xsl:template mode="sa" match="tei:*/@*[$attrs eq 1]" priority="1">
    <xsl:if test="
         self::attribute(baseForm)
      or self::attribute(lemma)
      or self::attribute(orig)
      or ( self::attribute(assertedValue) and ../@locus eq 'value' )
      or ( self::attribute(expand) and not( parent::classRef ) )
      "><xsl:value-of select="wf:padme(.)"/></xsl:if>
  </xsl:template>
  <xsl:template mode="sa" match="html:*/@*[$attrs eq 1]">
    <xsl:if test="self::attribute(title) or self::attribute(alt)"><xsl:value-of select="wf:padme(.)"/></xsl:if>
  </xsl:template>
  <xsl:template mode="sa" match="wwp:*/@*[$attrs eq 1]">
    <xsl:if test="self::attribute(rend)">
      <xsl:if test="matches( .,'p(re|ost)\(')">
        <xsl:variable name="rend" select="."/>
        <xsl:variable name="rend" select="replace( $rend, $rlops, $pop )"/>
        <xsl:variable name="rend" select="replace( $rend, $rlcps, $pcp )"/>
        <xsl:variable name="pre">
          <xsl:analyze-string select="$rend" regex="pre\(([^)]*)\)">
            <xsl:matching-substring>
              <xsl:value-of select="replace( regex-group(1), $pop, $rlopr )"/>
            </xsl:matching-substring>
          </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="post">
          <xsl:analyze-string select="$rend" regex="post\(([^)]*)\)">
            <xsl:matching-substring>
              <xsl:value-of select="replace( regex-group(1), $pcp, $rlcpr )"/>
            </xsl:matching-substring>
          </xsl:analyze-string>
        </xsl:variable>
        <xsl:value-of select="wf:padme($pre||$post)"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  <xsl:template mode="sa" match="yaps:*/@*[$attrs eq 1]"/>
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

  <xsl:function name="wf:unicodeCharName" as="xs:string">
    <xsl:param name="thisChar" as="element(ucd:char)"/>
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
