<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:ucd="http://www.unicode.org/ns/2003/ucd/1.0"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:yaps="http://www.wwp.northeastern.edu/ns/yaps"
  xmlns:tmp="http://www.wwp.neu.edu/temp/ns"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="3.0">
  <!--
      Copyleft 2019 Syd Bauman and the Women Writers Project.
      Available under the terms of the MIT License. (See the
      accompanying README.md.)
  -->
  <xsl:output method="xhtml" indent="yes" encoding="UTF-8" html-version="5"/>

  <xsl:param name="UCD" select="'https://raw.githubusercontent.com/behnam/unicode-ucdxml/master/ucd.nounihan.grouped.xml'"/>
  <xsl:param name="debug" select="false()" as="xs:boolean" static="yes"/>
  <xsl:param name="attrs" select="1" as="xs:integer"/>
  <xsl:param name="fold" select="0" as="xs:integer"/>
  <xsl:param name="skip" select="3" as="xs:integer"/>
  <xsl:param name="whitespace" select="0" as="xs:integer"/>
  <xsl:param name="fileName" select="tokenize( base-uri(/), '/')[last()]"/>
  <xd:doc>
    <xd:desc>protect open paren, protect close paren: theses variables should
      each be set to any single character you <xd:b>know</xd:b> will not be in the input
      document. And they have to be different from each other, too.
      Only used for WWP.</xd:desc>
  </xd:doc>
  <xsl:param name="pop" select="'&#xFF08;'"/>
  <xsl:param name="pcp" select="'&#xFF09;'"/>
  <xd:doc>
    <xd:desc>rendition ladder (open|close) paren for search, and rendition ladder
      (open|close) paren for replace: escape sequences to match an open or close
      paren in a rendition ladder. Only used for WWP.</xd:desc>
  </xd:doc>
  <xsl:variable name="rlops" select="'\\\('"/>
  <xsl:variable name="rlcps" select="'\\\)'"/>
  <xsl:variable name="rlopr" select="'\\('"/>
  <xsl:variable name="rlcpr" select="'\\)'"/>
  <xd:doc>
    <xd:desc>attribute separator for debugging: should be any single character
    you <xd:b>know</xd:b> will not be in the input document. It is used to
    temporarily surround the values of attributes for debugging.</xd:desc>
  </xd:doc>
  <xsl:param name="as4d" select="'&#x0115C5;'"/>
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
  <xd:doc>
    <xd:desc>get a copy of the Unicode Character Database in which to
    look up character names.</xd:desc>
  </xd:doc>
  <xsl:variable name="ucdTemp">
    <xsl:choose>
      <xsl:when test="not( $UCD castable as xs:anyURI )">
        <!-- when will this clause *ever* be executed? -->
        <xsl:variable name="noUCDmsg" select="'String supplied for Unicode Character Database URI ('||$UCD||') is not actually a URI'"/>
        <xsl:message terminate="no" select="'Warning: '||$noUCDmsg"/>
        <html:span class="emsg"><xsl:value-of select="$noUCDmsg"/></html:span>
      </xsl:when>
      <xsl:when test="doc-available($UCD)">
        <xsl:copy-of select="document($UCD)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="noUCDmsg" select="'Unicode Character Database URI ('||$UCD||') not readable.'"/>
        <xsl:message terminate="no" select="'Warning: '||$noUCDmsg"/>
        <html:span class="emsg"><xsl:value-of select="$noUCDmsg"/></html:span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="ucd">
    <xsl:choose>
      <xsl:when test="count( $ucdTemp/ucd:ucd/ucd:repertoire/ucd:group/ucd:char ) ge 128">
        <xsl:copy-of select="$ucdTemp"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="noUCDmsg" select="'$UCD ('||$UCD||') does not seem to be a valid Unicode Character Database (grouped).'"/>
        <xsl:message terminate="no" select="'Warning: '||$noUCDmsg"/>
        <html:span class="emsg"><xsl:value-of select="$noUCDmsg"/></html:span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <!--
    Flip a coin iff attrs=1 to see if we should include or exclude attributes
    (Note that if the vocabularly is one we recognize, this is ignored and specific
    attributes are kept.)
    (Note also that we deliberately avoid a web request unless attrs=1, just to
    avoid the wait.)
    Thanks to Vincent Lizzi for the idea for generating a random number from inside
    XSLT without fn:random-number-generator() (which is not available in Saxon 9
    HE, although it is available in Saxon 10 HE).
  -->
  <xsl:variable name="coin" as="xs:boolean" select="
      if ($attrs eq 1) then
        if (doc-available('https://www.random.org/integers/') ) then
          unparsed-text('https://www.random.org/integers/?num=1&amp;min=0&amp;max=1&amp;col=1&amp;base=10&amp;format=plain&amp;rnd=new')
          cast as xs:boolean
        else
          ((
            ( current-time() cast as xs:string )
            => substring-after('.')
            => substring( 1, 1 )
          ) cast as xs:integer mod 2 )
            cast as xs:boolean
      else
        true()
      "/>

  <xd:doc>
    <xd:desc>Just copy stuff unless told otherwise …</xd:desc>
  </xd:doc>
  <xsl:template match="@*|node()" mode="#all" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/">
    <!-- 
      Die early if there's an unprocessable param (just because waiting
      until we would test the param anyway takes a long time, at least
      in $whitespace case).
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
    <xsl:result-document use-when="$debug"
      href="/tmp/{$andI}_debug_content.xml" indent="no" method="xml">
      <xsl:sequence select="$content"/>
    </xsl:result-document>
    <xsl:variable name="content" select="replace( $content, $as4d, '')"/>

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
        <!-- Because of unpocessable parameter test, above, we know no other value is possible -->
      </xsl:choose>
    </xsl:variable>
    <xsl:result-document use-when="$debug"
      href="/tmp/{$andI}_debug_bigString1.txt" indent="no" method="text">
      <xsl:sequence select="$bigString"/>
    </xsl:result-document>

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
        <!-- Because of unpocessable parameter test, above, we know no other value is possible -->
      </xsl:choose>
    </xsl:variable>
    <xsl:result-document use-when="$debug"
      href="/tmp/{$andI}_debug_bigString2.txt" indent="no" method="text">
      <xsl:sequence select="$bigString"/>
    </xsl:result-document>

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
        <xsl:for-each select="distinct-values( $seq )">
          <xsl:map-entry key="." select="count( $seq[ . eq current() ] )"/>
        </xsl:for-each>
      </xsl:map>
    </xsl:variable>

    <!-- Generate output -->
    <xsl:variable name="ucd_available" select="not( $ucd/html:span[@class eq 'emsg'] )"/>
    <html>
      <xsl:call-template name="html_head"/>
      <body>
        <h2>Character counts in <xsl:value-of select="$fileName"/></h2>
        <xsl:call-template name="explain_params"/>
        <xsl:if test="not( $ucd_available )">
          <p>Note: 4th column, character names, not rendered because <xsl:sequence select="$ucd"/></p>
        </xsl:if>
        <p>Click on a column header to sort by that column.</p>
        <table class="sortable" border="1">
          <thead>
            <tr>
              <th>count</th>
              <th>codepoint</th>
              <th>character</th>
              <xsl:if test="$ucd_available">
                <th>character name</th>
              </xsl:if>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="map:keys($count_by_decimal_char_num)">
              <xsl:sort order="descending" select="$count_by_decimal_char_num(.)"/>
              <xsl:variable name="hexNum" select="wf:decInt2hexDigits(.)"/>
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
                <xsl:if test="$ucd_available">
                  <td class="ucn">
                    <xsl:value-of select="wf:unicodeCharName( $hexNum4digit )"/>
                  </td>
                </xsl:if>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <p>Total characters: <xsl:sequence select="format-number( count( $seq ),'#,###,###,##0')"/>.
	<br/>Distinct characters: <xsl:sequence select="format-number( map:size($count_by_decimal_char_num),'#,###,##0')"/>.</p>
        <p>This table generated <xsl:value-of select="current-dateTime()"/>.</p>
        <hr/>
        <p name="fn1">¹ <xsl:value-of select="$me"/></p>
      </body>
    </html>
  </xsl:template>
  
  <!-- Handle "skip" and "attrs" parameters here in mode "sa" -->
  <xsl:template mode="sa" match="( processing-instruction() | comment() )[$skip eq 0]">
    <xsl:value-of select="wf:padme(.)"/>
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
        <!-- Remove keywords ’cause they are not characters -->
        <xsl:variable name="rend" select="replace( $rend, '#[A-Za-z0-9._-]+','')"/>
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
  <xsl:template mode="sa" match="*/@*[$attrs eq 1][$coin]" priority="0.9">
    <xsl:value-of select="wf:padme(.)"/>
  </xsl:template>
  <xsl:template mode="sa" match="@*[$attrs eq 9]">
    <xsl:value-of select="wf:padme(.)"/>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>
      <xd:p>This function modified from the function at
        https://www.oxygenxml.com/archives/xsl-list/200902/msg00214.html
        (It had two bugs: misplaced close paren, and 'gt' where 'ge' was needed.)
      </xd:p>
    </xd:desc>
    <xd:param name="dec">a non-negative (base 10) integer</xd:param>
    <xd:return>a string that represents the same integer in base 16 (using
    only uppercase letters)</xd:return>
  </xd:doc>
  <xsl:function name="wf:decInt2hexDigits" as="xs:string">
    <xsl:param name="dec" as="xs:integer"/>
    <xsl:sequence select="
      if ($dec eq 0) then '0'
      else concat(
        if ( $dec ge 16 ) then wf:decInt2hexDigits( $dec idiv 16 )
        else '',
        substring('0123456789ABCDEF', ($dec mod 16) + 1, 1 )
        )"/>
  </xsl:function>
  
  <xsl:function name="wf:padme" as="xs:string">
    <xsl:param name="stringIN"/>
    <xsl:value-of select="$as4d||$stringIN||$as4d"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>
      <xd:p>Given a code point, return the Unicode name(s) of a character.</xd:p>
      <xd:p>In the UCD, each character (other than those in certain groups of
      CJK, Tangut, or Nüshu ideographic characters) has at least one name;
      many have two names. The names are typically expressed on the
      <tt>@na</tt> attribute, and second names on the <tt>@na1</tt>
      attribute. But in some cases the only one name is expressed on
      <tt>@na1</tt>. Furthermore, when a name is not expressed on a
      <tt>@na</tt> or <tt>@na1</tt> attribute, sometimes the attribute
      is still present but just has no value. However, <tt>@na</tt>
      is only specified without a value for characters we should never
      see: DELETE and the PUA block.</xd:p>
    </xd:desc>
    <xd:param name="thisCodePoint">a 4-digit positive hexadecimal integer
      (expressed as a 4-character long xs:string).</xd:param>
    <xd:return>An xs:string that is either the Unicode name(s) or
      an error message.</xd:return>
  </xd:doc>
  <xsl:function name="wf:unicodeCharName" as="xs:string">
    <xsl:param name="thisCodePoint" as="xs:string"/>
    <xsl:variable name="thisChar" select="$ucd/ucd:ucd/ucd:repertoire/ucd:group/ucd:char[@cp eq $thisCodePoint]"/>
    <xsl:choose>
      <xsl:when test="not( exists( $thisChar) )">
        <xsl:variable name="msg" select="'Unable to ascertain Unicode name for '||$thisCodePoint"/>
        <xsl:message select="$msg"/>
        <xsl:value-of select="$msg"/>
      </xsl:when>
      <!-- both @na and @na1 -->
      <xsl:when test="$thisChar[@na  and  normalize-space(@na1) ne '']">
        <xsl:value-of select="$thisChar/@na||' or '||$thisChar/@na1"/>
      </xsl:when>
      <!-- either @na or @na1 -->
      <xsl:when test="$thisChar[@na or @na1]">
        <xsl:value-of select="( $thisChar/@na, $thisChar/@na1 )[1]"/>
      </xsl:when>
      <!-- neither? look to parent <ucd:group> -->
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

  <xd:doc>
    <xd:desc>Generate the metadata for the output HTML file</xd:desc>
  </xd:doc>
  <xsl:template name="html_head">
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
            .emsg {
              display: block;
              padding: 0.5ex 8em 0em 2em;
              font-family: monospace;
              color: #906060;
            }
            dt { font-weight: bold; font-size: 120%; font-family: monospace; margin: 1ex 0em 0em 0em; }
            li.true::marker { color: green; }
            li.false::marker { color: red; }
            li.true { list-style-type: square; }
            li.false { color:  grey; font-size: 97%; }
            li.true { color: black; font-size: 103%; }
          </xsl:text>
      </style>
    </head>
  </xsl:template>

  <xd:doc>
    <xd:desc>Generate the block that explains the parameters that could be
    used, and indicates which were actually used.</xd:desc>
  </xd:doc>
  <xsl:template name="explain_params">
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
                keep only:
                <ul>
                  <li>@assertedValue iff @locus is "value"</li>
                  <li>@baseForm</li>
                  <li>@expand, other than on &lt;classRef&gt;</li>
                  <li>@lemma</li>
                  <li>@orig</li>
                </ul>
              </xsl:when>
              <xsl:when test="$input/wwp:* | $input/yaps:*">
                keep only pre() and post() of @rend, and ignore keywords like “#rule” in those
              </xsl:when>
              <xsl:when test="$input/html:*">
                keep only @title and @alt
              </xsl:when>
              <xsl:otherwise expand-text="true">
                flipped a coin, it was
                {if ($coin) then 'heads' else 'tails'},
                so
                {if ($coin) then 'all attributes were kept' else 'all attributes were dropped'}.
              </xsl:otherwise>
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
  </xsl:template>

</xsl:stylesheet>
