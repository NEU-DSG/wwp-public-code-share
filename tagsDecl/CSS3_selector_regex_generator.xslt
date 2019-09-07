<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:out="http://www.w3.org/1999/XSL/Transform-NOT!"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"    version="3.0"
  xmlns:sb="http://bauman.zapto.org/ns-for-testing-CSS"
  xmlns:wi="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:ws="http://www.wwp-test.northeastern.edu/"
  xmlns:wpt="https://github.com/web-platform-tests/wpt"
  xmlns:w3c="https://www.w3.org/Style/CSS/Test/CSS3/Selectors/current/"
  xmlns:wo="http://wwo.wwp-test.northeastern.edu/WWO/css/wwo/wwo.css"
  xmlns:pt="https://github.com/benfrain/css-performance-tests" >
  <xd:doc scope="component">
    <xd:desc>Yes, that's a whole lot of namespaces. The majority
    are merely used to differentiate from where a given test case
    comes. The only ones actually used by the program are a:, rng:,
    out:, xsl: and (of course) xsl:.</xd:desc>
  </xd:doc>
  
  <xd:doc scope="stylesheet">
    <xd:desc>Generate a regex to validate CSS3 selectors</xd:desc>
  </xd:doc>
  
  <xd:doc scope="component">
    <xd:desc>We might be generating XSLT output, so we need to have a
      namespace synonym to allow us to refer to XSLT-as-output as
      opposed to XSLT-as-instructions.</xd:desc>
  </xd:doc>
  <xsl:namespace-alias stylesheet-prefix="out" result-prefix="xsl"/>

  <xsl:output method="xml" exclude-result-prefixes="#all" indent="yes"/>
  
  <xd:doc>
    <xd:desc>The $output parameter is defined as a URI, because sometimes
      it is, and even when it isn't a namespace URI (but rather just a token),
      it meets the syntactic constraints of a URI. I have to admit, I did not
      expect "Relax NG" to work as an xsd:anyURI (that is, to be castable as
      xs:anyURI), but it did. In any case, the point is that the user can
      specify whether to generate RELAX NG output (the default) or XSLT output
      by specifying any one of a number of tokens, including the namespace URI
      for the language.
    </xd:desc>
  </xd:doc>
  <xsl:param name="output" as="xs:anyURI" select="'Relax NG' cast as xs:anyURI"/>
  <xsl:variable name="outLang">
    <xsl:choose>
      <xsl:when test="$output = ('rng','rnc','RNG','RNC','RELAXNG','RELAX NG','RelaxNG','Relax NG','http://relaxng.org/ns/structure/1.0')">RNG</xsl:when>
      <xsl:when test="$output = ('xsl','xslt','XSL','XSLT','http://www.w3.org/1999/XSL/Transform')">XSL</xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes" select="'Fatal error: output type &quot;'||$output||'&quot; not recognized.'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xd:doc scope="component">
    <xd:desc>$now is the current timestamp w/o timezone, as a string.</xd:desc>
  </xd:doc>
  <xsl:variable name="now" select="substring( current-dateTime() cast as xs:string, 1, 19 )"/>
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:variable name="xmlName" select="'\\i\\c*'"/>
  <xsl:variable name="nonASCII" select="'\&amp;#x00A0;-\&amp;#x10FFFF;'"/>
  <xsl:variable name="lettersPlus" select="'a-zA-Z_'"/>
  <!-- define escape chars as identifier chars - (hex digit or newline) -->
  <xsl:variable name="identSansNewlineNorHexDigit" select="'['||$lettersPlus||$nonASCII||'-[a-fA-F0-9\&amp;#x0A;\&amp;#x0C;\&amp;#x0D;]]'"/>
  <!--  OR define as ALL chars - (hex digit or newline) ? -->
  <xsl:variable name="allSansNewlineNorHexDigit" select="'[&amp;#x21;-&amp;#x10FFFF;-[a-fA-F0-9\\n\\r\\t]]'"/>
  <xsl:variable name="neitherNewlineNorHexDigit" select="$allSansNewlineNorHexDigit"/>
  <xsl:variable name="escape" select="'\\\\('||$neitherNewlineNorHexDigit||'|[0-9a-fA-F]{1,6}\\s?)'"/>
  
  <!--  CSS 3 uses CSS 2.1 identifiers, which are very permissive -->
  <xsl:variable name="identinit" select="'(['||$lettersPlus||$nonASCII||']|'||$escape||')'"/>
  <xsl:variable name="identalso" select="'(['||$lettersPlus||$nonASCII||'0-9\\-]|'||$escape||')'"/>
  <xsl:variable name="ident" select="'-?'||$identinit||$identalso||'*'"/>
  
  <!--  universal and type selectors, e.g. *, *|*, duck, tei|titleStmt, *|span, svg|* -->
  <xsl:variable name="ns" select="'(('||$ident||'|\\*)?\\|)?'"/>	<!--  namespace prefix for univ or type -->
  <xsl:variable name="univ" select="'\\*'"/>   <!--  universal selector sans NS -->
  <xsl:variable name="type" select="$ident"/>  <!--  type selector sans NS -->
  <xsl:variable name="univtype" select="$ns||'('||$univ||'|'||$type||')'"/> <!--  either universal or type selector w/ NS -->
  
  <!--  attribute selectors, e.g. [type='chap'], [type~=rhyme], [xml:lang|='en'] -->
  <xsl:variable name="attname" select="$ns||$ident"/>		<!--  attribute name -->
  <xsl:variable name="attrop" select="'[\$~\*|^]?='"/>		<!--  operator -->
  <!--  attr value ID is a CSS 2.1 identifier (top value of U+10FFFF found in 10.2 of L3 spec) -->
  <!--  attr value string (w/ enclosing quotes escaped) -->
  <xsl:variable name="sqav" select="'\&amp;apos;([^\&amp;apos;]|\\\\&amp;apos;)*\&amp;apos;'"/> <!--  single quoted attr value -->
  <xsl:variable name="dqav" select="'\&amp;quot;([^\&amp;quot;]|\\\\&amp;quot;)*\&amp;quot;'"/> <!--  double quoted attr value -->
  <xsl:variable name="attval" select="'('||$sqav||'|'||$dqav||'|'||$ident||')'"/>        <!--  attr value - an ID or a string  -->
  <xsl:variable name="attribute" select="'\\[\\s*'||$attname||'\\s*('||$attrop||'\\s*'||$attval||'\\s*)?\\]'"/> <!--  attribute selector -->
  
  <!--  class selectors, e.g. ".3d" — although 10.1 of spec says it must be an identifier -->
  <xsl:variable name="CSS1class" select="'\\.\\c+'"/>	<!--  CSS1 allowed a class to start w/ a digit (unless followed by unit) -->
  <xsl:variable name="CSS2class" select="'\\.(\\\\[0-9]\\c*|\\c+)'"/>	<!--  CSS2 says an initial digit must be backslash-escaped -->
  <xsl:variable name="CSS21class" select="'\\.'||$ident"/>			<!--  CSS2.1 says an ID -->
  <xsl:variable name="class" select="$CSS21class"/>
  
  <!--  ID selectors, e.g. "#threeDim" -->
  <xsl:variable name="ID1" select="'#\\i\\c*'"/>	 <!--ID selector, reasonable -->
  <xsl:variable name="ID2" select="'#'||$ident"/>	<!--ID selector in CSS 3 uses CSS 2.1 identifier -->
  <xsl:variable name="ID" select="$ID2"/>
  
  <!--  lang regexp modified from http://schneegans.de/lv/ — NOT USED -->
  <xsl:variable name="lang" select="'((((([a-z]{2,3})(-([a-z]{3})){0,3})|([a-z]{4})|([a-z]{5,8}))(-([a-z]{4}))?(-([a-z]{2}|[0-9]{3}))?(-([a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*(-([a-z0-9-[x]](-[a-z0-9]{2,8})+))*(-x(-([a-z0-9]{1,8}))+)?)|(x(-([a-z0-9]{1,8}))+)|((en-GB-oed|i-ami|i-bnn|i-default|i-enochian|i-hak|i-klingon|i-lux|i-mingo|i-navajo|i-pwn|i-tao|i-tay|i-tsu|sgn-BE-FR|sgn-BE-NL|sgn-CH-DE)|(art-lojban|cel-gaulish|no-bok|no-nyn|zh-guoyu|zh-hakka|zh-min|zh-min-nan|zh-xiang)))'"/>
  
  <!--  lang regexp modified from https://github.com/sebinsua/ietf-language-tag-regex -->
  <!--  1) changed to Perl syntax -->
  <!--  2) combined $privateUse and $privateUse2, as they match the same -->
  <!--     stuff -->
  <!--  3) Note: I *left* the explicit case insensitivity for two reasons: -->
  <!--     1) I do not know of any way to ask a RELAX NG validator to apply -->
  <!--        a <param name="pattern"> case insensitively. -->
  <!--     2) Just to make it easier to compare to future versions. -->
  <xsl:variable name="regular" select="'(art-lojban|cel-gaulish|no-bok|no-nyn|zh-guoyu|zh-hakka|zh-min|zh-min-nan|zh-xiang)'"/>
  <xsl:variable name="irregular" select="'(en-GB-oed|i-ami|i-bnn|i-default|i-enochian|i-hak|i-klingon|i-lux|i-mingo|i-navajo|i-pwn|i-tao|i-tay|i-tsu|sgn-BE-FR|sgn-BE-NL|sgn-CH-DE)'"/>
  <xsl:variable name="grandfathered" select="'('||$irregular||'|'||$regular||')'"/>
  <xsl:variable name="privateUse" select="'(x(-[A-Za-z0-9]{1,8}).)'"/>
  <xsl:variable name="singleton" select="'[0-9A-WY-Za-wy-z]'"/>
  <xsl:variable name="extension" select="'('||$singleton||'(-[A-Za-z0-9]{2,8}).)'"/>
  <xsl:variable name="variant" select="'([A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3})'"/>
  <xsl:variable name="region" select="'([A-Za-z]{2}|[0-9]{3})'"/>
  <xsl:variable name="script" select="'([A-Za-z]{4})'"/>
  <xsl:variable name="extlang" select="'([A-Za-z]{3}(-[A-Za-z]{3}){0,2})'"/>
  <xsl:variable name="language" select="'(([A-Za-z]{2,3}(-'||$extlang||')?)|[A-Za-z]{4}|[A-Za-z]{5,8})'"/>
  <xsl:variable name="langtag" select="'('||$language||'(-'||$script||')?'||'(-'||$region||')?'||'(-'||$variant||')*'||'(-'||$extension||')*'||'(-'||$privateUse||')?'||')'"/>
  <xsl:variable name="languageTag" select="'('||$grandfathered||'|'||$langtag||'|'||$privateUse||')'"/>

  <!--  several of the structural pseudo-classes take an argument of the form "aN+b|odd|even", -->
  <!--  where N is a literal 'n', and 'a' and 'b' are optional (possibly signed) integers -->
  <!--  (but note that if 'b' is negative, the '+' is dropped, thus 12n-1, not 12n+-1). -->
  <xsl:variable name="N" select="'\\s*([+\\-]?\\s*[0-9]*n(\\s*[+\\-]?\\s*[0-9]+)?|[+\\-]?\\s*[0-9]+|odd|even)\\s*'"/>
  
  <xsl:variable name="pseudo_class_sans_not" select="':(link|visited|hover|active|focus|target|lang\\('||$languageTag||'\\)|enabled|disabled|checked|root|nth(-last)?-child\\('||$N||'\\)|nth(-last)?-of-type\\('||$N||'\\)|(first|last|only)-(child|of-type)|empty)'"/>
  <xsl:variable name="simple_selector_sans_not" select="'('||$univtype||'|'||$attribute||'|'||$class||'|'||$ID||'|'||$pseudo_class_sans_not||')'"/>
  <xsl:variable name="not" select="':not\\('||$simple_selector_sans_not||'\\)'"/>
  <xsl:variable name="pseudo_class" select="$pseudo_class_sans_not||'|'||$not"/>
  <xsl:variable name="pseudo_element" select="'::?(first-(line|letter)|before|after)'"/> <!--  CSS3 requires the second colon, but CSS1 and CSS2 did not -->
  
  <xsl:variable name="combinator" select="'[>+~&amp;#x20;&amp;#x09;&amp;#x0A;&amp;#x0D;]'"/> <!--  U+0C is allowed by CSS3, but not by XML -->
  <xsl:variable name="simple_selector" select="'('||$univtype||'|'||$attribute||'|'||$class||'|'||$ID||'|'||$pseudo_class||')'"/> <!--  at the moment, unused -->
  <xsl:variable name="simple_sans" select="'('||$attribute||'|'||$class||'|'||$ID||'|'||$pseudo_class||')'"/> <!--  simple selector w/o Type and Universal selectors  -->
  <xsl:variable name="sequence_of_simple_selectors" select="'('||$univtype||')?('||$simple_sans||')*'"/> <!--  See [1]. -->
  <xsl:variable name="selector" select="$sequence_of_simple_selectors||'(\\s*'||$combinator||'\\s*'||$sequence_of_simple_selectors||')*('||$pseudo_element||')?'"/>
  <xsl:variable name="selectors" select="$selector||'(,\\s*'||$selector||')*'"/>
  <!--  DEBUGGing can be performed by changing the value of $regexp from -->
  <!--  $selectors to some component thereof, e.g. $pseudo_class -->
  <xsl:variable name="regexp" select="'\\s\*'||$selectors||'\\s\*'"/>	<!--  we add the anchors (if needed) later -->
  
  <xd:doc>
    <xd:desc>OK, let's do this thing.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:message select="'Debug: outLang='||$outLang||'&#x0A;'"/>
    <xsl:choose>
      <xsl:when test="$outLang eq 'RNG'">
        <grammar 
          xmlns="http://relaxng.org/ns/structure/1.0"
          xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
          xmlns:sb="http://bauman.zapto.org/ns-for-testing-CSS"
          xmlns:wi="http://www.wwp.northeastern.edu/ns/textbase"
          xmlns:ws="http://www.wwp-test.northeastern.edu/"
          xmlns:wpt="https://github.com/web-platform-tests/wpt"
          xmlns:w3c="https://www.w3.org/Style/CSS/Test/CSS3/Selectors/current/"
          xmlns:wo="http://wwo.wwp-test.northeastern.edu/WWO/css/wwo/wwo.css"
          xmlns:pt="https://github.com/benfrain/css-performance-tests"    
          datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
          <xsl:comment> This grammar written <xsl:value-of select="$now"/> by ./CSS3_selector_regex_generator.xslt </xsl:comment>
          <start>
            <ref name="ANY"/>
          </start>
          <define name="ANY">
            <element>
              <anyName/>
              <zeroOrMore>
                <attribute>
                  <anyName>
                    <except>
                      <name>selector</name>
                    </except>
                  </anyName>
                </attribute>
              </zeroOrMore>
              <optional>
                <attribute name="selector">
                  <data type="string">
                    <param name="pattern"><xsl:value-of select="$regexp"/></param>
                  </data>
                </attribute>
              </optional>
              <zeroOrMore>
                <choice>
                  <text/>
                  <ref name="ANY"/>
                </choice>
              </zeroOrMore>
            </element>
          </define>
          <xsl:call-template name="debuggingOutput"/>
        </grammar>
      </xsl:when>
      <xsl:when test="$outLang eq 'XSL'">
        <out:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:sb="http://bauman.zapto.org/ns-for-testing-CSS"
          xmlns:wi="http://www.wwp.northeastern.edu/ns/textbase"
          xmlns:ws="http://www.wwp-test.northeastern.edu/"
          xmlns:wpt="https://github.com/web-platform-tests/wpt"
          xmlns:w3c="https://www.w3.org/Style/CSS/Test/CSS3/Selectors/current/"
          xmlns:wo="http://wwo.wwp-test.northeastern.edu/WWO/css/wwo/wwo.css"
          xmlns:pt="https://github.com/benfrain/css-performance-tests"    
          xsl:exclude-result-prefixes="#all"
          version="3.0">
          <xsl:text>&#x0A;</xsl:text>
          <xsl:comment> This pgm written <xsl:value-of select="$now"/> by ./CSS3_selector_regex_generator.perl </xsl:comment>
          <xsl:text>&#x0A;</xsl:text>
          <out:variable name="apos" select='"&apos;"'/> <!-- not used at the moment -->
          <out:variable name="quot" select="'&quot;'"/> <!-- not used at the moment -->
          <out:variable name="selector_regex">
            <out:text><xsl:value-of select="$regexp"/></out:text>
          </out:variable>
          <out:variable name="anchored_selector_regex" select="'^'||$selector_regex"/>
          
          <out:output method="text"/>
          
          <out:template match="/">
            <out:text>&#x0A;</out:text>
            <out:apply-templates select="//*[@selector]"/>
          </out:template>
          
          <out:template match="*">
            <out:value-of select="'selector “'
              ||@selector
              ||'” is&#x09;&#x09;'"/>
            <out:if test="not( matches( @selector, $anchored_selector_regex,'i') )">NOT </out:if>
            <out:value-of select="'valid.&#x0A;'"/>
          </out:template>
          
          <xsl:call-template name="debuggingOutput"/>

        </out:stylesheet>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes" select="'Internal fatal error: incomprehensible $outLang ('||$outLang||').'"/>
      </xsl:otherwise>
    </xsl:choose>
    <!--<xsl:message select="$regexp"/>-->
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Generate debugging code by copying over any and all
    elements in the input that have a @selector attribute.</xd:desc>
  </xd:doc>
  <xsl:template name="debuggingOutput">
    <xsl:if test="//@selector">
      <xsl:comment> ========= debugging ========= </xsl:comment>
      <xsl:comment>
  legend:
    pt = performance test suite
    wpt = W3C web platform tests for CSS
    w3c = W3C test suite, last retrieved 2019-06-01
    ws = WWP CSS stylesheets, i.e. from website
    wi = WWP instances 
    wo = WWO CSS stylesheet, i.e. for Women Writers Online textbase viewing site
    sb = dreamt up by yours truly
      </xsl:comment>
      <xsl:comment>
  Note: the wpt and w3c sets are very very similar, but not quite
    identical; it is not clear to me there is any real advantage in
    running both, but I am interested in having a lot of test cases
    too see how fast this is, too. Thus both are included.
    </xsl:comment>
      <xsl:apply-templates select="//*[@selector]" mode="copy"/>
      <xsl:comment> ========= end debugging ========= </xsl:comment>    
    </xsl:if>
  </xsl:template>

  <xd:doc>
    <xd:desc>Standard copy template, but it is only used to copy over
    elements that have a @selector attribute.</xd:desc>
  </xd:doc>
  <xsl:template match="*[@selector] | @*" mode="copy" exclude-result-prefixes="#all">
    <xsl:copy>
      <xsl:apply-templates exclude-result-prefixes="#all" select="@*|node()" mode="copy"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>The "debugging_storage_unit" template should never be fired. It
    is just a depot where we store a set of elements to be copied over into
    the output so that the output can be used on itself (either to validate
    itself iff RNG or to transform itself iff XSLT) to test the regexp.</xd:desc>
  </xd:doc>
  <xsl:template name="debugging_storage_unit" exclude-result-prefixes="#all">
  <wi:rendition selector="head">align(center)case(allcaps)post(#rule)</wi:rendition>
  <wi:rendition selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="a.cent" selector="speaker, head">align(center)</wi:rendition>
  <wi:rendition xml:id="a.left" selector="label">align(left)slant(upright)</wi:rendition>
  <wi:rendition xml:id="a.left" selector="lg">align(left)</wi:rendition>
  <wi:rendition xml:id="a.right" selector="ref">align(right)break(no)slant(upright)</wi:rendition>
  <wi:rendition xml:id="a.speaker" selector="speaker">align(left)place(outside)slant(italic)</wi:rendition>
  <wi:rendition xml:id="allcaps" selector="">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="b.yes" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="br.y" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="break.center" selector="mw">align(center) break(yes)</wi:rendition>
  <wi:rendition xml:id="break.first-indent" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="break.indent" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="breakaligncaps" selector="head, titlePart">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="breakyes" selector="item">break(yes)</wi:rendition>
  <wi:rendition xml:id="c.break" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="c.fw" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="c.head" selector="head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="c.head" selector="label, head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="c.speaker" selector="speaker">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="c.titleblock" selector="titleBlock">align(center)</wi:rendition>
  <wi:rendition xml:id="center" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="centerallcaps" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="centersmallcaps" selector="speaker">align(center)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="div" selector="div">post(#rule)</wi:rendition>
  <wi:rendition xml:id="dquotes" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="emph" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="f-ind.1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="f.i" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="f.indent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="head" selector="head">align(center)case(allcaps)post(#rule)</wi:rendition>
  <wi:rendition xml:id="i.mcr" selector="mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="i.mcr" selector="persName, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="i.one" selector="rs">indent(1)</wi:rendition>
  <wi:rendition xml:id="i.placename" selector="emph, mcr, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="indentme" selector="p, item, note">indent(1)</wi:rendition>
  <wi:rendition xml:id="italics" selector="emph, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="note.align" selector="note">align(outer)slant(italic)</wi:rendition>
  <wi:rendition xml:id="note.align" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="p" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="p.in" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="p.ind" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="p.left" selector="note">place(left)</wi:rendition>
  <wi:rendition xml:id="para" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="prepostquo" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="prepostquotes" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="q" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="q.m" selector="said">pre(‟)post(”)</wi:rendition>
  <wi:rendition xml:id="q.mark" selector="said">pre(“)post(”)bestow((pre(“))(lb))</wi:rendition>
  <wi:rendition xml:id="quotemarks" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.1ind" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.actor" selector="actor">slant(italic)align(left)break(no)post(,)</wi:rendition>
  <wi:rendition xml:id="r.actor" selector="actor">slant(italic)post(.)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.alcentcaps" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.align" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="r.align" selector="mw">break(no)align(right)</wi:rendition>
  <wi:rendition xml:id="r.align" selector="roleDesc">align(right)break(no)</wi:rendition>
  <wi:rendition xml:id="r.aligncenter" selector="ref">align(center)</wi:rendition>
  <wi:rendition xml:id="r.alignoutside" selector="mw">align(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.alignr" selector="">align(right)</wi:rendition>
  <wi:rendition xml:id="r.alignr" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="r.alignr" selector="mw, label">align(right)break(no)</wi:rendition>
  <wi:rendition xml:id="r.allcaps" selector="emph">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.allcaps" selector="hi">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.allcaps" selector="mcr">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.allcaps" selector="mcr, speaker">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.allcaps" selector="speaker">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.alrib" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.alrightbreak" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="r.arg" selector="argument">break(yes)align(left)slant(italic)indent(1)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.arg" selector="argument">break(yes)slant(italic)align(left)indent(1)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.arg" selector="argument">first-indent(-1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.argu" selector="argument">bestow((first-indent(0)indent(+1))(p))</wi:rendition>
  <wi:rendition xml:id="r.argu" selector="argument">first-indent(-1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.argument" selector="argument">break(yes)align(left)first-indent(0)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.argument" selector="argument">break(yes)first-indent(0)indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.argument" selector="argument">break(yes)slant(italic)first-indent(0)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.argument" selector="argument">first-indent(-1)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.argument" selector="argument">slant(italic)indent(1)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.bibl" selector="bibl">bestow((break(yes))(bibl))</wi:rendition>
  <wi:rendition xml:id="r.bibl" selector="bibl">break(yes)align(center)face(roman)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.bibl" selector="bibl">slant(italic)break(no)</wi:rendition>
  <wi:rendition xml:id="r.bibl" selector="bibl">slant(italic)pre(—)post(.)</wi:rendition>
  <wi:rendition xml:id="r.bkalc" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.bot" selector="note">place(bottom)</wi:rendition>
  <wi:rendition xml:id="r.brar" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="bibl">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="bibl, item">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="closer, epigraph">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="closer, opener">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="head">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="item">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw">break(yes)align(outside)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw, item, trailer, closer">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw, label">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="mw, salute">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="opener">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="ps">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="salute, bibl, signed, label">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="sp">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="stage">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.break" selector="trailer">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.breakIndent" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.breakit" selector="castItem">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.breakup" selector="mw">break(yes)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.brk" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.ca" selector="label">case(allcaps)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.caps" selector="">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.caps" selector="hi">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.caps" selector="mcr">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.caps" selector="signed">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.caption" selector="ab">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="r.castitem" selector="castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.catch" selector="catch">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="r.ce" selector="mw, docTitle">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.cen" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="r.cen" selector="head">align(center)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.cen" selector="head, docTitle">align(center)</wi:rendition>
  <wi:rendition xml:id="r.cent" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="head">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="head, label">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="label">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="mw">align(center) break(yes)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="ref">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="titleBlock">align(center)</wi:rendition>
  <wi:rendition xml:id="r.center" selector="titlePart">align(center)</wi:rendition>
  <wi:rendition xml:id="r.centerallcaps" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.centercaps" selector="label, trailer">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.centit" selector="head">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="r.closer" selector="closer">align(right)slant(upright)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.closer" selector="closer">indent(3)first-indent(2)</wi:rendition>
  <wi:rendition xml:id="r.closer" selector="closer">indent(4)</wi:rendition>
  <wi:rendition xml:id="r.contents" selector="rs">bestow((first-indent(0)indent(1))(rs))</wi:rendition>
  <wi:rendition xml:id="r.ctr" selector="label">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.ctr" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="r.dateline" selector="dateline">break(no)first-indent(1)slant(italic)post(—)</wi:rendition>
  <wi:rendition xml:id="r.dateline" selector="dateline">break(yes)align(right)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.dateline" selector="dateline">pre(“)right-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.div" selector="div">post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.div" selector="div">pre(#rule)</wi:rendition>
  <wi:rendition xml:id="r.doublequotes" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.em" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.emph" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.epi" selector="epigraph">indent(+3)</wi:rendition>
  <wi:rendition xml:id="r.epi" selector="epigraph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.epigraph" selector="epigraph">align(center)</wi:rendition>
  <wi:rendition xml:id="r.face" selector="l">face(blackletter)</wi:rendition>
  <wi:rendition xml:id="r.fi" selector="sp">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.first" selector="item, sp">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.first-indent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.firsti" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.firstind" selector="lg">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.firstind" selector="p">first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.firstindent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.firstindent1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.foreign" selector="foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">align(center)break(no)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">align(right)break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">align(right)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)align(outside)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)align(right)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">break(yes)place(outside)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">place(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.fw" selector="mw">slant(italic)align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.gloss" selector="gloss">break(yes)first-indent(1)indent(2)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)break(yes)case(allcaps)post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)case(allcaps)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)case(allcaps)post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)pre(#ornament)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">align(center)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)case(allcaps)post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)case(allcaps)pre(#rule)post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)case(mixed)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)slant(italic)pre(#rule)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">break(yes)align(center)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">case(allcaps) align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">case(allcaps)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">post(.)align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head">slant(upright)case(allcaps)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, label">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, label">break(yes)align(center)post(.)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, speaker">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, speaker">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, speaker">break(yes)indent(1)first-indent(0)face(roman)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, titleBlock">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, titlePart">align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, titlePart">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, titlePart">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="head, trailer">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.head" selector="titlePart, head">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.hi" selector="hi">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.hi" selector="hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.hi" selector="hi">slant(italic)case(mixed)</wi:rendition>
  <wi:rendition xml:id="r.hi" selector="hi">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.in" selector="">align(left)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.in" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.in" selector="speaker">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.in1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.ind" selector="">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.ind" selector="advertisement">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.ind" selector="lg">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.ind" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="">indent(2)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p">first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p">first-indent(1)align(left)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p">indent(0)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.indent" selector="p, closer">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.init" selector="speaker">align(left)indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, distinct, mentioned, foreign, soCalled, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, distinct, soCalled, term, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr, persName, name, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr, persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr, placeName, persName, name, measure">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, mcr, speaker, term, opener">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, name, quote, foreign, mcr, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, persName, name, placeName, title, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="emph, soCalled, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign, emph, mcr, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign, mentioned, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="foreign, soCalled, name, mcr, q, quote, persName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="hi, emph, mcr, item">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, distinct, emph, foreign, soCalled, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, emph, author, foreign, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, emph, author, foreign, soCalled">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, name, placeName, persName, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, persName, name, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, name, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, quote, bibl">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, quote, bibl, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, quote, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, placeName, persName, quote, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, hi, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, persName, placeName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, persName, placeName, hi, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, persName, placeName, name, bibl, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, persName, placeName, name, q, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, placeName, name, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, placeName, persName, quote, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, placeName, persName, speaker">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, q, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mcr, title, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="mentioned, term, mcr, foreign, distinct">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="name, placeName, emph, mcr, q">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="name, placeName, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="name, placeName, persName, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="note">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, bibl, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, castItem, role, rs, emph, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, emph, mcr, quote, placeName, ref">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, foreign, placeName, scene, title, name, term, distinct">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, mcr, quote, emph, foreign, placeName, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, mcr, quote, placeName, bibl, name, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, measure">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, role, hi, rs, emph, foreign, placeName, l, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, role, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, role, roleDesc, rs, emph, mcr, foreign, placeName, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, role, rs, emph, foreign, placeName, l, q, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, name, role, rs, roleDesc, emph, foreign, placeName, lg, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, foreign, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, mcr, emph, foreign, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, mcr, roleDesc, speaker">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, mcr, title, name, foreign, quote, hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, name, emph, foreign, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, name, mcr, emph, bibl, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, name, mcr, emph, term, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, name, mcr, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, name, mcr, q, quote, title">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, role">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, speaker, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, placeName, stage, mcr, roleDesc">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, quote, placeName, emph, soCalled">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, salute, title">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="persName, term, placeName, mcr, name, speaker, emph, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, label">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, name, emph, mcr, hi, foreign, measure">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName, mcr, distinct, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName, name, mcr, speaker">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="placeName, persName, title, role, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="q, quote, name, persName, placeName, emph, mcr, title, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="q, quote, persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="quote, emph, hi, rs, name, persName, title, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="quote, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="rs, mcr, foreign, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="rs, placeName, persName, mcr, emph, quote, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="speaker">slant(italic)indent(1)break(no)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="speaker, persName, placeName, mcr, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="stage, mcr, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="term, soCalled, mcr, foreign, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.it" selector="title">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.ital" selector="emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.ital" selector="persName, quote, placeName, abbr, bibl, name, mcr, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.ital" selector="rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="emph, gloss, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign, mcr, hi, persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign, mcr, hi, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign, mcr, hi, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="foreign, mcr, persName, placeName, hi, bibl, name, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="hi, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="hi, measure">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr, emph, foreign, speaker">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr, emph, placeName, persName, name, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr, gloss">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="mcr, hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="persName, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="persName, placeName, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="persName, placeName, name, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="placeName, mcr, bibl">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="quote, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="quote, mentioned, foreign, persName, placeName, name, mcr, title">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="roleDesc, stage, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italic" selector="speaker, mcr, emph, hi, mentioned, gloss">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.italics" selector="emph, mcr, persName, name, hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.itbreak" selector="stage">slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.itbyinp" selector="speaker">slant(italic)break(yes)indent(1)post(.␣)</wi:rendition>
  <wi:rendition xml:id="r.item" selector="item">first-indent(0)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.item" selector="item">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.itemlist" selector="item">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.l" selector="l">align(left)</wi:rendition>
  <wi:rendition xml:id="r.l" selector="l">break(no)</wi:rendition>
  <wi:rendition xml:id="r.l" selector="l">indent(1)</wi:rendition>
  <wi:rendition xml:id="r.l" selector="l">indent(4)</wi:rendition>
  <wi:rendition xml:id="r.l" selector="l">slant(italic)indent(2)</wi:rendition>
  <wi:rendition xml:id="r.la" selector="label">align(center)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(center)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(center)break(yes)case(smallcaps)post(.)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(center)case(allcaps)post(.)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">align(left)break(no)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">break(no)slant(upright)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">break(yes)post(.)align(left)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">indent(1)case(mixed)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">pre(()post())</wi:rendition>
  <wi:rendition xml:id="r.label" selector="label">slant(italic)indent(2)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.label" selector="term">align(center)post(.)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.lang" selector="persName, name, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.left" selector="castItem">break(yes)align(left)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="">indent(3)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">align(left)indent(0)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">bestow((indent(3))(lb))</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">face(roman)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">indent(+2)bestow((case(mixed)slant(italic))(head))</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">indent(0)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">indent(2)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">indent(2)break(no)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.lg" selector="lg">slant(italic)bestow((indent(3))(lb))</wi:rendition>
  <wi:rendition xml:id="r.line" selector=""/>
  <wi:rendition xml:id="r.line" selector="l">align(left)indent(+1)bestow((indent(+1))(lb))</wi:rendition>
  <wi:rendition xml:id="r.line" selector="l">bestow((indent(+1))(l))</wi:rendition>
  <wi:rendition xml:id="r.line" selector="l, p">indent(0)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.mcr" selector="list, mcr">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.mcr" selector="mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(center)break(yes)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(outside)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(right)break(no)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(no)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(yes)align(left)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(yes)align(outside)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">place(outside)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw">place(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.mw" selector="mw, label">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="item">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="lg">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="mw">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="opener">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="p">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="p, role, actor">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobreak" selector="p, sp, lg">break(no)</wi:rendition>
  <wi:rendition xml:id="r.nobrk" selector="label">break(no)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">break(yes)align(left)slant(italic)place(outside)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">break(yes)first-indent(1)place(inline)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">first-indent(1)indent(0)align(left)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">place(bottom)align(center)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">place(end)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">place(inset-outside)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">pre(#rule*)place(bottom)align(center)</wi:rendition>
  <wi:rendition xml:id="r.note" selector="note">slant(italic)place(outside)</wi:rendition>
  <wi:rendition xml:id="r.noteplace" selector="note">place(right)</wi:rendition>
  <wi:rendition xml:id="r.open" selector="opener">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="r.opener" selector="opener">align(center)</wi:rendition>
  <wi:rendition xml:id="r.opener" selector="opener">case(allcaps)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.out" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="r.outside" selector="mw">align(outside)</wi:rendition>
  <wi:rendition xml:id="r.outside" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="item, p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">align(left)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">break(no)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">break(no)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">break(yes)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(0)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(1)align(left)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">first-indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.p" selector="p">slant(italic)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.page" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.pageNum" selector="mw">align(outside)</wi:rendition>
  <wi:rendition xml:id="r.pagenumber" selector="mw">align(outside)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">break(yes)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">break(yes)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">break(yes)indent(0)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">break(yes)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">first-indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">indent(0)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">indent(0)first-indent(+1)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">indent(0)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">indent(0)first-indent(0)break(no)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p">indent(0)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.para" selector="p, item">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.parens" selector="stage">pre(()post())</wi:rendition>
  <wi:rendition xml:id="r.pb" selector="pb">border(#rule)</wi:rendition>
  <wi:rendition xml:id="r.persName" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.persName" selector="persName">case(smallcaps)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.persName" selector="persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.persname" selector="persName">case(allcaps)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.persname" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.persname" selector="persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.pgnum" selector="mw">align(outside)</wi:rendition>
  <wi:rendition xml:id="r.placeName" selector="placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.placeend" selector="note">place(end)</wi:rendition>
  <wi:rendition xml:id="r.placename" selector="placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.placeoutside" selector="mw">place(outside)</wi:rendition>
  <wi:rendition xml:id="r.poem" selector="lg">align(left)indent(2)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.post" selector="speaker">slant(italic)indent(1)post(. )</wi:rendition>
  <wi:rendition xml:id="r.postrule" selector="div">post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.prepostquo" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.prpo" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q">break(yes)indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q">pre(‘)post(’)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q, quote">post(”)pre(“)bestow((pre(‘)post(’))(q quote))</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q, quote, said">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="q, quote, title, gloss">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="said">bestow((pre(‘)post(’))(q quote title))post(”)pre(“)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="said">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="said">pre(“)post(”)bestow((pre(‘)post(’))(q quote title))</wi:rendition>
  <wi:rendition xml:id="r.q" selector="said, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="said, quote">slant(upright)pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.q" selector="title, quote, q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quo" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quo" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quo" selector="quote, q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quo" selector="quote, said">pre(‘)post(’)bestow((pre(“)post(”))(quote said))</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="q, quote, title">pre(“)post(”)bequeath((pre(‘)post(’))(q quote))</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote">pre(‘)post(’)</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote, q">bestow((pre(“))(p dateline salute))</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote, q">pre()post()</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote, q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote, q, gloss, mentioned">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.quote" selector="quote, said">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.ref" selector="ref">align(right)</wi:rendition>
  <wi:rendition xml:id="r.ref" selector="ref">align(right)fill(#leader)</wi:rendition>
  <wi:rendition xml:id="r.ref" selector="ref">align(right)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.ref" selector="ref">break(no)align(right)</wi:rendition>
  <wi:rendition xml:id="r.ref" selector="ref">slant(upright)align(right)</wi:rendition>
  <wi:rendition xml:id="r.reftype" selector="ref">align(right)fill()</wi:rendition>
  <wi:rendition xml:id="r.ri" selector="">align(right)</wi:rendition>
  <wi:rendition xml:id="r.right" selector="">align(right)</wi:rendition>
  <wi:rendition xml:id="r.right" selector="dateline">align(right)</wi:rendition>
  <wi:rendition xml:id="r.right" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="r.right" selector="ref">align(right)</wi:rendition>
  <wi:rendition xml:id="r.rightalign" selector="dateline, time">align(right)</wi:rendition>
  <wi:rendition xml:id="r.role" selector="role">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.role" selector="role">slant(italic)align(center)break(no)post(,)</wi:rendition>
  <wi:rendition xml:id="r.roledesc" selector="roleDesc">slant(upright)align(right)break(no)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">break(yes)align(left)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">first-indent(0)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">indent(1)first-indent(-1)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">indent(1)first-indent(0)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">pre(—)post(.)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.rs" selector="rs, argument">slant(italic)break(yes)indent(1)first-indent(-1)</wi:rendition>
  <wi:rendition xml:id="r.rt" selector="">align(right)fill(-)</wi:rendition>
  <wi:rendition xml:id="r.rule" selector="div">post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.rule" selector="div">pre(#rule)</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said">pre(‘)post(’)</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said">pre(“)</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said">pre(“)post(”)bequeath((pre(“)post(”))(lb))</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said, floatingText">pre(“)post(”)bestow((pre(“))(lb))</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said, floatingText, quote">pre(“)post(”)bestow((pre(“))(lb))</wi:rendition>
  <wi:rendition xml:id="r.said" selector="said, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="r.sal" selector="salute">indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.salute" selector="">indent(1)slant(upright)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.salute" selector="salute">align(center)slant(upright)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.salute" selector="salute">break(yes)align(left)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.salute" selector="salute">break(yes)pre(“)right-indent(4)</wi:rendition>
  <wi:rendition xml:id="r.salute" selector="salute">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.scaps" selector="hi">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.scaps" selector="mcr">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.sig" selector="mw">align(right)right-indent(2)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.sign" selector="signed">align(right)right-indent(1)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">align(right)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">align(right)right-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">break(yes)pre(“)post(”)case(smallcaps)right-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">case(allcaps)align(right)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.signed" selector="signed">slant(italic)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.slit" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.sm" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smallcaps" selector="">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smallcaps" selector="hi">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smallcaps" selector="hi, persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smallcaps" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smallcaps" selector="placeName, persName, hi">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smcap" selector="mcr, emph">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.smcaps" selector="placeName, persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="sp">break(no)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="sp">break(yes)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="sp">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="speaker">break(yes)case(allcaps)align(center)post(.)</wi:rendition>
  <wi:rendition xml:id="r.sp" selector="speaker">case(smallcaps)align(center)</wi:rendition>
  <wi:rendition xml:id="r.spaceabove" selector="lg">space-above()</wi:rendition>
  <wi:rendition xml:id="r.speak" selector="speaker">align(center)</wi:rendition>
  <wi:rendition xml:id="r.speak" selector="speaker">align(center)case(allcaps)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.speak" selector="speaker">post(.)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.speak" selector="speaker">slant(italic)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">align(center)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">align(center)case(smallcaps)post(.)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">align(left)slant(italic)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">break(no)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">break(no)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">break(yes)align(center)case(smallcaps)post(.)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">break(yes)indent(1)face(roman)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">case(smallcaps)align(center)slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)align(left)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)align(left)indent(2)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)break(no)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)indent(1)break(yes)post(.)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)post(.)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.speaker" selector="speaker">slant(italic)post(.—)</wi:rendition>
  <wi:rendition xml:id="r.speech" selector="sp">first-indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.spk" selector="speaker">slant(italic)break(yes)indent(1)</wi:rendition>
  <wi:rendition xml:id="r.spkr" selector="speaker">slant(italic)break(yes)indent(1)post(.␣)</wi:rendition>
  <wi:rendition xml:id="r.spkr" selector="speaker">slant(italic)break(yes)indent(2)post(.␣)</wi:rendition>
  <wi:rendition xml:id="r.st" selector="stage">slant(italic)break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">align(right)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">align(right)slant(italic)pre([)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">align(right)slant(italic)pre(()break(no)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">break(no)slant(italic)place(inset-right)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">break(yes)align(right)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">post(.)align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">pre(()slant(italic)break(no)align(right)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)bestow((slant(upright))(persName))</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)break(no)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)break(yes)align(right)pre([)</wi:rendition>
  <wi:rendition xml:id="r.stage" selector="stage">slant(italic)pre(()post())break(no)</wi:rendition>
  <wi:rendition xml:id="r.text" selector="text">face(blackletter)</wi:rendition>
  <wi:rendition xml:id="r.title" selector="titlePart">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.titleblock" selector="titleBlock">align(center)</wi:rendition>
  <wi:rendition xml:id="r.titlepart" selector="titlePart">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.tr" selector="trailer">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="r.trail" selector="trailer">align(center)case(allcaps)slant(italic)post(#rule)</wi:rendition>
  <wi:rendition xml:id="r.trailer" selector="trailer">align(center)slant(italic)pre([)post(])</wi:rendition>
  <wi:rendition xml:id="r.trailer" selector="trailer">slant(italic)align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="r.trailer" selector="trailer">slant(italic)break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="abbr, hi, q">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="hi">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="label">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="mcr, hi, name, placeName, persName, quote">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="p">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="persName, orgName, placeName, hi, mcr">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="ref">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.up" selector="speaker, persName, placeName, name, mcr">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.upfi" selector="p">slant(upright)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="r.upright" selector="">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.upright" selector="mcr, quote, placeName, persName">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.upright" selector="persName">slant(upright)</wi:rendition>
  <wi:rendition xml:id="r.yesbreak" selector="castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="rbreak" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.actor" selector="">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.actor" selector="actor">align(right)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.albreak" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.alcen" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.alcent" selector="label">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.alcentbr" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.alct" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.alct" selector="titlePart">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.ali.ct" selector="titleBlock, head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.alig" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.align" selector="">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.align" selector="align">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.align" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.align" selector="mw">align(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.alignright" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.allcaps" selector="">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.allcaps" selector="titlePart, head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.allcaps" selector="titlePart, head">case(allcaps)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.alri" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.alri" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.alribr" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.alriitbr" selector="mw, stage">align(right)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.alslital" selector="stage">align(right)pre([)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.arg" selector="argument">align(left)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.argument" selector="argument">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.bk" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.bkalr" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.bl" selector="text">face(blackletter)</wi:rendition>
  <wi:rendition xml:id="rend.br" selector="item, mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.br" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="head">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="item">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw">break(yes)slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw, l">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw, label, lg">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw, p, head, salute, closer">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw, sp, lg, castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="mw, titlePart">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="p, mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="salute, closer, p">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="sp">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="sp, castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="sp, mw, castItem">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="titlePart, docImprint, docDate, p, head">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.break" selector="titlePart, docImprint, mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.breakcent" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.breakit" selector="p">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.breakright" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.breleftit" selector="speaker">slant(italic)align(left)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.brk" selector="titlePart">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.brrig" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.caps" selector="">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.caps" selector="head">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.caps" selector="salute">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.catch" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.catch" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.cen" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.cen" selector="head, epigraph">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.cent" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.centall" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.center" selector="">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.center" selector="epigraph">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.center" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.center" selector="titlePart, epigraph, head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.centit" selector="">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.centit" selector="head">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.centit" selector="trailer">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.close" selector="closer">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.cntr" selector="">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.cntr.allcaps" selector="">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.cntr.allcaps" selector="head">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.col" selector="mw">columns(1)align(outside)</wi:rendition>
  <wi:rendition xml:id="rend.complex" selector="head, label">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.ctitb" selector="head">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.ctitb" selector="head, stage">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.ctitb" selector="head, stage, note, trailer">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.ctr" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.dateline" selector="dateline">align(right)right-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.div" selector="div">post(#ornament)</wi:rendition>
  <wi:rendition xml:id="rend.div" selector="div">post(#rule)</wi:rendition>
  <wi:rendition xml:id="rend.dot" selector="label">post(.)</wi:rendition>
  <wi:rendition xml:id="rend.emph" selector="emph">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.emph" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.emph" selector="emph, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.face" selector="text">face(blackletter)</wi:rendition>
  <wi:rendition xml:id="rend.fin" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.fin1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.fir" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.first-indent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.firstindent" selector="item">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.firstindent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">align(center)place(top)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw">break(yes)face(blackletter)</wi:rendition>
  <wi:rendition xml:id="rend.fw" selector="mw, head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.h" selector="head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.he" selector="head">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)case(allcaps)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">case(allcaps)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">case(allcaps)align(center)post(#rule)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">face(roman)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head">slant(italic)pre(#ornament)align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head, respLine">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head, speaker">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="head, titlePart, respLine, docImprint">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.head" selector="titlePart, head">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.hi" selector="hi">case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.hi" selector="hi">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.i" selector="persName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.in" selector="">indent(-1)</wi:rendition>
  <wi:rendition xml:id="rend.in" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.in1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.inbre" selector="p">first-indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.inbrk" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.ind" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.ind1" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.indent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.indent" selector="p">indent(0)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="rend.indent" selector="p">indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.indent" selector="speaker">indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.indent2" selector="epigraph">indent(2)</wi:rendition>
  <wi:rendition xml:id="rend.indentit" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.indentit" selector="speaker">indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.indentit" selector="speaker">slant(italic)indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, dateline, closer, lg, salute, foreign, mcr, persName, placeName, rs, title, name, term, mentioned, q, measure, abbr, soCalled">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, dateline, closer, salute, foreign, mcr, persName, placeName, rs, title, name, term, q, quote, measure, abbr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, hi, quote, q, rs, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, mcr, distinct">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, mcr, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, mcr, hi, lg, quote, q, rs, title, persName, placeName, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, name, persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, persName, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, q, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, q, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, quote, q, rs, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="emph, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="foreign, argument, emph, hi, placeName, persName, quote, bibl, term, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="foreign, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="foreign, persName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="mcr, emph, hi, placeName, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="mcr, emph, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="mcr, emph, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="mcr, head, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="name, persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="note">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, emph, mentioned">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, emph, placeName, foreign, speaker, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, foreign, name, placeName, mcr, emph, salute, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, foreign, placeName, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, foreign, placeName, name, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, name, placeName, title, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, name, placeName, title, mcr, emph, salute">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, emph, mcr, foreign, hi">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, emph, stage, lg, rs, name, speaker, foreign, title, mcr, role">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, mcr, name, q, emph, abbr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, rs, emph, name">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, placeName, speaker, rs, foreign, emph, name, title, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="persName, soCalled, foreign, term, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, head, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, mcr, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, mcr, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, orgName, name, emph, mcr, rs, q, foreign, soCalled, item, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, q, quote, emph, foreign, name, rs, title">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, quote, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, persName, rs, emph, orgName, name, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="placeName, rs, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="quote, persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="quote, persName, foreign">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="role, persName, placeName, name, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="salute, emph, dateline, closer, foreign, mcr, persName, placeName, name, q, quote, speaker, measure, abbr, term">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="salute, emph, dateline, closer, foreign, mcr, persName, placeName, rs, title, name, term, q, quote, measure, abbr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="salute, regMe">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="speaker, stage, mcr, hi, foreign, term, distinct">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.it" selector="term, mcr, name, persName, placeName, emph, label, foreign, quote">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.ita" selector="roleDesc, foreign, emph, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.ital" selector="name, publisher, placeName, persName, emph, lg, role">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.italic" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.italic" selector="persName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.italic" selector="persName, placeName">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.italic" selector="placeName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.itin" selector="speaker">indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.itout" selector="note">slant(italic)place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.label" selector="label">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.label" selector="label">break(yes)align(center)post(.)</wi:rendition>
  <wi:rendition xml:id="rend.lg" selector="lg">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.lg" selector="lg">slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.mcr" selector="mcr">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.mcr" selector="mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.mcr" selector="mcr">slant(upright)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.mw" selector="mw">align(right)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.mw" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.mw" selector="mw">break(yes)align(outside)</wi:rendition>
  <wi:rendition xml:id="rend.mw" selector="mw">place(outside)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.n" selector="note">place(outside)face(blackletter)</wi:rendition>
  <wi:rendition xml:id="rend.no" selector="p">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="advertisement">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="item">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="label">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="list, item, label">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="p">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="p, sp, lg">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.nobreak" selector="q">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.note" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.note" selector="note">place(outside)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.note" selector="note">slant(italic)place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.notep" selector="note">bequeath((first-indent(0)break(no)align(left))(p))</wi:rendition>
  <wi:rendition xml:id="rend.out" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.outit" selector="note">slant(italic)place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">break(no)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">break(no)first-indent(0)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p">first-indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.p" selector="p, item">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.pagenum" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.para" selector="p">break(yes)first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.paraindent" selector="">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.paraindent" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.persname" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.place.out" selector="">place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.placeout" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.plout" selector="note">place(outside)</wi:rendition>
  <wi:rendition xml:id="rend.pn" selector="mw">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.pn" selector="mw">break(yes)align(right)</wi:rendition>
  <wi:rendition xml:id="rend.pn" selector="mw, titlePart">break(yes)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.ppquote" selector="quote, q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.pre.star" selector="anchor">pre(*)</wi:rendition>
  <wi:rendition xml:id="rend.prepl" selector="note">place(outside)pre()</wi:rendition>
  <wi:rendition xml:id="rend.preru" selector="div">pre(#rule)</wi:rendition>
  <wi:rendition xml:id="rend.q" selector="q">bestow((pre(“))(l))</wi:rendition>
  <wi:rendition xml:id="rend.q" selector="q">post(”)bestow((pre(“))(l))</wi:rendition>
  <wi:rendition xml:id="rend.q" selector="q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.q" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.q" selector="q, quote">pre(“)post(”)bestow((pre(“))(l))</wi:rendition>
  <wi:rendition xml:id="rend.qmark" selector="q, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.quote" selector="q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.quote" selector="quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.quote" selector="quote, q">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.quotes" selector="said, quote">pre(“)post(”)</wi:rendition>
  <wi:rendition xml:id="rend.right" selector="closer">align(right)break(yes)face(roman)</wi:rendition>
  <wi:rendition xml:id="rend.right" selector="mw">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.right" selector="ref">align(right)</wi:rendition>
  <wi:rendition xml:id="rend.role" selector="role">align(left)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.roledesc" selector="roleDesc">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.roman" selector="foreign, lg, persName, placeName, q, quote, mcr, title, titlePart">face(roman)</wi:rendition>
  <wi:rendition xml:id="rend.romup" selector="name">slant(upright)face(roman)</wi:rendition>
  <wi:rendition xml:id="rend.rs" selector="rs">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.rtbt" selector="mw">align(right)place(bottom)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.sal" selector="salute">case(allcaps)indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.salute" selector="salute">break(yes)indent(1)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.salute" selector="salute">case(allcaps)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.signed" selector="signed">align(right)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.slant" selector="emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.smc" selector="role">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.smcp" selector="">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.smcp" selector="emph, persName, placeName, mcr">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.smcp" selector="persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.sp" selector="sp">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.sp" selector="sp">indent(1)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.sp" selector="speaker">post(.␣)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.sp" selector="speaker">slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.spe" selector="sp">break(yes)first-indent(+1)</wi:rendition>
  <wi:rendition xml:id="rend.spe" selector="speaker">align(left)</wi:rendition>
  <wi:rendition xml:id="rend.spea" selector="speaker">break(no)indent(1)slant(italic)post(␣)</wi:rendition>
  <wi:rendition xml:id="rend.speak" selector="speaker">align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.speak" selector="speaker">align(left)indent(1)slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.speak" selector="speaker">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="rend.speaker" selector="speaker">indent(1)align(left)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.speaker" selector="speaker">slant(italic)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.spkr" selector="speaker">slant(italic)post(. )indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.spkr" selector="speaker">slant(italic)post(.)indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.spkr" selector="speaker">slant(italic)post(.␣)indent(1)</wi:rendition>
  <wi:rendition xml:id="rend.st" selector="stage">break(yes)slant(italic)align(center)</wi:rendition>
  <wi:rendition xml:id="rend.sta" selector="stage">break(no)case(mixed)slant(italic)bestow((slant(upright)case(smallcaps))(persName))</wi:rendition>
  <wi:rendition xml:id="rend.stage" selector="stage">align(center)slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.stage" selector="stage">break(yes)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.stage" selector="stage">slant(italic)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.title" selector="">align(center)</wi:rendition>
  <wi:rendition xml:id="rend.titlepart" selector="titlePart">align(center)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.titlepart" selector="titlePart">align(center)break(yes)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="trailer">align(center)case(allcaps)break(yes)face(roman)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="trailer">align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="trailer">align(center)slant(italic)case(allcaps)break(yes)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="trailer">break(yes)align(center)case(allcaps)</wi:rendition>
  <wi:rendition xml:id="rend.trailer" selector="trailer">break(yes)align(center)slant(italic)</wi:rendition>
  <wi:rendition xml:id="rend.up" selector="emph, name, persName, placeName, rs, bibl">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.up" selector="hi">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.up" selector="persName">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.up" selector="persName, hi">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.upright" selector="hi, emph">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.upright" selector="label">slant(upright)</wi:rendition>
  <wi:rendition xml:id="rend.yes" selector="mw">break(yes)</wi:rendition>
  <wi:rendition xml:id="rfirst" selector="p">first-indent(1)</wi:rendition>
  <wi:rendition xml:id="rhead" selector="head">align(center)</wi:rendition>
  <wi:rendition xml:id="rit" selector="persName, placeName, mcr">slant(italic)</wi:rendition>
  <wi:rendition xml:id="s.center" selector="speaker">align(center)slant(upright)case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="s.ital" selector="mcr, name, persName, emph">slant(italic)</wi:rendition>
  <wi:rendition xml:id="sc" selector="mcr, emph, persName">case(smallcaps)</wi:rendition>
  <wi:rendition xml:id="smallcaps" selector="speaker">case(smallcaps)</wi:rendition>
  <xsl:comment> ********* </xsl:comment>
  <wpt:rendition selector="li,p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[title$='bar'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|foo|='bar'], *|*[html|lang|='en'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|foo|='bar'], *|*[html|lang|='en'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title^='si on'], *|*[title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title^='si on'], *|*[title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title$='tait'], p[|title$='tait'] "/>
  <wpt:rendition selector="*|*[|title$='tait'], *|*[html|title$='tait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title$='tait'], *|*[html|title$='tait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title*='hanta'], p[|title*='hanta'] "/>
  <wpt:rendition selector="*|*[|title*='hanta'], *|*[html|title*='hanta'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|title*='hanta'], *|*[html|title*='hanta'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title='si on chantait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title='si on chantait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|class~='deux'], *|*[*|foo~='deux'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|class~='deux'], *|*[*|foo~='deux'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[*|lang|='en'], *|*[a|foo|='un-d'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[*|lang|='en'], *|*[a|foo|='un-d'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title$='tait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title$='tait'] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[title*='bar'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title*='on ch'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="*|*[*|title*='on ch'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title='si on chantait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title='si on chantait'] "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|q "/>
  <wpt:rendition selector="*|*[|class~='foo'] "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|q "/>
  <wpt:rendition selector="*|*[|class~='foo'] "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|q "/>
  <wpt:rendition selector="*|*[|lang|='foo-bar'], *|*[|myattr|='tat-tut'] "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|q "/>
  <wpt:rendition selector="*|*[|lang|='foo-bar'], *|*[|myattr|='tat-tut'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title^='si on'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title$='tait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title$='tait'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title*='on ch'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[|title*='on ch'] "/>
  <wpt:rendition selector="*|p, *|l "/>
  <wpt:rendition selector="div.test * "/>
  <wpt:rendition selector="div.test *:not(a|p) "/>
  <wpt:rendition selector="div.test *:not(*|div)"/>
  <wpt:rendition selector="div.test &gt; *:not(*|p):not(*|div) "/>
  <wpt:rendition selector="div.stub &gt; *:not(*|div) "/>
  <wpt:rendition selector="div.stub &gt; *"/>
  <wpt:rendition selector="div.stub &gt; *:not(|p) "/>
  <wpt:rendition selector="div.stub &gt; *|l &gt; *:not(|p) "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not(a|*) "/>
  <wpt:rendition selector="div.stub v "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not(*|*) "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not(|*) "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not(|*) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="div.stub *:not([a|title='foo']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r, *|s "/>
  <wpt:rendition selector="div.stub *:not([a|title='foo']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|foo~='bar']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|foo~='bar']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|foo|='bar']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|foo|='bar']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title*='hanta']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|s "/>
  <wpt:rendition selector="div.stub *|*:not([a|title*='hanta']) "/>
  <wpt:rendition selector="li "/>
  <wpt:rendition selector=".t1 "/>
  <wpt:rendition selector="li.t2 "/>
  <wpt:rendition selector=".t3 "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([*|title]) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([*|title]) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([*|title='si on chantait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([*|title='si on chantait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p.deu, *|q "/>
  <wpt:rendition selector="div.stub html|*:not([*|class~='deux']),"/>
  <wpt:rendition selector="div.stub *|*:not(html|*):not([*|foo~='deux']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p.deu, *|q "/>
  <wpt:rendition selector="div.stub html|*:not([*|class~='deux']),"/>
  <wpt:rendition selector="div.stub *|*:not(html|*):not([*|foo~='deux']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p.foo, *|q, *|s "/>
  <wpt:rendition selector="div.stub html|*:not([*|lang|='en']),"/>
  <wpt:rendition selector="div.stub *|*:not(html|*):not([a|foo|='un-d']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p.foo, *|q, *|s "/>
  <wpt:rendition selector="div.stub html|*:not([*|lang|='en']),"/>
  <wpt:rendition selector="div.stub *|*:not(html|*):not([a|foo|='un-d']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title*='on ch']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|p.red, *|q, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([*|title*='on ch']) "/>
  <wpt:rendition selector="*|q, *|r "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([|title]) "/>
  <wpt:rendition selector="*|q, *|r "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="div.stub *|*:not([|title]) "/>
  <wpt:rendition selector="*|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title='si on chantait']) "/>
  <wpt:rendition selector="*|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title='si on chantait']) "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|address, *|r "/>
  <wpt:rendition selector="div.stub *|*:not([|class~='foo']) "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|address, *|r "/>
  <wpt:rendition selector="div.stub *|*:not([|class~='foo']) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p.t1 "/>
  <wpt:rendition selector="p.t2 "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="div.teST "/>
  <wpt:rendition selector="div.te "/>
  <wpt:rendition selector="div.st "/>
  <wpt:rendition selector="div.te.st "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|address, *|r "/>
  <wpt:rendition selector="div.stub *|*:not([|lang|='foo-bar']) "/>
  <wpt:rendition selector="*|p, *|address, *|q, *|r "/>
  <wpt:rendition selector="*|address, *|r "/>
  <wpt:rendition selector="div.stub *|*:not([|lang|='foo-bar']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title^='si on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title$='tait']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title*='on ch']) "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s, *|t"/>
  <wpt:rendition selector="*|q, *|s, *|t "/>
  <wpt:rendition selector="div.stub *|*:not([|title*='on ch']) "/>
  <wpt:rendition selector="div :not(:enabled):not(:disabled) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=odd] "/>
  <wpt:rendition selector="line:nth-of-type(odd) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=odd] "/>
  <wpt:rendition selector="line:nth-of-type(odd) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=match] "/>
  <wpt:rendition selector="line:nth-child(3n-1) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=match] "/>
  <wpt:rendition selector="line:nth-child(3n-1) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=match] "/>
  <wpt:rendition selector="line:nth-last-of-type(3n-1) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="line "/>
  <wpt:rendition selector="[type~=match] "/>
  <wpt:rendition selector="line:nth-last-of-type(3n-1) "/>
  <wpt:rendition selector="[hidden] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:empty "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".t1.fail "/>
  <wpt:rendition selector=".fail.t1 "/>
  <wpt:rendition selector=".t2.fail "/>
  <wpt:rendition selector=".fail.t2 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p.t1.t2 "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="div.t1 "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address.t5.t5 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".t1:not(.t2) "/>
  <wpt:rendition selector=":not(.t2).t1 "/>
  <wpt:rendition selector=".t2:not(.t1) "/>
  <wpt:rendition selector=":not(.t1).t2 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not(.t1):not(.t2) "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="div:not(.t1) "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:not(.t5):not(.t5) "/>
  <wpt:rendition selector="li "/>
  <wpt:rendition selector="#t1 "/>
  <wpt:rendition selector="li#t2 "/>
  <wpt:rendition selector="li#t3 "/>
  <wpt:rendition selector="#t4 "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:empty "/>
  <wpt:rendition selector=".text "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p, "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".5cm "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".\5cm "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".two\ words "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".one.word "/>
  <wpt:rendition selector=".one\.word "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="foo &amp; address, p "/>
  <wpt:rendition selector="foo &amp; address, p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="foo &amp; address, p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="[*=test] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="[*|*=test] "/>
  <wpt:rendition selector="::selection "/>
  <wpt:rendition selector=":selection "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="#test#fail "/>
  <wpt:rendition selector="#fail#test "/>
  <wpt:rendition selector="#fail "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="#pass#pass "/>
  <wpt:rendition selector=".warning "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="#Aone#Atwo, #Aone#Athree, #Atwo#Athree "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="#Bone#Btwo, #Bone#Bthree, #Btwo#Bthree "/>
  <wpt:rendition selector="#Cone#Ctwo, #Cone#Cthree, #Ctwo#Cthree "/>
  <wpt:rendition selector="#Done#Dtwo, #Done#Dthree, #Dtwo#Dthree "/>
  <wpt:rendition selector="p.test a "/>
  <wpt:rendition selector="p.test *:link "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:subject"/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p   * "/>
  <wpt:rendition selector="p &gt; * "/>
  <wpt:rendition selector="p + * "/>
  <wpt:rendition selector="p ~ * "/>
  <wpt:rendition selector=":canvas "/>
  <wpt:rendition selector=":viewport "/>
  <wpt:rendition selector=":window "/>
  <wpt:rendition selector=":menu "/>
  <wpt:rendition selector=":table "/>
  <wpt:rendition selector=":select "/>
  <wpt:rendition selector="::canvas "/>
  <wpt:rendition selector="::viewport "/>
  <wpt:rendition selector="::window "/>
  <wpt:rendition selector="::menu "/>
  <wpt:rendition selector="::table "/>
  <wpt:rendition selector="::select "/>
  <wpt:rendition selector="p:first-letter "/>
  <wpt:rendition selector="p::first-letter "/>
  <wpt:rendition selector="p::first-letter "/>
  <wpt:rendition selector="p:first-letter "/>
  <wpt:rendition selector="p:first-line "/>
  <wpt:rendition selector="p::first-line "/>
  <wpt:rendition selector="p::first-line "/>
  <wpt:rendition selector="p:first-line "/>
  <wpt:rendition selector="span:before "/>
  <wpt:rendition selector="span::before "/>
  <wpt:rendition selector="span::before "/>
  <wpt:rendition selector="span:before "/>
  <wpt:rendition selector="span:after "/>
  <wpt:rendition selector="span::after "/>
  <wpt:rendition selector="span::after "/>
  <wpt:rendition selector="span:after "/>
  <wpt:rendition selector="p.test a "/>
  <wpt:rendition selector="p.test *:visited "/>
  <wpt:rendition selector="span "/>
  <wpt:rendition selector="span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span"/>
  <wpt:rendition selector=".span "/>
  <wpt:rendition selector=".span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span"/>
  <wpt:rendition selector=".span "/>
  <wpt:rendition selector=".span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span"/>
  <wpt:rendition selector="p.span "/>
  <wpt:rendition selector="p:not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span)"/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child"/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".fail "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA[|attribute] "/>
  <wpt:rendition selector="testB[|attribute='fail'] "/>
  <wpt:rendition selector="testC[|attribute~='fail'] "/>
  <wpt:rendition selector="testD[|attribute^='fail'] "/>
  <wpt:rendition selector="testE[|attribute*='fail'] "/>
  <wpt:rendition selector="testF[|attribute$='fail'] "/>
  <wpt:rendition selector="testG[|attribute|='fail'] "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA[|attribute] "/>
  <wpt:rendition selector="testB[|attribute='fail'] "/>
  <wpt:rendition selector="testC[|attribute~='fail'] "/>
  <wpt:rendition selector="testD[|attribute^='fail'] "/>
  <wpt:rendition selector="testE[|attribute*='fail'] "/>
  <wpt:rendition selector="testF[|attribute$='fail'] "/>
  <wpt:rendition selector="testG[|attribute|='fail'] "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA[*|attribute] "/>
  <wpt:rendition selector="testB[*|attribute='pass'] "/>
  <wpt:rendition selector="testC[*|attribute~='pass'] "/>
  <wpt:rendition selector="testD[*|attribute^='pass'] "/>
  <wpt:rendition selector="testE[*|attribute*='pass'] "/>
  <wpt:rendition selector="testF[*|attribute$='pass'] "/>
  <wpt:rendition selector="testG[*|attribute|='pass'] "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA[*|attribute] "/>
  <wpt:rendition selector="testB[*|attribute='pass'] "/>
  <wpt:rendition selector="testC[*|attribute~='pass'] "/>
  <wpt:rendition selector="testD[*|attribute^='pass'] "/>
  <wpt:rendition selector="testE[*|attribute*='pass'] "/>
  <wpt:rendition selector="testF[*|attribute$='pass'] "/>
  <wpt:rendition selector="testG[*|attribute|='pass'] "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA[*|attribute='pass'] "/>
  <wpt:rendition selector="testB[*|attribute='pass'] "/>
  <wpt:rendition selector="tests, tests * "/>
  <wpt:rendition selector="testA:not([*|attribute='pass']) "/>
  <wpt:rendition selector="testB:not([*|attribute='pass']) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".13 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".\13 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".\31 \33 "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not(#other).class:not(.fail).test#id#id "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="div:not(#theid).class:not(.fail).test#theid#theid "/>
  <wpt:rendition selector="div:not(#other).notclass:not(.fail).test#theid#theid "/>
  <wpt:rendition selector="div:not(#other).class:not(.test).test#theid#theid "/>
  <wpt:rendition selector="div:not(#other).class:not(.fail).nottest#theid#theid "/>
  <wpt:rendition selector="div:not(#other).class:not(.fail).nottest#theid#other "/>
  <wpt:rendition selector="p:selection "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="p::first-child "/>
  <wpt:rendition selector="div "/>
  <wpt:rendition selector="p:not(:first-line) "/>
  <wpt:rendition selector="p:not(:after) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="span:first-line "/>
  <wpt:rendition selector="span::first-line "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:first-line "/>
  <wpt:rendition selector="p::first-line "/>
  <wpt:rendition selector="p:hover "/>
  <wpt:rendition selector="a:hover "/>
  <wpt:rendition selector="tr:hover "/>
  <wpt:rendition selector="td:hover "/>
  <wpt:rendition selector="table "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:first-letter "/>
  <wpt:rendition selector="p::first-letter "/>
  <wpt:rendition selector=".cs "/>
  <wpt:rendition selector=".cs P "/>
  <wpt:rendition selector=".cs .a "/>
  <wpt:rendition selector=".cs .span1 span "/>
  <wpt:rendition selector=".cs .span2 "/>
  <wpt:rendition selector=".cs .span2 SPAN "/>
  <wpt:rendition selector=".cs .span2 span "/>
  <wpt:rendition selector=".ci "/>
  <wpt:rendition selector=".ci P "/>
  <wpt:rendition selector=".ci .a "/>
  <wpt:rendition selector=".ci .span1 span "/>
  <wpt:rendition selector=".ci .span2 SPAN "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="foo\:bar "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="..test "/>
  <wpt:rendition selector=".foo..quux "/>
  <wpt:rendition selector=".bar. "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[class$=''] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[class^=''] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[class*=''] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not([class$='']) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not([class^='']) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not([class*='']) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".a a:hover "/>
  <wpt:rendition selector=".b a:hover "/>
  <wpt:rendition selector=".b a:link "/>
  <wpt:rendition selector=".c :link "/>
  <wpt:rendition selector=".c :visited:hover "/>
  <wpt:rendition selector="div:hover &gt; p:first-child "/>
  <wpt:rendition selector=":link, :visited "/>
  <wpt:rendition selector=":link:hover span "/>
  <wpt:rendition selector="a:active "/>
  <wpt:rendition selector="button:active "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="a:focus "/>
  <wpt:rendition selector="p:target "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:target "/>
  <wpt:rendition selector=":root "/>
  <wpt:rendition selector=":target "/>
  <wpt:rendition selector="ul &gt; li "/>
  <wpt:rendition selector="li:lang(en-GB) "/>
  <wpt:rendition selector="button "/>
  <wpt:rendition selector="input "/>
  <wpt:rendition selector="button:enabled "/>
  <wpt:rendition selector="input:enabled "/>
  <wpt:rendition selector="button "/>
  <wpt:rendition selector="input "/>
  <wpt:rendition selector="button:disabled "/>
  <wpt:rendition selector="input:disabled "/>
  <wpt:rendition selector="input, span "/>
  <wpt:rendition selector="input:checked, input:checked + span "/>
  <wpt:rendition selector="html "/>
  <wpt:rendition selector="*:root "/>
  <wpt:rendition selector=":root:first-child "/>
  <wpt:rendition selector=":root:last-child "/>
  <wpt:rendition selector=":root:only-child "/>
  <wpt:rendition selector=":root:nth-child(1) "/>
  <wpt:rendition selector=":root:nth-child(n) "/>
  <wpt:rendition selector=":root:nth-last-child(1) "/>
  <wpt:rendition selector=":root:nth-last-child(n) "/>
  <wpt:rendition selector=":root:first-of-type "/>
  <wpt:rendition selector=":root:last-of-type "/>
  <wpt:rendition selector=":root:only-of-type "/>
  <wpt:rendition selector=":root:nth-of-type(1) "/>
  <wpt:rendition selector=":root:nth-of-type(n) "/>
  <wpt:rendition selector=":root:nth-last-of-type(1) "/>
  <wpt:rendition selector=":root:nth-last-of-type(n) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="* html "/>
  <wpt:rendition selector="* :root "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="ul &gt; li:nth-child(odd) "/>
  <wpt:rendition selector="ol &gt; li:nth-child(even) "/>
  <wpt:rendition selector="table.t1 tr:nth-child(-n+4) "/>
  <wpt:rendition selector="table.t2 td:nth-child(3n+1) "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="ul &gt; li:nth-child(odd) "/>
  <wpt:rendition selector="ol &gt; li:nth-child(even) "/>
  <wpt:rendition selector="table.t1 tr:nth-child(-n+4) "/>
  <wpt:rendition selector="table.t2 td:nth-child(3n+1) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="ul &gt; li:nth-last-child(odd) "/>
  <wpt:rendition selector="ol &gt; li:nth-last-child(even) "/>
  <wpt:rendition selector="table.t1 tr:nth-last-child(-n+4) "/>
  <wpt:rendition selector="table.t2 td:nth-last-child(3n+1) "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="ul &gt; li:nth-last-child(odd) "/>
  <wpt:rendition selector="ol &gt; li:nth-last-child(even) "/>
  <wpt:rendition selector="table.t1 tr:nth-last-child(-n+4) "/>
  <wpt:rendition selector="table.t2 td:nth-last-child(3n+1) "/>
  <wpt:rendition selector="* "/>
  <wpt:rendition selector="ul, p "/>
  <wpt:rendition selector="*.t1 "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:nth-of-type(3) "/>
  <wpt:rendition selector="dl &gt; :nth-of-type(3n+1) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:nth-last-of-type(3) "/>
  <wpt:rendition selector="dl &gt; :nth-last-of-type(3n+1) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 td:first-child "/>
  <wpt:rendition selector="p &gt; *:first-child "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 td:last-child "/>
  <wpt:rendition selector="p &gt; *:last-child "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:first-of-type "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:last-of-type "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:only-child "/>
  <wpt:rendition selector="div.testText &gt; div &gt; p "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 :only-of-type "/>
  <wpt:rendition selector="p:first-line "/>
  <wpt:rendition selector="p:first-letter "/>
  <wpt:rendition selector="p:first-letter "/>
  <wpt:rendition selector="p:before "/>
  <wpt:rendition selector="p::first-letter "/>
  <wpt:rendition selector="p::first-letter "/>
  <wpt:rendition selector="p::before "/>
  <wpt:rendition selector="* "/>
  <wpt:rendition selector="ul, p "/>
  <wpt:rendition selector="*.t1 "/>
  <wpt:rendition selector="#foo "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p::before "/>
  <wpt:rendition selector="p:before "/>
  <wpt:rendition selector="p::after "/>
  <wpt:rendition selector="p:after "/>
  <wpt:rendition selector=".white "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="div.t1 p "/>
  <wpt:rendition selector=".white "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="div.t1 p "/>
  <wpt:rendition selector=".white "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="div &gt; p.test "/>
  <wpt:rendition selector=".white "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="div &gt; p.test "/>
  <wpt:rendition selector=".fail &gt; div "/>
  <wpt:rendition selector=".control "/>
  <wpt:rendition selector="#fail &gt; div "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="div.stub &gt; p + p "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector=".white "/>
  <wpt:rendition selector="div.stub &gt; p + p "/>
  <wpt:rendition selector=".fail + div "/>
  <wpt:rendition selector=".control "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="div.stub &gt; p ~ p "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="div.stub &gt; p ~ p "/>
  <wpt:rendition selector="div.stub span, div.stub address, div.stub *|q, div.stub *|r "/>
  <wpt:rendition selector="address, *|q, *|r "/>
  <wpt:rendition selector="div.stub *:not(p) "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not(*) "/>
  <wpt:rendition selector="div.stub &gt; *|*"/>
  <wpt:rendition selector="div.stub &gt; *|*:not() "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[title] "/>
  <wpt:rendition selector="a|* "/>
  <wpt:rendition selector="div.stub *|*:not([test]) "/>
  <wpt:rendition selector="div.stub &gt; p "/>
  <wpt:rendition selector="div.stub &gt; a|* "/>
  <wpt:rendition selector="div.stub *|*:not([test='1']) "/>
  <wpt:rendition selector="div.stub p "/>
  <wpt:rendition selector="div.stub &gt; a|*, div.stub &gt; b|* "/>
  <wpt:rendition selector="div.stub *|*:not([test~='foo']) "/>
  <wpt:rendition selector="div.stub *|p:not([class~='foo']) "/>
  <wpt:rendition selector="div.stub b|*[test~='foo2'] "/>
  <wpt:rendition selector="div.stub p "/>
  <wpt:rendition selector="div.stub &gt; a|*, div.stub &gt; b|* "/>
  <wpt:rendition selector="div.stub *|*:not([test|='foo-bar']) "/>
  <wpt:rendition selector="div.stub *|p:not([lang|='en-us']) "/>
  <wpt:rendition selector="div.stub b|*[test|='foo2-bar'] "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not([title^='si on']) "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not([title$='tait']) "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not([title*=' on']) "/>
  <wpt:rendition selector="*|p, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="div.stub *:not([a|title]) "/>
  <wpt:rendition selector="*|p, *|q, *|r "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="div.stub *:not([a|title]) "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not(.foo) "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address[title='foo'] "/>
  <wpt:rendition selector="span[title='a'] "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not(#foo) "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not(:link) "/>
  <wpt:rendition selector="div.stub &gt; * "/>
  <wpt:rendition selector="div.stub *:not(:visited) "/>
  <wpt:rendition selector="div.stub * "/>
  <wpt:rendition selector="div.stub &gt; * &gt; *:not(:hover) "/>
  <wpt:rendition selector="div.stub * "/>
  <wpt:rendition selector="div.stub &gt; * &gt; *:not(:active) "/>
  <wpt:rendition selector="a:not(:focus) "/>
  <wpt:rendition selector="a "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not(:target) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not(:target) "/>
  <wpt:rendition selector="div.stub * "/>
  <wpt:rendition selector="div.stub *:not(:lang(fr)) "/>
  <wpt:rendition selector="button "/>
  <wpt:rendition selector="input "/>
  <wpt:rendition selector="button:not(:enabled) "/>
  <wpt:rendition selector="input:not(:enabled)  "/>
  <wpt:rendition selector="button "/>
  <wpt:rendition selector="input "/>
  <wpt:rendition selector="button:not(:disabled) "/>
  <wpt:rendition selector="input:not(:disabled) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[class~='b'] "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address[title~='foo'] "/>
  <wpt:rendition selector="span[class~='b'] "/>
  <wpt:rendition selector="input, span "/>
  <wpt:rendition selector="input:not(:checked), input:not(:checked) + span "/>
  <wpt:rendition selector="p:not(:root) "/>
  <wpt:rendition selector="div * "/>
  <wpt:rendition selector="html:not(:root), test:not(:root) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="ul &gt; li:not(:nth-child(odd)) "/>
  <wpt:rendition selector="ol &gt; li:not(:nth-child(even)) "/>
  <wpt:rendition selector="table.t1 tr:not(:nth-child(-n+4)) "/>
  <wpt:rendition selector="table.t2 td:not(:nth-child(3n+1)) "/>
  <wpt:rendition selector="table.t1 td, table.t2 td "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="ul &gt; li:not(:nth-child(odd)) "/>
  <wpt:rendition selector="ol &gt; li:not(:nth-child(even)) "/>
  <wpt:rendition selector="table.t1 tr:not(:nth-child(-n+4)) "/>
  <wpt:rendition selector="table.t2 td:not(:nth-child(3n+1)) "/>
  <wpt:rendition selector="table.t1 td, table.t2 td "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="ul &gt; li:not(:nth-last-child(odd)) "/>
  <wpt:rendition selector="ol &gt; li:not(:nth-last-child(even)) "/>
  <wpt:rendition selector="table.t1 tr:not(:nth-last-child(-n+4)) "/>
  <wpt:rendition selector="table.t2 td:not(:nth-last-child(3n+1)) "/>
  <wpt:rendition selector="table.t1 td, table.t2 td "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="ul &gt; li:not(:nth-last-child(odd)) "/>
  <wpt:rendition selector="ol &gt; li:not(:nth-last-child(even)) "/>
  <wpt:rendition selector="table.t1 tr:not(:nth-last-child(-n+4)) "/>
  <wpt:rendition selector="table.t2 td:not(:nth-last-child(3n+1)) "/>
  <wpt:rendition selector="table.t1 td, table.t2 td "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:not(:nth-of-type(3)) "/>
  <wpt:rendition selector="dl &gt; *:not(:nth-of-type(3n+1)) "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="p:not(:nth-of-type(3)) "/>
  <wpt:rendition selector="dl &gt; *:not(:nth-of-type(3n+1)) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:not(:nth-last-of-type(3)) "/>
  <wpt:rendition selector="dl &gt; *:not(:nth-last-of-type(3n+1)) "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="p:not(:nth-last-of-type(3)) "/>
  <wpt:rendition selector="dl &gt; *:not(:nth-last-of-type(3n+1)) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 td:not(:first-child) "/>
  <wpt:rendition selector="p &gt; *:not(:first-child) "/>
  <wpt:rendition selector="table.t1 td "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector=".t1 td:not(:first-child) "/>
  <wpt:rendition selector="p &gt; *:not(:first-child) "/>
  <wpt:rendition selector="table.t1 td "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 td:not(:last-child) "/>
  <wpt:rendition selector="p &gt; *:not(:last-child) "/>
  <wpt:rendition selector="table.t1 td "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector=".t1 td:not(:last-child) "/>
  <wpt:rendition selector="p &gt; *:not(:last-child) "/>
  <wpt:rendition selector="table.t1 td "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:not(:first-of-type) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="[title~='hello world'] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[lang|='en'] "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address[lang='fi'] "/>
  <wpt:rendition selector="span[lang|='fr'] "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="address "/>
  <wpt:rendition selector="address:not(:last-of-type) "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector="p:not(:only-child) "/>
  <wpt:rendition selector="div.testText &gt; div &gt; p "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector="p:not(:only-child) "/>
  <wpt:rendition selector="div.testText &gt; div &gt; p "/>
  <wpt:rendition selector=".red "/>
  <wpt:rendition selector=".t1 *:not(:only-of-type) "/>
  <wpt:rendition selector=".green "/>
  <wpt:rendition selector=".t1 *:not(:only-of-type) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p:not(:not(p)) "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote &gt; div p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote + div ~ p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote + div ~ p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote + div p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote + div p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote div &gt; p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="p[title^='foo'] "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote ~ div + p "/>
  <wpt:rendition selector="p "/>
  <wpt:rendition selector="blockquote ~ div + p "/>
  <wpt:rendition selector="testa "/>
  <wpt:rendition selector="test|testa "/>
  <wpt:rendition selector="div.myTest * "/>
  <wpt:rendition selector="div.myTest *|testA "/>
  <wpt:rendition selector="*|testA "/>
  <wpt:rendition selector="|testA "/>
  <wpt:rendition selector="p, q "/>
  <wpt:rendition selector="b|* "/>
  <wpt:rendition selector="p, q "/>
  <wpt:rendition selector="b|* "/>
  <wpt:rendition selector="[test] "/>
  <wpt:rendition selector="div.test * "/>
  <wpt:rendition selector="div.test *|* "/>
  <wpt:rendition selector="div.green * "/>
  <wpt:rendition selector="div.test * "/>
  <wpt:rendition selector="div.test |* "/>
  <wpt:rendition selector="div.green * "/>
  <wpt:rendition selector="div.test * "/>
  <wpt:rendition selector="div.test |* "/>
  <wpt:rendition selector="*|p, *|q, *|r "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="*[a|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="*[a|title] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q, *|t "/>
  <wpt:rendition selector="*[a|title='foo'] "/>
  <wpt:rendition selector="*[a|title=footwo] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|q "/>
  <wpt:rendition selector="*[a|title='foo'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|foo~='bar'], *|*[|class~='bar'] "/>
  <wpt:rendition selector="*|*[html|class~='bar'] "/>
  <wpt:rendition selector="*|p, *|q, *|r, *|s "/>
  <wpt:rendition selector="*|p, *|r "/>
  <wpt:rendition selector="*|*[a|foo~='bar'], *|*[html|class~='bar'] "/>
  <wpt:rendition selector="#test "/>
  <wpt:rendition selector="#test:not(:empty) "/>
  <wpt:rendition selector="#test1 "/>
  <wpt:rendition selector="#test1:empty "/>
  <wpt:rendition selector="#test2 "/>
  <wpt:rendition selector="#test2:empty "/>
  <wpt:rendition selector="#test "/>
  <wpt:rendition selector="#stub ~ div div + div &gt; div "/>
  <wpt:rendition selector="[test] "/>
  <wpt:rendition selector="stub ~ [|attribute^=start]:not([|attribute~=mid])[|attribute*=dle][|attribute$=end] ~ t "/>
  <wpt:rendition selector="#two:first-child "/>
  <wpt:rendition selector="#three:last-child     "/>
  <xsl:comment> ********* </xsl:comment>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|foo|="bar"], *|*[html|lang|="en"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|foo|="bar"], *|*[html|lang|="en"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title^="si on"], *|*[title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title^="si on"], *|*[title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title$="tait"], *|*[html|title$="tait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title$="tait"], p[|title$="tait"] '/>
  <w3c:rendition selector='*|*[|title$="tait"], *|*[html|title$="tait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title*="hanta"], *|*[html|title*="hanta"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|title*="hanta"], p[|title*="hanta"] '/>
  <w3c:rendition selector='*|*[|title*="hanta"], *|*[html|title*="hanta"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title="si on chantait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title="si on chantait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|class~="deux"], *|*[*|foo~="deux"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|class~="deux"], *|*[*|foo~="deux"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[*|lang|="en"], *|*[a|foo|="un-d"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[*|lang|="en"], *|*[a|foo|="un-d"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title$="tait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title$="tait"] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[title$="bar"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title*="on ch"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='*|*[*|title*="on ch"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title="si on chantait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title="si on chantait"] '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|q '/>
  <w3c:rendition selector='*|*[|class~="foo"] '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|q '/>
  <w3c:rendition selector='*|*[|class~="foo"] '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|q '/>
  <w3c:rendition selector='*|*[|lang|="foo-bar"], *|*[|myattr|="tat-tut"] '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|q '/>
  <w3c:rendition selector='*|*[|lang|="foo-bar"], *|*[|myattr|="tat-tut"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title^="si on"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title$="tait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title$="tait"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title*="on ch"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[|title*="on ch"] '/>
  <w3c:rendition selector='*|p, *|l '/>
  <w3c:rendition selector='div.test * '/>
  <w3c:rendition selector='div.test *:not(a|p) '/>
  <w3c:rendition selector='div.test *:not(*|div) '/>
  <w3c:rendition selector='div.test > *:not(*|p):not(*|div) '/>
  <w3c:rendition selector='div.stub > *:not(*|div) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[title*="bar"] '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub > *:not(|p) '/>
  <w3c:rendition selector='div.stub > *|l > *:not(|p) '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not(a|*) '/>
  <w3c:rendition selector='div.stub v '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not(*|*) '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not(|*) '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not(|*) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='div.stub *:not([a|title="foo"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r, *|s '/>
  <w3c:rendition selector='div.stub *:not([a|title="foo"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|foo~="bar"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|foo~="bar"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|foo|="bar"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|foo|="bar"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title*="hanta"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|s '/>
  <w3c:rendition selector='div.stub *|*:not([a|title*="hanta"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([*|title]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([*|title]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([*|title="si on chantait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([*|title="si on chantait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p.deu, *|q '/>
  <w3c:rendition selector='div.stub html|*:not([*|class~="deux"]),'/>
  <w3c:rendition selector='   div.stub *|*:not(html|*):not([*|foo~="deux"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p.deu, *|q '/>
  <w3c:rendition selector='div.stub html|*:not([*|class~="deux"]),'/>
  <w3c:rendition selector='   div.stub *|*:not(html|*):not([*|foo~="deux"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p.foo, *|q, *|s '/>
  <w3c:rendition selector='div.stub html|*:not([*|lang|="en"]),'/>
  <w3c:rendition selector='  div.stub *|*:not(html|*):not([a|foo|="un-d"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p.foo, *|q, *|s '/>
  <w3c:rendition selector='div.stub html|*:not([*|lang|="en"]),'/>
  <w3c:rendition selector='  div.stub *|*:not(html|*):not([a|foo|="un-d"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title*="on ch"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|p.red, *|q, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([*|title*="on ch"]) '/>
  <w3c:rendition selector='*|q, *|r '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([|title]) '/>
  <w3c:rendition selector='*|q, *|r '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='div.stub *|*:not([|title]) '/>
  <w3c:rendition selector='*|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title="si on chantait"]) '/>
  <w3c:rendition selector='*|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title="si on chantait"]) '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|address, *|r '/>
  <w3c:rendition selector='div.stub *|*:not([|class~="foo"]) '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|address, *|r '/>
  <w3c:rendition selector='div.stub *|*:not([|class~="foo"]) '/>
  <w3c:rendition selector='li '/>
  <w3c:rendition selector='.t1 '/>
  <w3c:rendition selector='li.t2 '/>
  <w3c:rendition selector='.t3 '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|address, *|r '/>
  <w3c:rendition selector='div.stub *|*:not([|lang|="foo-bar"]) '/>
  <w3c:rendition selector='*|p, *|address, *|q, *|r '/>
  <w3c:rendition selector='*|address, *|r '/>
  <w3c:rendition selector='div.stub *|*:not([|lang|="foo-bar"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title^="si on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title$="tait"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title*="on ch"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s, *|t'/>
  <w3c:rendition selector='*|q, *|s, *|t '/>
  <w3c:rendition selector='div.stub *|*:not([|title*="on ch"]) '/>
  <w3c:rendition selector='div :not(:enabled):not(:disabled) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=odd] '/>
  <w3c:rendition selector='  line:nth-of-type(odd) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=odd] '/>
  <w3c:rendition selector='  line:nth-of-type(odd) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=match] '/>
  <w3c:rendition selector='  line:nth-child(3n-1) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=match] '/>
  <w3c:rendition selector='  line:nth-child(3n-1) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=match] '/>
  <w3c:rendition selector='  line:nth-last-of-type(3n-1) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector='  line '/>
  <w3c:rendition selector='  [type~=match] '/>
  <w3c:rendition selector='  line:nth-last-of-type(3n-1) '/>
  <w3c:rendition selector='  [hidden] '/>
  <w3c:rendition selector=' p '/>
  <w3c:rendition selector=' p:empty '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='.t1.fail '/>
  <w3c:rendition selector='.fail.t1 '/>
  <w3c:rendition selector='.t2.fail '/>
  <w3c:rendition selector='.fail.t2 '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p.t1.t2 '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='div.t1 '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address.t5.t5 '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='.t1:not(.t2) '/>
  <w3c:rendition selector=':not(.t2).t1 '/>
  <w3c:rendition selector='.t2:not(.t1) '/>
  <w3c:rendition selector=':not(.t1).t2 '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(.t1):not(.t2) '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='div:not(.t1) '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address:not(.t5):not(.t5) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p.t1 '/>
  <w3c:rendition selector='p.t2 '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='div.teST '/>
  <w3c:rendition selector='div.te '/>
  <w3c:rendition selector='div.st '/>
  <w3c:rendition selector='div.te.st '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector=' address '/>
  <w3c:rendition selector=' address:empty '/>
  <w3c:rendition selector=' .text '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p, '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  .\5cm '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  .two\ words '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  .one.word '/>
  <w3c:rendition selector='  .one\.word '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  .5cm '/>
  <w3c:rendition selector='  foo &amp; address, p '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  foo &amp; address, p '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  foo &amp; address, p '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  [*=test] '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  [*|*=test] '/>
  <w3c:rendition selector='  ::selection '/>
  <w3c:rendition selector='  :selection '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='#test#fail '/>
  <w3c:rendition selector='#fail#test '/>
  <w3c:rendition selector='#fail '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='#pass#pass '/>
  <w3c:rendition selector='.warning '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='#Aone#Atwo, #Aone#Athree, #Atwo#Athree '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='#Bone#Btwo, #Bone#Bthree, #Btwo#Bthree '/>
  <w3c:rendition selector='#Cone#Ctwo, #Cone#Cthree, #Ctwo#Cthree '/>
  <w3c:rendition selector='#Done#Dtwo, #Done#Dthree, #Dtwo#Dthree '/>
  <w3c:rendition selector='li '/>
  <w3c:rendition selector='#t1 '/>
  <w3c:rendition selector='li#t2 '/>
  <w3c:rendition selector='li#t3 '/>
  <w3c:rendition selector='#t4 '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p:subject  '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p   * '/>
  <w3c:rendition selector='  p > * '/>
  <w3c:rendition selector='  p + * '/>
  <w3c:rendition selector='  p ~ * '/>
  <w3c:rendition selector='  :canvas '/>
  <w3c:rendition selector='  :viewport '/>
  <w3c:rendition selector='  :window '/>
  <w3c:rendition selector='  :menu '/>
  <w3c:rendition selector='  :table '/>
  <w3c:rendition selector='  :select '/>
  <w3c:rendition selector='  ::canvas '/>
  <w3c:rendition selector='  ::viewport '/>
  <w3c:rendition selector='  ::window '/>
  <w3c:rendition selector='  ::menu '/>
  <w3c:rendition selector='  ::table '/>
  <w3c:rendition selector='  ::select '/>
  <w3c:rendition selector='  p::first-letter '/>
  <w3c:rendition selector='  p:first-letter '/>
  <w3c:rendition selector='  p:first-letter '/>
  <w3c:rendition selector='  p::first-letter '/>
  <w3c:rendition selector='  p::first-line '/>
  <w3c:rendition selector='  p:first-line '/>
  <w3c:rendition selector='  p:first-line '/>
  <w3c:rendition selector='  p::first-line '/>
  <w3c:rendition selector='  span::before '/>
  <w3c:rendition selector='  span:before '/>
  <w3c:rendition selector='  span:before '/>
  <w3c:rendition selector='  span::before '/>
  <w3c:rendition selector='  span::after '/>
  <w3c:rendition selector='  span:after '/>
  <w3c:rendition selector='  span:after '/>
  <w3c:rendition selector='  span::after '/>
  <w3c:rendition selector='p.test a '/>
  <w3c:rendition selector='p.test *:link '/>
  <w3c:rendition selector='  .span '/>
  <w3c:rendition selector='  .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span, .span  '/>
  <w3c:rendition selector='  .span '/>
  <w3c:rendition selector='  .span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span.span  '/>
  <w3c:rendition selector='  p.span '/>
  <w3c:rendition selector='  p:not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span):not(.span)  '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child:first-child  '/>
  <w3c:rendition selector='  span '/>
  <w3c:rendition selector='  span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span, span  '/>
  <w3c:rendition selector=' p '/>
  <w3c:rendition selector=' .fail '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA[|attribute] '/>
  <w3c:rendition selector=' testB[|attribute="fail"] '/>
  <w3c:rendition selector=' testC[|attribute~="fail"] '/>
  <w3c:rendition selector=' testD[|attribute^="fail"] '/>
  <w3c:rendition selector=' testE[|attribute*="fail"] '/>
  <w3c:rendition selector=' testF[|attribute$="fail"] '/>
  <w3c:rendition selector=' testG[|attribute|="fail"] '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA[|attribute] '/>
  <w3c:rendition selector=' testB[|attribute="fail"] '/>
  <w3c:rendition selector=' testC[|attribute~="fail"] '/>
  <w3c:rendition selector=' testD[|attribute^="fail"] '/>
  <w3c:rendition selector=' testE[|attribute*="fail"] '/>
  <w3c:rendition selector=' testF[|attribute$="fail"] '/>
  <w3c:rendition selector=' testG[|attribute|="fail"] '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA[*|attribute] '/>
  <w3c:rendition selector=' testB[*|attribute="pass"] '/>
  <w3c:rendition selector=' testC[*|attribute~="pass"] '/>
  <w3c:rendition selector=' testD[*|attribute^="pass"] '/>
  <w3c:rendition selector=' testE[*|attribute*="pass"] '/>
  <w3c:rendition selector=' testF[*|attribute$="pass"] '/>
  <w3c:rendition selector=' testG[*|attribute|="pass"] '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA[*|attribute] '/>
  <w3c:rendition selector=' testB[*|attribute="pass"] '/>
  <w3c:rendition selector=' testC[*|attribute~="pass"] '/>
  <w3c:rendition selector=' testD[*|attribute^="pass"] '/>
  <w3c:rendition selector=' testE[*|attribute*="pass"] '/>
  <w3c:rendition selector=' testF[*|attribute$="pass"] '/>
  <w3c:rendition selector=' testG[*|attribute|="pass"] '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA[*|attribute="pass"] '/>
  <w3c:rendition selector=' testB[*|attribute="pass"] '/>
  <w3c:rendition selector=' tests, tests * '/>
  <w3c:rendition selector=' testA:not([*|attribute="pass"]) '/>
  <w3c:rendition selector=' testB:not([*|attribute="pass"]) '/>
  <w3c:rendition selector=' p '/>
  <w3c:rendition selector=' .13 '/>
  <w3c:rendition selector=' p '/>
  <w3c:rendition selector=' .\13 '/>
  <w3c:rendition selector=' p '/>
  <w3c:rendition selector=' .\31 \33 '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(#other).class:not(.fail).test#id#id '/>
  <w3c:rendition selector='div '/>
  <w3c:rendition selector='div:not(#theid).class:not(.fail).test#theid#theid '/>
  <w3c:rendition selector='div:not(#other).notclass:not(.fail).test#theid#theid '/>
  <w3c:rendition selector='div:not(#other).class:not(.test).test#theid#theid '/>
  <w3c:rendition selector='div:not(#other).class:not(.fail).nottest#theid#theid '/>
  <w3c:rendition selector='div:not(#other).class:not(.fail).nottest#theid#other '/>
  <w3c:rendition selector=' p:selection '/>
  <w3c:rendition selector=' div '/>
  <w3c:rendition selector=' p::first-child '/>
  <w3c:rendition selector=' div '/>
  <w3c:rendition selector=' p:not(:first-line) '/>
  <w3c:rendition selector=' p:not(:after) '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p:first-line '/>
  <w3c:rendition selector='  p::first-line '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  span:first-line '/>
  <w3c:rendition selector='  span::first-line '/>
  <w3c:rendition selector='p.test a '/>
  <w3c:rendition selector='p.test *:visited '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='  p:first-letter '/>
  <w3c:rendition selector='  p::first-letter '/>
  <w3c:rendition selector=' .cs '/>
  <w3c:rendition selector=' .cs P '/>
  <w3c:rendition selector=' .cs .a '/>
  <w3c:rendition selector=' .cs .span1 span '/>
  <w3c:rendition selector=' .cs .span2 '/>
  <w3c:rendition selector=' .cs .span2 SPAN '/>
  <w3c:rendition selector=' .cs .span2 span '/>
  <w3c:rendition selector=' .ci '/>
  <w3c:rendition selector=' .ci P '/>
  <w3c:rendition selector=' .ci .a '/>
  <w3c:rendition selector=' .ci .span1 span '/>
  <w3c:rendition selector=' .ci .span2 SPAN '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='foo\:bar '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='..test '/>
  <w3c:rendition selector='.foo..quux '/>
  <w3c:rendition selector='.bar. '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[class$=""] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[class^=""] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[class*=""] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not([class$=""]) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not([class^=""]) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not([class*=""]) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='.a a:hover '/>
  <w3c:rendition selector='.b a:hover '/>
  <w3c:rendition selector='.b a:link '/>
  <w3c:rendition selector='.c :link '/>
  <w3c:rendition selector='.c :visited:hover '/>
  <w3c:rendition selector='div:hover > p:first-child '/>
  <w3c:rendition selector=':link, :visited '/>
  <w3c:rendition selector=':link:hover span '/>
  <w3c:rendition selector='p:hover '/>
  <w3c:rendition selector='a:hover '/>
  <w3c:rendition selector='tr:hover '/>
  <w3c:rendition selector='td:hover '/>
  <w3c:rendition selector='table '/>
  <w3c:rendition selector='button:active '/>
  <w3c:rendition selector='a:active '/>
  <w3c:rendition selector='li,p '/>
  <w3c:rendition selector='a:focus '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:target '/>
  <w3c:rendition selector=':root '/>
  <w3c:rendition selector=':target '/>
  <w3c:rendition selector='p:target '/>
  <w3c:rendition selector='ul > li '/>
  <w3c:rendition selector='li:lang(en-GB) '/>
  <w3c:rendition selector='button '/>
  <w3c:rendition selector='input '/>
  <w3c:rendition selector='button:enabled '/>
  <w3c:rendition selector='input:enabled '/>
  <w3c:rendition selector='button '/>
  <w3c:rendition selector='input '/>
  <w3c:rendition selector='button:disabled '/>
  <w3c:rendition selector='input:disabled '/>
  <w3c:rendition selector='input, span '/>
  <w3c:rendition selector='input:checked, input:checked + span '/>
  <w3c:rendition selector=':root:first-child '/>
  <w3c:rendition selector=':root:last-child '/>
  <w3c:rendition selector=':root:only-child '/>
  <w3c:rendition selector=':root:nth-child(1) '/>
  <w3c:rendition selector=':root:nth-child(n) '/>
  <w3c:rendition selector=':root:nth-last-child(1) '/>
  <w3c:rendition selector=':root:nth-last-child(n) '/>
  <w3c:rendition selector=':root:first-of-type '/>
  <w3c:rendition selector=':root:last-of-type '/>
  <w3c:rendition selector=':root:only-of-type '/>
  <w3c:rendition selector=':root:nth-of-type(1) '/>
  <w3c:rendition selector=':root:nth-of-type(n) '/>
  <w3c:rendition selector=':root:nth-last-of-type(1) '/>
  <w3c:rendition selector=':root:nth-last-of-type(n) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='* html '/>
  <w3c:rendition selector='* :root '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='html '/>
  <w3c:rendition selector='*:root '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='ul > li:nth-child(odd) '/>
  <w3c:rendition selector='ol > li:nth-child(even) '/>
  <w3c:rendition selector='table.t1 tr:nth-child(-n+4) '/>
  <w3c:rendition selector='table.t2 td:nth-child(3n+1) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='ul > li:nth-child(odd) '/>
  <w3c:rendition selector='ol > li:nth-child(even) '/>
  <w3c:rendition selector='table.t1 tr:nth-child(-n+4) '/>
  <w3c:rendition selector='table.t2 td:nth-child(3n+1) '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='ul > li:nth-last-child(odd) '/>
  <w3c:rendition selector='ol > li:nth-last-child(even) '/>
  <w3c:rendition selector='table.t1 tr:nth-last-child(-n+4) '/>
  <w3c:rendition selector='table.t2 td:nth-last-child(3n+1) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='ul > li:nth-last-child(odd) '/>
  <w3c:rendition selector='ol > li:nth-last-child(even) '/>
  <w3c:rendition selector='table.t1 tr:nth-last-child(-n+4) '/>
  <w3c:rendition selector='table.t2 td:nth-last-child(3n+1) '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:nth-of-type(3) '/>
  <w3c:rendition selector='dl > :nth-of-type(3n+1) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:nth-last-of-type(3) '/>
  <w3c:rendition selector='dl > :nth-last-of-type(3n+1) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 td:first-child '/>
  <w3c:rendition selector='p > *:first-child '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 td:last-child '/>
  <w3c:rendition selector='p > *:last-child '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address:first-of-type '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address:last-of-type '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:only-child '/>
  <w3c:rendition selector='div.testText > div > p '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 :only-of-type '/>
  <w3c:rendition selector='p:first-line '/>
  <w3c:rendition selector='p:first-letter '/>
  <w3c:rendition selector='p:before '/>
  <w3c:rendition selector='p::first-letter '/>
  <w3c:rendition selector='p::first-letter '/>
  <w3c:rendition selector=' p::before '/>
  <w3c:rendition selector='p:first-letter '/>
  <w3c:rendition selector='* '/>
  <w3c:rendition selector='ul, p '/>
  <w3c:rendition selector='*.t1 '/>
  <w3c:rendition selector='* '/>
  <w3c:rendition selector='ul, p '/>
  <w3c:rendition selector='*.t1 '/>
  <w3c:rendition selector='p:before '/>
  <w3c:rendition selector='p::before '/>
  <w3c:rendition selector='p:after '/>
  <w3c:rendition selector='p::after '/>
  <w3c:rendition selector='.white '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='div.t1 p '/>
  <w3c:rendition selector='.white '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='div.t1 p '/>
  <w3c:rendition selector='.white '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='div > p.test '/>
  <w3c:rendition selector='  .fail > div '/>
  <w3c:rendition selector='  .control '/>
  <w3c:rendition selector='  #fail > div '/>
  <w3c:rendition selector='  p '/>
  <w3c:rendition selector='.white '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='div > p.test '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='.white '/>
  <w3c:rendition selector='div.stub > p + p '/>
  <w3c:rendition selector='  .fail + div '/>
  <w3c:rendition selector='  .control '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='div.stub > p + p '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='div.stub > p ~ p '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='div.stub > p ~ p '/>
  <w3c:rendition selector='div.stub span, div.stub address, div.stub *|q, div.stub *|r '/>
  <w3c:rendition selector='address, *|q, *|r '/>
  <w3c:rendition selector='div.stub *:not(p) '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not(*) '/>
  <w3c:rendition selector='div.stub > *|* '/>
  <w3c:rendition selector='div.stub > *|*:not() '/>
  <w3c:rendition selector='#foo '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='a|* '/>
  <w3c:rendition selector='div.stub *|*:not([test]) '/>
  <w3c:rendition selector='div.stub > p '/>
  <w3c:rendition selector='div.stub > a|* '/>
  <w3c:rendition selector='div.stub *|*:not([test="1"]) '/>
  <w3c:rendition selector='div.stub p '/>
  <w3c:rendition selector='div.stub > a|*, div.stub > b|* '/>
  <w3c:rendition selector='div.stub *|*:not([test~="foo"]) '/>
  <w3c:rendition selector='div.stub *|p:not([class~="foo"]) '/>
  <w3c:rendition selector='div.stub b|*[test~="foo2"] '/>
  <w3c:rendition selector='div.stub p '/>
  <w3c:rendition selector='div.stub > a|*, div.stub > b|* '/>
  <w3c:rendition selector='div.stub *|*:not([test|="foo-bar"]) '/>
  <w3c:rendition selector='div.stub *|p:not([lang|="en-us"]) '/>
  <w3c:rendition selector='div.stub b|*[test|="foo2-bar"] '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not([title^="si on"]) '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not([title$="tait"]) '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not([title*=" on"]) '/>
  <w3c:rendition selector='*|p, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='div.stub *:not([a|title]) '/>
  <w3c:rendition selector='*|p, *|q, *|r '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='div.stub *:not([a|title]) '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not(.foo) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[title] '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not(#foo) '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not(:link) '/>
  <w3c:rendition selector='div.stub > * '/>
  <w3c:rendition selector='div.stub *:not(:visited) '/>
  <w3c:rendition selector='div.stub * '/>
  <w3c:rendition selector='div.stub > * > *:not(:hover) '/>
  <w3c:rendition selector='div.stub * '/>
  <w3c:rendition selector='div.stub > * > *:not(:active) '/>
  <w3c:rendition selector='a:not(:focus) '/>
  <w3c:rendition selector='a '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(:target) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(:target) '/>
  <w3c:rendition selector='div.stub * '/>
  <w3c:rendition selector='div.stub *:not(:lang(fr)) '/>
  <w3c:rendition selector='button '/>
  <w3c:rendition selector='input '/>
  <w3c:rendition selector='button:not(:enabled) '/>
  <w3c:rendition selector='input:not(:enabled)  '/>
  <w3c:rendition selector='button '/>
  <w3c:rendition selector='input '/>
  <w3c:rendition selector='button:not(:disabled) '/>
  <w3c:rendition selector='input:not(:disabled) '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address[title="foo"] '/>
  <w3c:rendition selector='span[title="a"] '/>
  <w3c:rendition selector='input, span '/>
  <w3c:rendition selector='input:not(:checked), input:not(:checked) + span '/>
  <w3c:rendition selector='html:not(:root), test:not(:root) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(:root) '/>
  <w3c:rendition selector='div * '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='ul > li:not(:nth-child(odd)) '/>
  <w3c:rendition selector='ol > li:not(:nth-child(even)) '/>
  <w3c:rendition selector='table.t1 tr:not(:nth-child(-n+4)) '/>
  <w3c:rendition selector='table.t2 td:not(:nth-child(3n+1)) '/>
  <w3c:rendition selector='table.t1 td, table.t2 td '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='ul > li:not(:nth-child(odd)) '/>
  <w3c:rendition selector='ol > li:not(:nth-child(even)) '/>
  <w3c:rendition selector='table.t1 tr:not(:nth-child(-n+4)) '/>
  <w3c:rendition selector='table.t2 td:not(:nth-child(3n+1)) '/>
  <w3c:rendition selector='table.t1 td, table.t2 td '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='ul > li:not(:nth-last-child(odd)) '/>
  <w3c:rendition selector='ol > li:not(:nth-last-child(even)) '/>
  <w3c:rendition selector='table.t1 tr:not(:nth-last-child(-n+4)) '/>
  <w3c:rendition selector='table.t2 td:not(:nth-last-child(3n+1)) '/>
  <w3c:rendition selector='table.t1 td, table.t2 td '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='ul > li:not(:nth-last-child(odd)) '/>
  <w3c:rendition selector='ol > li:not(:nth-last-child(even)) '/>
  <w3c:rendition selector='table.t1 tr:not(:nth-last-child(-n+4)) '/>
  <w3c:rendition selector='table.t2 td:not(:nth-last-child(3n+1)) '/>
  <w3c:rendition selector='table.t1 td, table.t2 td '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='p:not(:nth-of-type(3)) '/>
  <w3c:rendition selector='dl > *:not(:nth-of-type(3n+1)) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:not(:nth-of-type(3)) '/>
  <w3c:rendition selector='dl > *:not(:nth-of-type(3n+1)) '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='p:not(:nth-last-of-type(3)) '/>
  <w3c:rendition selector='dl > *:not(:nth-last-of-type(3n+1)) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:not(:nth-last-of-type(3)) '/>
  <w3c:rendition selector='dl > *:not(:nth-last-of-type(3n+1)) '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='.t1 td:not(:first-child) '/>
  <w3c:rendition selector='p > *:not(:first-child) '/>
  <w3c:rendition selector='table.t1 td '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 td:not(:first-child) '/>
  <w3c:rendition selector='p > *:not(:first-child) '/>
  <w3c:rendition selector='table.t1 td '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='.t1 td:not(:last-child) '/>
  <w3c:rendition selector='p > *:not(:last-child) '/>
  <w3c:rendition selector='table.t1 td '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 td:not(:last-child) '/>
  <w3c:rendition selector='p > *:not(:last-child) '/>
  <w3c:rendition selector='table.t1 td '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address:not(:first-of-type) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='[title~="hello world"] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[class~="b"] '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address[title~="foo"] '/>
  <w3c:rendition selector='span[class~="b"] '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address:not(:last-of-type) '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='p:not(:only-child) '/>
  <w3c:rendition selector='div.testText > div > p '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='p:not(:only-child) '/>
  <w3c:rendition selector='div.testText > div > p '/>
  <w3c:rendition selector='.green '/>
  <w3c:rendition selector='.t1 *:not(:only-of-type) '/>
  <w3c:rendition selector='.red '/>
  <w3c:rendition selector='.t1 *:not(:only-of-type) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p:not(:not(p)) '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote > div p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote + div ~ p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote + div ~ p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote + div p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote + div p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote div > p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[lang|="en"] '/>
  <w3c:rendition selector='address '/>
  <w3c:rendition selector='address[lang="fi"] '/>
  <w3c:rendition selector='span[lang|="fr"] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote ~ div + p '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='blockquote ~ div + p '/>
  <w3c:rendition selector='testa '/>
  <w3c:rendition selector='test|testa '/>
  <w3c:rendition selector='div.myTest * '/>
  <w3c:rendition selector='div.myTest *|testA '/>
  <w3c:rendition selector='*|testA '/>
  <w3c:rendition selector='|testA '/>
  <w3c:rendition selector='p, q '/>
  <w3c:rendition selector='b|* '/>
  <w3c:rendition selector='[test] '/>
  <w3c:rendition selector='p, q '/>
  <w3c:rendition selector='b|* '/>
  <w3c:rendition selector='div.test * '/>
  <w3c:rendition selector='div.test *|* '/>
  <w3c:rendition selector='div.green * '/>
  <w3c:rendition selector='div.test * '/>
  <w3c:rendition selector='div.test |* '/>
  <w3c:rendition selector='div.green * '/>
  <w3c:rendition selector='div.test * '/>
  <w3c:rendition selector='div.test |* '/>
  <w3c:rendition selector='*|p, *|q, *|r '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='*[a|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='*[a|title] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q '/>
  <w3c:rendition selector='*[a|title="foo"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|q, *|t '/>
  <w3c:rendition selector='*[a|title="foo"] '/>
  <w3c:rendition selector='*[a|title=footwo] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|foo~="bar"], *|*[html|class~="bar"] '/>
  <w3c:rendition selector='*|p, *|q, *|r, *|s '/>
  <w3c:rendition selector='*|p, *|r '/>
  <w3c:rendition selector='*|*[a|foo~="bar"], *|*[|class~="bar"] '/>
  <w3c:rendition selector='*|*[html|class~="bar"] '/>
  <w3c:rendition selector='p '/>
  <w3c:rendition selector='p[title^="foo"] '/>
  <w3c:rendition selector='   #test1 '/>
  <w3c:rendition selector='   #test1:empty '/>
  <w3c:rendition selector='   #test2 '/>
  <w3c:rendition selector='   #test2:empty '/>
  <w3c:rendition selector='   #test '/>
  <w3c:rendition selector='   #test:not(:empty) '/>
  <w3c:rendition selector='   #test '/>
  <w3c:rendition selector='   #stub ~ div div + div > div '/>
  <w3c:rendition selector='   [test] '/>
  <w3c:rendition selector='   stub ~ [|attribute^=start]:not([|attribute~=mid])[|attribute*=dle][|attribute$=end] ~ t '/>
  <w3c:rendition selector='   #two:first-child '/>
  <w3c:rendition selector='   #three:last-child '/>
  <xsl:comment> ********* </xsl:comment>
  <ws:rendition selector='		#main '/>
  <ws:rendition selector='		#page '/>
  <ws:rendition selector='		.customhover a:active '/>
  <ws:rendition selector='		.customhover a:hover '/>
  <ws:rendition selector='		.customhover a:link '/>
  <ws:rendition selector='		.customhover a:visited '/>
  <ws:rendition selector='		.headbutton '/>
  <ws:rendition selector='		body '/>
  <ws:rendition selector='	#Contentin '/>
  <ws:rendition selector='	#Contentinp '/>
  <ws:rendition selector='	#aboutlink '/>
  <ws:rendition selector='	#aboutlink a:active  '/>
  <ws:rendition selector='	#aboutlink a:hover  '/>
  <ws:rendition selector='	#aboutlink a:link  '/>
  <ws:rendition selector='	#aboutlink a:visited  '/>
  <ws:rendition selector='	#contactlink '/>
  <ws:rendition selector='	#contactlink  a:active  '/>
  <ws:rendition selector='	#contactlink  a:hover  '/>
  <ws:rendition selector='	#contactlink  a:link  '/>
  <ws:rendition selector='	#contactlink  a:visited  '/>
  <ws:rendition selector='	#encodinglink '/>
  <ws:rendition selector='	#encodinglink  a:active  '/>
  <ws:rendition selector='	#encodinglink  a:hover  '/>
  <ws:rendition selector='	#encodinglink  a:link  '/>
  <ws:rendition selector='	#encodinglink  a:visited  '/>
  <ws:rendition selector='	#licenselink '/>
  <ws:rendition selector='	#licenselink  a:active  '/>
  <ws:rendition selector='	#licenselink  a:hover  '/>
  <ws:rendition selector='	#licenselink  a:link  '/>
  <ws:rendition selector='	#licenselink  a:visited  '/>
  <ws:rendition selector='	#sitelink '/>
  <ws:rendition selector='	#sitelink  a:active  '/>
  <ws:rendition selector='	#sitelink  a:hover  '/>
  <ws:rendition selector='	#sitelink  a:link  '/>
  <ws:rendition selector='	#sitelink  a:visited  '/>
  <ws:rendition selector='	#textslink '/>
  <ws:rendition selector='	#textslink a:active  '/>
  <ws:rendition selector='	#textslink a:hover  '/>
  <ws:rendition selector='	#textslink a:link  '/>
  <ws:rendition selector='	#textslink a:visited  '/>
  <ws:rendition selector='	#title '/>
  <ws:rendition selector='	#wwolink '/>
  <ws:rendition selector='	#wwolink a:active  '/>
  <ws:rendition selector='	#wwolink a:hover  '/>
  <ws:rendition selector='	#wwolink a:link  '/>
  <ws:rendition selector='	#wwolink a:visited  '/>
  <ws:rendition selector='

code '/>
  <ws:rendition selector='

date '/>
  <ws:rendition selector='

emph '/>
  <ws:rendition selector='

foreign '/>
  <ws:rendition selector='

formula '/>
  <ws:rendition selector='

gi:before '/>
  <ws:rendition selector='

gloss '/>
  <ws:rendition selector='

hi '/>
  <ws:rendition selector='

kw '/>
  <ws:rendition selector='

mentioned '/>
  <ws:rendition selector='

name '/>
  <ws:rendition selector='

num '/>
  <ws:rendition selector='

q:before '/>
  <ws:rendition selector='

soCalled:before '/>
  <ws:rendition selector='

term:before '/>
  <ws:rendition selector='

title '/>
  <ws:rendition selector='

val '/>
  <ws:rendition selector='
att:after '/>
  <ws:rendition selector='
gi '/>
  <ws:rendition selector='
gi:after '/>
  <ws:rendition selector='
q '/>
  <ws:rendition selector='
q:after '/>
  <ws:rendition selector='
q[rend="display"] '/>
  <ws:rendition selector='
soCalled '/>
  <ws:rendition selector='
soCalled:after '/>
  <ws:rendition selector='
term '/>
  <ws:rendition selector='
term:after '/>
  <ws:rendition selector='    	.customhover 	'/>
  <ws:rendition selector='    	.headingsm '/>
  <ws:rendition selector='            .btn-default '/>
  <ws:rendition selector='            .glyphicon '/>
  <ws:rendition selector='            > span '/>
  <ws:rendition selector='   div.content p:last-child:after, div.content ul:last-child li:last-child:after '/>
  <ws:rendition selector='  #featured '/>
  <ws:rendition selector='  #featured .container '/>
  <ws:rendition selector='  #featured .container .featured '/>
  <ws:rendition selector='  #featured .container .featured a '/>
  <ws:rendition selector='  #featured .container .featured a:after '/>
  <ws:rendition selector='  #featured .container .featured:first-child,'/>
  <ws:rendition selector='  #featured .container .featured:last-child '/>
  <ws:rendition selector='  #footer .container '/>
  <ws:rendition selector='  #footer .container #about '/>
  <ws:rendition selector='  #footer .container .submissions '/>
  <ws:rendition selector='  #fulltext .body .container '/>
  <ws:rendition selector='  #fulltext .body .container .blockquote '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .figGrp .figure '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .figure.inset-left '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .figure.inset-left,'/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .figure.inset-right '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .section.sources ul '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent .section.sources ul li .biblMenu '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent p '/>
  <ws:rendition selector='  #fulltext .body .container .bodyContent ul '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container .bio '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container .dates '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container .extras '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container .extras h1 '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container div.label '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container div.related h1,'/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container div.related,'/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container.context '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container.note '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container.note div.label '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .container.person p '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .contents ul,'/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .contents,'/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .other '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent .other ul '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonContent div.label '/>
  <ws:rendition selector='  #fulltext .body .container .ribbon .ribbonThreads '/>
  <ws:rendition selector='  #fulltext .body .container p.pullquote '/>
  <ws:rendition selector='  #fulltext .header .headerGroup '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .byline .date '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .keywords a '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .keywords a:after '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .keywords a:last-of-type:after '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .keywords br '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container .meta '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .container h1 '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .keywords a:after '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .keywords a:last-of-type:after '/>
  <ws:rendition selector='  #fulltext .header .headerGroup .keywords br '/>
  <ws:rendition selector='  #header .container '/>
  <ws:rendition selector='  #header .container .brand '/>
  <ws:rendition selector='  #header .container .brand a .logo '/>
  <ws:rendition selector='  #header .container .brand a .text '/>
  <ws:rendition selector='  #main '/>
  <ws:rendition selector='  #main #contents '/>
  <ws:rendition selector='  #main #contents.grid .contents-item '/>
  <ws:rendition selector='  #main #contents.grid .contents-item:nth-child(2n) '/>
  <ws:rendition selector='  #main #contents.grid .contents-item:nth-child(2n+1) '/>
  <ws:rendition selector='  #main #contents.grid .contents-item:nth-child(3n),'/>
  <ws:rendition selector='  #main #contents.grid .contents-item:nth-child(3n+1) '/>
  <ws:rendition selector='  #main #sidebar '/>
  <ws:rendition selector='  #main .menu .menu-item:first-child '/>
  <ws:rendition selector='  #timeline blockquote '/>
  <ws:rendition selector='  .ie6_button '/>
  <ws:rendition selector='  .ie6_button,'/>
  <ws:rendition selector='  .menu .menu-item.button-toggle '/>
  <ws:rendition selector='  .menu .menu-item.button-toggle-label '/>
  <ws:rendition selector='  ::-webkit-validation-bubble-arrow,'/>
  <ws:rendition selector='  ::-webkit-validation-bubble-message '/>
  <ws:rendition selector='  ::-webkit-validation-bubble-top-inner-arrow '/>
  <ws:rendition selector='  ::-webkit-validation-bubble-top-outer-arrow,'/>
  <ws:rendition selector='  div.c2 '/>
  <ws:rendition selector='  input[type=submit] '/>
  <ws:rendition selector='  li.c3 '/>
  <ws:rendition selector='  select[multiple] '/>
  <ws:rendition selector='  select[size],'/>
  <ws:rendition selector=' div.c4 '/>
  <ws:rendition selector=' img.c1 '/>
  <ws:rendition selector=' img.c3 '/>
  <ws:rendition selector=' table.c2 '/>
  <ws:rendition selector=' td.c1 '/>
  <ws:rendition selector='#Content '/>
  <ws:rendition selector='#Content img '/>
  <ws:rendition selector='#Contentin '/>
  <ws:rendition selector='#Contentinp '/>
  <ws:rendition selector='#Contentsub '/>
  <ws:rendition selector='#Indeximg '/>
  <ws:rendition selector='#advanced #year-slider '/>
  <ws:rendition selector='#advanced .submit '/>
  <ws:rendition selector='#advanced fieldset '/>
  <ws:rendition selector='#advanced fieldset div.field '/>
  <ws:rendition selector='#advanced fieldset div.field input '/>
  <ws:rendition selector='#advanced fieldset div.field input.no-label '/>
  <ws:rendition selector='#advanced fieldset div.field input[type=radio] '/>
  <ws:rendition selector='#advanced fieldset div.field input[type=text] '/>
  <ws:rendition selector='#advanced fieldset div.field label '/>
  <ws:rendition selector='#advanced fieldset legend '/>
  <ws:rendition selector='#advanced form '/>
  <ws:rendition selector='#banner '/>
  <ws:rendition selector='#basicform '/>
  <ws:rendition selector='#basicform input '/>
  <ws:rendition selector='#builder '/>
  <ws:rendition selector='#builder .colorpicker '/>
  <ws:rendition selector='#builder .colorpicker .colorgrid '/>
  <ws:rendition selector='#builder .colorpicker .colorgrid .cell '/>
  <ws:rendition selector='#builder .colorpicker select '/>
  <ws:rendition selector='#builder .handle '/>
  <ws:rendition selector='#builder .handle a '/>
  <ws:rendition selector='#builder .handle a:hover '/>
  <ws:rendition selector='#builder .tabcontent '/>
  <ws:rendition selector='#builder .tabcontent .band '/>
  <ws:rendition selector='#builder .tabcontent .band p '/>
  <ws:rendition selector='#builder .tabcontent .band.activated '/>
  <ws:rendition selector='#builder .tabcontent .band.activated p '/>
  <ws:rendition selector='#builder .tabcontent .band.configured '/>
  <ws:rendition selector='#builder .tabcontent .band.configured p '/>
  <ws:rendition selector='#builder .tabcontent .bands a.visualize,'/>
  <ws:rendition selector='#builder .tabcontent .bands a.visualize:hover,'/>
  <ws:rendition selector='#builder .tabcontent .bands,'/>
  <ws:rendition selector='#builder .tabcontent .options '/>
  <ws:rendition selector='#builder .tabcontent .options.active '/>
  <ws:rendition selector='#builder .tabcontent .region '/>
  <ws:rendition selector='#builder .tabcontent .region a.visualize '/>
  <ws:rendition selector='#builder .tabcontent .region a.visualize:hover '/>
  <ws:rendition selector='#builder .tabcontent form .option '/>
  <ws:rendition selector='#builder .tabcontent form .option label '/>
  <ws:rendition selector='#builder .tabcontent h1 '/>
  <ws:rendition selector='#builder .tabcontent h2 '/>
  <ws:rendition selector='#builder .tabcontent.active '/>
  <ws:rendition selector='#builder div.tabs '/>
  <ws:rendition selector='#builder ul.tabs '/>
  <ws:rendition selector='#builder ul.tabs li '/>
  <ws:rendition selector='#builder ul.tabs li.active '/>
  <ws:rendition selector='#builder ul.tabs li:first-child '/>
  <ws:rendition selector='#content '/>
  <ws:rendition selector='#content .browser '/>
  <ws:rendition selector='#content .facets '/>
  <ws:rendition selector='#content .facets .facet '/>
  <ws:rendition selector='#content .facets .facet > ul '/>
  <ws:rendition selector='#content .facets .facet > ul > div > div > li '/>
  <ws:rendition selector='#content .facets .facet > ul > li,'/>
  <ws:rendition selector='#content .facets .facet h1 '/>
  <ws:rendition selector='#content .facets .facet li > ul '/>
  <ws:rendition selector='#content .facets .facet li a '/>
  <ws:rendition selector='#content .facets .facet li a,'/>
  <ws:rendition selector='#content .facets .facet li a.selected '/>
  <ws:rendition selector='#content .facets .facet li.selected > a '/>
  <ws:rendition selector='#content .facets .facet li.selected > a:hover '/>
  <ws:rendition selector='#content .facets .facet li.selected > ul > li '/>
  <ws:rendition selector='#content .facets .facet ul ul '/>
  <ws:rendition selector='#content .facets .search a '/>
  <ws:rendition selector='#content .facets .search form '/>
  <ws:rendition selector='#content .facets .search input[type=search] '/>
  <ws:rendition selector='#content .facets .search input[type=submit] '/>
  <ws:rendition selector='#content .facets li .facet-count '/>
  <ws:rendition selector='#content .facets li .facet-count:after '/>
  <ws:rendition selector='#content .facets li .facet-count:before '/>
  <ws:rendition selector='#content .region-heading '/>
  <ws:rendition selector='#content .region-heading a.selected '/>
  <ws:rendition selector='#content .region-heading li '/>
  <ws:rendition selector='#content .results '/>
  <ws:rendition selector='#content .results .results-menu '/>
  <ws:rendition selector='#content .results .results-menu .alpha-list li '/>
  <ws:rendition selector='#content .results .results-menu .alpha-list li a '/>
  <ws:rendition selector='#content .results .results-menu > ul '/>
  <ws:rendition selector='#content .results .results-menu > ul > li '/>
  <ws:rendition selector='#content .results .results-menu > ul > li > a '/>
  <ws:rendition selector='#content .results .results-menu > ul > li > ul '/>
  <ws:rendition selector='#content .results .results-menu > ul > li > ul > li '/>
  <ws:rendition selector='#content .results .results-menu > ul > li > ul > li a '/>
  <ws:rendition selector='#content .results .results-menu > ul > li > ul > li a:hover '/>
  <ws:rendition selector='#content .results .results-menu > ul > li:hover '/>
  <ws:rendition selector='#content .results .results-menu > ul > li:hover > a '/>
  <ws:rendition selector='#content .results .results-menu > ul > li:hover > ul '/>
  <ws:rendition selector='#content .results .results-menu:hover '/>
  <ws:rendition selector='#content .results .results-menu:hover > ul '/>
  <ws:rendition selector='#content .results-list '/>
  <ws:rendition selector='#content .results-list li '/>
  <ws:rendition selector='#content .results-list li.yearSelected '/>
  <ws:rendition selector='#content .results-list li:hover '/>
  <ws:rendition selector='#content .results-list li:hover span.actions a.add '/>
  <ws:rendition selector='#content .results-list li:hover span.actions a.add:hover '/>
  <ws:rendition selector='#content .results-list span.actions '/>
  <ws:rendition selector='#content .results-list span.actions a.add '/>
  <ws:rendition selector='#content .results-list span.author:after '/>
  <ws:rendition selector='#content .results-list span.date:before '/>
  <ws:rendition selector='#content .results-list span.genres,'/>
  <ws:rendition selector='#content .results-list span.matches '/>
  <ws:rendition selector='#content .results-list ul '/>
  <ws:rendition selector='#content .timeline '/>
  <ws:rendition selector='#content .timeline .timeline-content '/>
  <ws:rendition selector='#content .timeline .timeline-menu '/>
  <ws:rendition selector='#content .timeline .timeline-menu a '/>
  <ws:rendition selector='#content .timeline .timeline-menu a:hover '/>
  <ws:rendition selector='#content .viewer '/>
  <ws:rendition selector='#content .viewer .region-heading '/>
  <ws:rendition selector='#content .viewer .viewer-inner '/>
  <ws:rendition selector='#content .viewer .viewer-inner .viewer-content '/>
  <ws:rendition selector='#content .viewer .viewer-menu '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > a '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > ul '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > ul > label '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > ul > li '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > ul > li a '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li > ul > li a:hover '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li:hover '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li:hover > a '/>
  <ws:rendition selector='#content .viewer .viewer-menu > ul > li:hover > ul '/>
  <ws:rendition selector='#content .viewer .viewer-menu div '/>
  <ws:rendition selector='#content .viewer .viewer-menu:hover '/>
  <ws:rendition selector='#content .viewer .viewer-menu:hover > ul '/>
  <ws:rendition selector='#content .viewer-content .text .back > div '/>
  <ws:rendition selector='#content .viewer-content .text .body > div,'/>
  <ws:rendition selector='#content .viewer-content .text .front .titleBlock '/>
  <ws:rendition selector='#content .viewer-content .text .front > div,'/>
  <ws:rendition selector='#content .viewer-content .text .titleBlock p '/>
  <ws:rendition selector='#content .viewer-content .text div.body > h1 '/>
  <ws:rendition selector='#content .viewer-content .text p '/>
  <ws:rendition selector='#content .viewer-content .text span.milestone,'/>
  <ws:rendition selector='#content .viewer-content .text span.pb '/>
  <ws:rendition selector='#content .viewer-content .titleBlock h1 '/>
  <ws:rendition selector='#content .viewer-content .titleBlock h1,'/>
  <ws:rendition selector='#content .viewer-content .titleBlock h2 '/>
  <ws:rendition selector='#content .viewer-content .titleBlock h2,'/>
  <ws:rendition selector='#content .viewer-content .titleBlock h3 '/>
  <ws:rendition selector='#content .viewer-content div.poem > div.lg '/>
  <ws:rendition selector='#content .viewer-content h1 '/>
  <ws:rendition selector='#content .viewer-content h2 '/>
  <ws:rendition selector='#content .viewer-content h3 '/>
  <ws:rendition selector='#content .viewer-content span.l '/>
  <ws:rendition selector='#editor '/>
  <ws:rendition selector='#enter '/>
  <ws:rendition selector='#fancy-bg-e '/>
  <ws:rendition selector='#fancy-bg-n '/>
  <ws:rendition selector='#fancy-bg-ne '/>
  <ws:rendition selector='#fancy-bg-nw '/>
  <ws:rendition selector='#fancy-bg-s '/>
  <ws:rendition selector='#fancy-bg-se '/>
  <ws:rendition selector='#fancy-bg-sw '/>
  <ws:rendition selector='#fancy-bg-w '/>
  <ws:rendition selector='#fancybox-close '/>
  <ws:rendition selector='#fancybox-content '/>
  <ws:rendition selector='#fancybox-frame '/>
  <ws:rendition selector='#fancybox-hide-sel-frame '/>
  <ws:rendition selector='#fancybox-img '/>
  <ws:rendition selector='#fancybox-inner '/>
  <ws:rendition selector='#fancybox-left '/>
  <ws:rendition selector='#fancybox-left, #fancybox-right '/>
  <ws:rendition selector='#fancybox-left-ico '/>
  <ws:rendition selector='#fancybox-left-ico, #fancybox-right-ico '/>
  <ws:rendition selector='#fancybox-left:hover span '/>
  <ws:rendition selector='#fancybox-left:hover, #fancybox-right:hover '/>
  <ws:rendition selector='#fancybox-loading '/>
  <ws:rendition selector='#fancybox-loading div '/>
  <ws:rendition selector='#fancybox-loading.fancybox-ie div	'/>
  <ws:rendition selector='#fancybox-outer '/>
  <ws:rendition selector='#fancybox-overlay '/>
  <ws:rendition selector='#fancybox-right '/>
  <ws:rendition selector='#fancybox-right-ico '/>
  <ws:rendition selector='#fancybox-right:hover span '/>
  <ws:rendition selector='#fancybox-title '/>
  <ws:rendition selector='#fancybox-title-left '/>
  <ws:rendition selector='#fancybox-title-main '/>
  <ws:rendition selector='#fancybox-title-over '/>
  <ws:rendition selector='#fancybox-title-right '/>
  <ws:rendition selector='#fancybox-title-wrap '/>
  <ws:rendition selector='#fancybox-title-wrap span '/>
  <ws:rendition selector='#fancybox-tmp '/>
  <ws:rendition selector='#fancybox-wrap '/>
  <ws:rendition selector='#fancybox_error '/>
  <ws:rendition selector='#featured '/>
  <ws:rendition selector='#featured .container '/>
  <ws:rendition selector='#featured .container .featured '/>
  <ws:rendition selector='#featured .container .featured a '/>
  <ws:rendition selector='#featured .container .featured a .author '/>
  <ws:rendition selector='#featured .container .featured a .title '/>
  <ws:rendition selector='#featured .container .featured a:after '/>
  <ws:rendition selector='#featured .container .featured:first-child '/>
  <ws:rendition selector='#featured .container .featured:last-child '/>
  <ws:rendition selector='#featured h1 '/>
  <ws:rendition selector='#foot '/>
  <ws:rendition selector='#footer '/>
  <ws:rendition selector='#footer #neu-brand '/>
  <ws:rendition selector='#footer #neu-brand #dsg-brand '/>
  <ws:rendition selector='#footer #neu-brand #dsg-brand a '/>
  <ws:rendition selector='#footer .container '/>
  <ws:rendition selector='#footer .container #about '/>
  <ws:rendition selector='#footer .container .submissions '/>
  <ws:rendition selector='#footer .container h1 '/>
  <ws:rendition selector='#footer .container p '/>
  <ws:rendition selector='#footer .nusvg '/>
  <ws:rendition selector='#footer a '/>
  <ws:rendition selector='#fulltext '/>
  <ws:rendition selector='#fulltext .body '/>
  <ws:rendition selector='#fulltext .body .container '/>
  <ws:rendition selector='#fulltext .body .container .blockquote '/>
  <ws:rendition selector='#fulltext .body .container .blockquote .lg,'/>
  <ws:rendition selector='#fulltext .body .container .blockquote .lg::first-child,'/>
  <ws:rendition selector='#fulltext .body .container .blockquote .p '/>
  <ws:rendition selector='#fulltext .body .container .blockquote .p::first-child '/>
  <ws:rendition selector='#fulltext .body .container .blockquote .sp '/>
  <ws:rendition selector='#fulltext .body .container .blockquote .sp .p '/>
  <ws:rendition selector='#fulltext .body .container .blockquote .stage '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent #see-also '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .annotations '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .context '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list .p-list-item '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list li,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list.list-labelled '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list.list-labelled > li '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list.list-labelled > li > .li-label '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .p-list.list-labelled > li > .li-labelled '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .persName.active '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .persName[data-wex-ref] '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .persName[data-wex-ref]:hover '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li .back '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li .biblMenu '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li .biblMenu .biblMenuItem '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li.active '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li.active .back '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li.active .biblMenu '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li:hover '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent .section.sources ul li:hover .biblMenu '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h1 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h2 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h3 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h4 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h5 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent h6 '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent p '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent p .blockquote '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul '/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul .p-list-item,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul li,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul.list-labelled > li > .li-label,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul.list-labelled > li > .li-labelled,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul.list-labelled > li,'/>
  <ws:rendition selector='#fulltext .body .container .bodyContent ul.list-labelled,'/>
  <ws:rendition selector='#fulltext .body .container .l '/>
  <ws:rendition selector='#fulltext .body .container .lg '/>
  <ws:rendition selector='#fulltext .body .container .quote '/>
  <ws:rendition selector='#fulltext .body .container .ref '/>
  <ws:rendition selector='#fulltext .body .container .ref:hover '/>
  <ws:rendition selector='#fulltext .body .container .ref[href] '/>
  <ws:rendition selector='#fulltext .body .container .ref[href]:hover '/>
  <ws:rendition selector='#fulltext .body .container .ribbon '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container .bio '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container .dates '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container .extras '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container .extras h2 '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container .label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.label:after '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.label:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.related '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.related a.related '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.related h2,'/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container div.related,'/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container h1 '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context .l + p '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context div.label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context div.label:after '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context div.label:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context div.label:hover:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context h1 + .l '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.context p + .l,'/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.note '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.note div.label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.note div.label:after '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.note div.label:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.note div.label:hover:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.person div.label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.person div.label:after '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.person div.label:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.person div.label:hover:before '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .container.person p '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div .label '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div .label:after '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div ul '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div ul li '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div ul li a '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div ul li a.active '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent .permaContent > div ul li a:hover '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent.pinned '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonContent.pinned .permaContent > div '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread a '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread a.active '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.context a '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.context a.active '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.context a:hover '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.note a '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.note a.active '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.note a:hover '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.person a '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.person a.active '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread.person a:hover '/>
  <ws:rendition selector='#fulltext .body .container .ribbon .ribbonThreads .thread:hover a '/>
  <ws:rendition selector='#fulltext .body .container .speaker '/>
  <ws:rendition selector='#fulltext .body .container p.pullquote '/>
  <ws:rendition selector='#fulltext .body .container p.pullquote + h1 '/>
  <ws:rendition selector='#fulltext .body .container p.pullquote:after '/>
  <ws:rendition selector='#fulltext .body .container p.pullquote:before '/>
  <ws:rendition selector='#fulltext .header '/>
  <ws:rendition selector='#fulltext .header .begin '/>
  <ws:rendition selector='#fulltext .header .headerGroup '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .byline '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .byline .author '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .byline .date '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .keywords '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .keywords a '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .keywords h2 '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container .meta '/>
  <ws:rendition selector='#fulltext .header .headerGroup .container h1 '/>
  <ws:rendition selector='#fulltext .italic '/>
  <ws:rendition selector='#fulltext .sub '/>
  <ws:rendition selector='#fulltext .sup '/>
  <ws:rendition selector='#fulltext .sup,'/>
  <ws:rendition selector='#fulltext .title,'/>
  <ws:rendition selector='#fulltext .title-ital '/>
  <ws:rendition selector='#fulltext .title-up '/>
  <ws:rendition selector='#fulltext .upright '/>
  <ws:rendition selector='#header '/>
  <ws:rendition selector='#header #wwpuniverse table '/>
  <ws:rendition selector='#header #wwpuniverse table tr '/>
  <ws:rendition selector='#header #wwpuniverse table tr .wwpuniverse-component '/>
  <ws:rendition selector='#header #wwpuniverse table tr .wwpuniverse-main '/>
  <ws:rendition selector='#header #wwpuniverse table tr a '/>
  <ws:rendition selector='#header .container '/>
  <ws:rendition selector='#header .container #navbar '/>
  <ws:rendition selector='#header .container #navbar li '/>
  <ws:rendition selector='#header .container #navbar li a '/>
  <ws:rendition selector='#header .container #navbar li.active '/>
  <ws:rendition selector='#header .container #navbar li.active a '/>
  <ws:rendition selector='#header .container #navbar li.active:after '/>
  <ws:rendition selector='#header .container #navbar li:first-child '/>
  <ws:rendition selector='#header .container #navbar li:hover a '/>
  <ws:rendition selector='#header .container #navbar li:last-child '/>
  <ws:rendition selector='#header .container .brand '/>
  <ws:rendition selector='#header .container .brand a '/>
  <ws:rendition selector='#header .container .brand a .logo '/>
  <ws:rendition selector='#header .container .brand a .logo .icon '/>
  <ws:rendition selector='#header .container .brand a .text '/>
  <ws:rendition selector='#header .container .brand a .text .joiner '/>
  <ws:rendition selector='#header .logo '/>
  <ws:rendition selector='#header .logo .icon '/>
  <ws:rendition selector='#header .navbar-nav > li > a '/>
  <ws:rendition selector='#header .navbar-nav > li > a:focus,'/>
  <ws:rendition selector='#header .navbar-nav > li > a:hover '/>
  <ws:rendition selector='#header .navbar-nav > li.open > a '/>
  <ws:rendition selector='#header .text '/>
  <ws:rendition selector='#header .text .titlepart '/>
  <ws:rendition selector='#header .text .titlepart .joiner '/>
  <ws:rendition selector='#info '/>
  <ws:rendition selector='#linkbar '/>
  <ws:rendition selector='#linkbar a '/>
  <ws:rendition selector='#main '/>
  <ws:rendition selector='#main #contents '/>
  <ws:rendition selector='#main #contents .contents-item '/>
  <ws:rendition selector='#main #contents .contents-item .info '/>
  <ws:rendition selector='#main #contents .contents-item .info .author,'/>
  <ws:rendition selector='#main #contents .contents-item .info .title '/>
  <ws:rendition selector='#main #contents .contents-item .thumb '/>
  <ws:rendition selector='#main #contents.grid .contents-item '/>
  <ws:rendition selector='#main #contents.grid .contents-item .info '/>
  <ws:rendition selector='#main #contents.grid .contents-item .info .author '/>
  <ws:rendition selector='#main #contents.grid .contents-item .info .title '/>
  <ws:rendition selector='#main #contents.grid .contents-item .thumb '/>
  <ws:rendition selector='#main #contents.grid .contents-item:hover '/>
  <ws:rendition selector='#main #contents.grid .contents-item:nth-child(3n) '/>
  <ws:rendition selector='#main #contents.grid .contents-item:nth-child(3n+1) '/>
  <ws:rendition selector='#main #contents.list .contents-item '/>
  <ws:rendition selector='#main #contents.list .contents-item .info '/>
  <ws:rendition selector='#main #contents.list .contents-item .info .author '/>
  <ws:rendition selector='#main #contents.list .contents-item .info .title '/>
  <ws:rendition selector='#main #contents.list .contents-item .thumb '/>
  <ws:rendition selector='#main #contents.list .contents-item .thumb img '/>
  <ws:rendition selector='#main #sidebar '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"] '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"] span '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"] span:after '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"] span:before '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"].active '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"].active span '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"].active:after '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"].active:hover '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"].active:hover:after '/>
  <ws:rendition selector='#main #sidebar div a[data-wex-action="filter"]:hover '/>
  <ws:rendition selector='#main #sidebar div h1 '/>
  <ws:rendition selector='#main .menu .menu-item:first-child '/>
  <ws:rendition selector='#mainfields '/>
  <ws:rendition selector='#marquee '/>
  <ws:rendition selector='#marquee h1 '/>
  <ws:rendition selector='#marquee h2 '/>
  <ws:rendition selector='#nav a '/>
  <ws:rendition selector='#nav li '/>
  <ws:rendition selector='#nav li ul '/>
  <ws:rendition selector='#nav li:hover ul, #nav li.sfhover ul '/>
  <ws:rendition selector='#nav ul '/>
  <ws:rendition selector='#nav ul li'/>
  <ws:rendition selector='#nav ul li a '/>
  <ws:rendition selector='#nav ul li a. '/>
  <ws:rendition selector='#nav ul li a:hover '/>
  <ws:rendition selector='#nav ul li.activenav  '/>
  <ws:rendition selector='#nav ul li.activenav a '/>
  <ws:rendition selector='#nav, #nav ul '/>
  <ws:rendition selector='#overlay '/>
  <ws:rendition selector='#overlay.active '/>
  <ws:rendition selector='#pagecontent '/>
  <ws:rendition selector='#pagecontent p, #pagecontent h1, #pagecontent li '/>
  <ws:rendition selector='#pagecontent_schedule '/>
  <ws:rendition selector='#pagecontent_schedule p '/>
  <ws:rendition selector='#panel '/>
  <ws:rendition selector='#panel #cor-home '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes > div '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes a '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes a span.glyphicon '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes a:hover '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer .cor-indexes a:hover span.glyphicon '/>
  <ws:rendition selector='#panel #cor-home .cor-explorer h1 '/>
  <ws:rendition selector='#panel #cor-home .quote-box '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .h2 a,'/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .h2,'/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .pullquote '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .pullquote .pullquote-emph '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .pullquote.pullquote-emph,'/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .quote '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .quote > p:first-child:after '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .quote > p:first-child:before '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes .quote > p:first-child:before,'/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes h2 '/>
  <ws:rendition selector='#panel #cor-home .quote-box #carousel-quotes h2 a '/>
  <ws:rendition selector='#panel #cor-home .quote-box .title '/>
  <ws:rendition selector='#panel #cor-home .quote-box > h2 '/>
  <ws:rendition selector='#panel #reception #facets-panel '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter .badge '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-deselected '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-disabled '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-disabled .badge '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-selected '/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-selected .badge,'/>
  <ws:rendition selector='#panel #reception #facets-panel .cor-filter.facet-selected,'/>
  <ws:rendition selector='#panel #reception #facets-panel .facet-grp '/>
  <ws:rendition selector='#panel #reception #facets-panel .facet-grp ul.facet-list '/>
  <ws:rendition selector='#panel #reception #facets-panel .facet-grp ul.facet-list li '/>
  <ws:rendition selector='#panel #reception #facets-panel .facet-header-sub '/>
  <ws:rendition selector='#panel #reception #facets-panel button.cor-expander '/>
  <ws:rendition selector='#panel #reception #facets-panel button.cor-expander span.glyphicon '/>
  <ws:rendition selector='#panel #reception #facets-panel button.cor-expander.active '/>
  <ws:rendition selector='#panel #reception #facets-panel p '/>
  <ws:rendition selector='#panel #reception #facets-panel span.badge '/>
  <ws:rendition selector='#panel #reception #metaentry '/>
  <ws:rendition selector='#panel #reception #metaentry .h1,'/>
  <ws:rendition selector='#panel #reception #metaentry .h2 '/>
  <ws:rendition selector='#panel #reception #metaentry h1 '/>
  <ws:rendition selector='#panel #reception #metaentry h1,'/>
  <ws:rendition selector='#panel #reception #metaentry h2,'/>
  <ws:rendition selector='#panel #reception #reader .hi '/>
  <ws:rendition selector='#panel #reception #reader .metadata '/>
  <ws:rendition selector='#panel #reception #reader .metadata .wwo-link '/>
  <ws:rendition selector='#panel #reception #reader .metadata .wwo-link-expanded img '/>
  <ws:rendition selector='#panel #reception #reader .transcription '/>
  <ws:rendition selector='#panel #reception #reader .transcription .blockquote,'/>
  <ws:rendition selector='#panel #reception #reader .transcription .gap '/>
  <ws:rendition selector='#panel #reception #reader .transcription .head '/>
  <ws:rendition selector='#panel #reception #reader .transcription .lg '/>
  <ws:rendition selector='#panel #reception #reader .transcription .lg .l '/>
  <ws:rendition selector='#panel #reception #reader .transcription .note-inline '/>
  <ws:rendition selector='#panel #reception #reader .transcription .quote:after '/>
  <ws:rendition selector='#panel #reception #reader .transcription .quote:before '/>
  <ws:rendition selector='#panel #reception #reader .transcription p.gap '/>
  <ws:rendition selector='#panel #reception #reader .transcription span.gap '/>
  <ws:rendition selector='#panel #reception #reader h1 '/>
  <ws:rendition selector='#panel #reception #reader h1 .title '/>
  <ws:rendition selector='#panel #reception #results '/>
  <ws:rendition selector='#panel #reception #results .cor-nav '/>
  <ws:rendition selector='#panel #reception #results .cor-nav button.cor-to-top '/>
  <ws:rendition selector='#panel #reception #results .cor-nav button.cor-to-top:focus,'/>
  <ws:rendition selector='#panel #reception #results .cor-nav button.cor-to-top:hover '/>
  <ws:rendition selector='#panel #reception #results .results-pane '/>
  <ws:rendition selector='#panel #reception #results .results-pane nav '/>
  <ws:rendition selector='#panel #reception #results .results-pane nav ul.pagination .dropdown-menu '/>
  <ws:rendition selector='#panel #reception #results h2 '/>
  <ws:rendition selector='#panel #reception #sort-select '/>
  <ws:rendition selector='#panel #reception #sort-select .radio '/>
  <ws:rendition selector='#panel #reception .facets '/>
  <ws:rendition selector='#panel #reception .filtered-out '/>
  <ws:rendition selector='#panel #reception .label-as-badge '/>
  <ws:rendition selector='#panel #reception .metadata '/>
  <ws:rendition selector='#panel #reception .metadata .context '/>
  <ws:rendition selector='#panel #reception .metadata .context:after '/>
  <ws:rendition selector='#panel #reception .metadata .extlinks '/>
  <ws:rendition selector='#panel #reception .metadata .fieldname '/>
  <ws:rendition selector='#panel #reception .metadata .fieldname,'/>
  <ws:rendition selector='#panel #reception .metadata .fieldname.span-inline '/>
  <ws:rendition selector='#panel #reception .metadata .fieldvalue '/>
  <ws:rendition selector='#panel #reception .metadata .hangindent '/>
  <ws:rendition selector='#panel #reception .metadata .worklist '/>
  <ws:rendition selector='#panel #reception .metadata .worklist dd.cor-button '/>
  <ws:rendition selector='#panel #reception .metadata .worklist dt '/>
  <ws:rendition selector='#panel #reception .metadata .wwo-link a '/>
  <ws:rendition selector='#panel #reception .metadata .wwo-link.wwo-link-expanded .btn,'/>
  <ws:rendition selector='#panel #reception .metadata .wwo-link.wwo-link-expanded .btn-sm,'/>
  <ws:rendition selector='#panel #reception .metadata .wwo-link.wwo-link-expanded img '/>
  <ws:rendition selector='#panel #reception .metadata div.panel-heading '/>
  <ws:rendition selector='#panel #reception .metadata div.panel-heading h3 '/>
  <ws:rendition selector='#panel #reception .metadata dl '/>
  <ws:rendition selector='#panel #reception .metadata dl dd .title '/>
  <ws:rendition selector='#panel #reception .metadata dt + dd '/>
  <ws:rendition selector='#panel #reception .metadata dt,'/>
  <ws:rendition selector='#panel #reception .metadata dt:first-child '/>
  <ws:rendition selector='#panel #reception .metadata li '/>
  <ws:rendition selector='#panel #reception .metadata li,'/>
  <ws:rendition selector='#panel #reception .metadata p,'/>
  <ws:rendition selector='#panel #reception .metadata ul '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity .frbr-header '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity .frbr-header .btn-default '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity .frbr-header .btn-default .glyphicon '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity .frbr-header .btn-default[disabled] '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity .frbr-header .frbr-label '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h1 .subtitle,'/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h1 .wwo-link,'/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h1,'/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h2 '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h2 .subtitle '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity h2 .wwo-link '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.entry-match '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.frbr-entity-manifestation '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.frbr-entity-manifestation .frbr-header '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.frbr-entity-manifestation .frbr-header .btn-default '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.frbr-entity-manifestation .imprint-condensed '/>
  <ws:rendition selector='#panel #reception .metadata.frbr-entity.frbr-entity-manifestation .imprint-condensed .publication '/>
  <ws:rendition selector='#panel #reception .results-list .results-list-item '/>
  <ws:rendition selector='#panel #reception .results-list .results-list-item .results-item-entry '/>
  <ws:rendition selector='#panel #reception .results-list .results-list-item .results-item-title '/>
  <ws:rendition selector='#panel #reception .results-list .results-list-item .results-item-title .cor-expander '/>
  <ws:rendition selector='#panel #reception .results-list li '/>
  <ws:rendition selector='#panel #reception .text-main a '/>
  <ws:rendition selector='#panel #reception .title-stmt .title-rcvd '/>
  <ws:rendition selector='#panel #reception .title-stmt .title-src '/>
  <ws:rendition selector='#panel #reception span.facet-badge '/>
  <ws:rendition selector='#panel #reception span.facet-badge a '/>
  <ws:rendition selector='#panel #reception span.facet-badge a .taxonomy '/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="format"] '/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="genre"] '/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="miscellaneous"] '/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="reception"] '/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="reception"],'/>
  <ws:rendition selector='#panel #reception span.facet-badge[data-cor-taxonomy="theme"] '/>
  <ws:rendition selector='#panel #reception span.facet-label a .taxonomy,'/>
  <ws:rendition selector='#panel #reception span.facet-label a,'/>
  <ws:rendition selector='#panel #reception span.facet-label,'/>
  <ws:rendition selector='#panel #reception span.facet-label[data-cor-taxonomy="format"],'/>
  <ws:rendition selector='#panel #reception span.facet-label[data-cor-taxonomy="genre"],'/>
  <ws:rendition selector='#panel #reception span.facet-label[data-cor-taxonomy="miscellaneous"],'/>
  <ws:rendition selector='#panel #reception span.facet-label[data-cor-taxonomy="reception"],'/>
  <ws:rendition selector='#panel #reception span.facet-label[data-cor-taxonomy="theme"],'/>
  <ws:rendition selector='#panel .blockquote '/>
  <ws:rendition selector='#panel .btn-link '/>
  <ws:rendition selector='#panel .btn-link.btn-info '/>
  <ws:rendition selector='#panel .cor-button '/>
  <ws:rendition selector='#panel .cor-index '/>
  <ws:rendition selector='#panel .cor-index .index-list '/>
  <ws:rendition selector='#panel .cor-index .index-list a,'/>
  <ws:rendition selector='#panel .cor-index .index-list li '/>
  <ws:rendition selector='#panel .cor-index .index-list li .desc '/>
  <ws:rendition selector='#panel .cor-index .index-list li:first-child '/>
  <ws:rendition selector='#panel .cor-index.tags-pg h2 '/>
  <ws:rendition selector='#panel .cor-panel '/>
  <ws:rendition selector='#panel .h2 .title,'/>
  <ws:rendition selector='#panel .h2,'/>
  <ws:rendition selector='#panel .h3 .title,'/>
  <ws:rendition selector='#panel .h3,'/>
  <ws:rendition selector='#panel .h4 .title,'/>
  <ws:rendition selector='#panel .h4,'/>
  <ws:rendition selector='#panel .h5 .title,'/>
  <ws:rendition selector='#panel .h5,'/>
  <ws:rendition selector='#panel .h6 '/>
  <ws:rendition selector='#panel .h6 .title '/>
  <ws:rendition selector='#panel .header-wwpstyle '/>
  <ws:rendition selector='#panel .pagination > .active > a,'/>
  <ws:rendition selector='#panel .pagination > .active > a:focus,'/>
  <ws:rendition selector='#panel .pagination > .active > a:hover '/>
  <ws:rendition selector='#panel .pagination > li > a:focus,'/>
  <ws:rendition selector='#panel .pagination > li > a:hover '/>
  <ws:rendition selector='#panel .pagination a '/>
  <ws:rendition selector='#panel .results-list .results-item-title a '/>
  <ws:rendition selector='#panel .span-inline '/>
  <ws:rendition selector='#panel .title '/>
  <ws:rendition selector='#panel > div '/>
  <ws:rendition selector='#panel div[id].anchor-inner '/>
  <ws:rendition selector='#panel h1 '/>
  <ws:rendition selector='#panel h1 .title,'/>
  <ws:rendition selector='#panel h1,'/>
  <ws:rendition selector='#panel h2 .title,'/>
  <ws:rendition selector='#panel h2,'/>
  <ws:rendition selector='#panel h3 .title,'/>
  <ws:rendition selector='#panel h3,'/>
  <ws:rendition selector='#panel h4 .title,'/>
  <ws:rendition selector='#panel h4,'/>
  <ws:rendition selector='#panel h5 .title,'/>
  <ws:rendition selector='#panel h5,'/>
  <ws:rendition selector='#panel h6 .h1 .title,'/>
  <ws:rendition selector='#panel h6 .h1,'/>
  <ws:rendition selector='#panel table '/>
  <ws:rendition selector='#query '/>
  <ws:rendition selector='#querytext, #maincontents '/>
  <ws:rendition selector='#reader '/>
  <ws:rendition selector='#reader .reader-content '/>
  <ws:rendition selector='#reader .reader-content .left '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner .titleBlock p '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner div.body > h1 '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner div.poem > div.lg '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner div.titleBlock,'/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner h1 '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner h2 '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner h3 '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner p '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner span.l '/>
  <ws:rendition selector='#reader .reader-content .reader-content-inner span.mw '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc .toc-marker '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc .toc-marker > a '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc .toc-marker ol '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc .toc-marker ol a:hover '/>
  <ws:rendition selector='#reader .reader-content .reader-content-toc .toc-marker:hover > a '/>
  <ws:rendition selector='#reader .reader-content .right '/>
  <ws:rendition selector='#reader .reader-content-extras '/>
  <ws:rendition selector='#reader .reader-menu '/>
  <ws:rendition selector='#reader .reader-menu li '/>
  <ws:rendition selector='#reader .reader-menu li a '/>
  <ws:rendition selector='#reader .reader-menu li a:hover '/>
  <ws:rendition selector='#reader .reader-menu li#close '/>
  <ws:rendition selector='#reader .reader-menu li#close a '/>
  <ws:rendition selector='#reader .reader-menu li#close a:hover '/>
  <ws:rendition selector='#reader .reader-menu ul '/>
  <ws:rendition selector='#reader .reader-sub '/>
  <ws:rendition selector='#sort-table '/>
  <ws:rendition selector='#sort-table p:last-child:after, #sort-table li:last-child:after '/>
  <ws:rendition selector='#sort-table td '/>
  <ws:rendition selector='#sort-table td.fullview '/>
  <ws:rendition selector='#sort-table td.fullview img '/>
  <ws:rendition selector='#sort-table td.institution '/>
  <ws:rendition selector='#sort-table td.instructor '/>
  <ws:rendition selector='#sort-table th '/>
  <ws:rendition selector='#sort-table th.headerSortDown '/>
  <ws:rendition selector='#sort-table th.headerSortUp '/>
  <ws:rendition selector='#sort-table th.nosort '/>
  <ws:rendition selector='#sort-table thead '/>
  <ws:rendition selector='#sort-table tr '/>
  <ws:rendition selector='#sort-table tr:hover '/>
  <ws:rendition selector='#sort-table tr:hover td.fullview img '/>
  <ws:rendition selector='#sublink '/>
  <ws:rendition selector='#tabdesc '/>
  <ws:rendition selector='#timeline '/>
  <ws:rendition selector='#timeline .close '/>
  <ws:rendition selector='#timeline .close:hover '/>
  <ws:rendition selector='#timeline .title '/>
  <ws:rendition selector='#timeline .vco-storyjs a '/>
  <ws:rendition selector='#timeline .vco-storyjs a:hover '/>
  <ws:rendition selector='#timeline .wiki-source + p '/>
  <ws:rendition selector='#timeline blockquote '/>
  <ws:rendition selector='#timeline h2.date '/>
  <ws:rendition selector='#title '/>
  <ws:rendition selector='#tooltip '/>
  <ws:rendition selector='#topbuttons '/>
  <ws:rendition selector='#visor '/>
  <ws:rendition selector='#visor #timeline '/>
  <ws:rendition selector='#visor #timeline h1 '/>
  <ws:rendition selector='#visor .configure a,'/>
  <ws:rendition selector='#visor .configure h1,'/>
  <ws:rendition selector='#visor .configure,'/>
  <ws:rendition selector='#visor .configure-types ul '/>
  <ws:rendition selector='#visor .default-message '/>
  <ws:rendition selector='#visor .default-message a '/>
  <ws:rendition selector='#visr '/>
  <ws:rendition selector='#what '/>
  <ws:rendition selector='#what a '/>
  <ws:rendition selector='#what a span '/>
  <ws:rendition selector='#what a:hover span '/>
  <ws:rendition selector='#what li '/>
  <ws:rendition selector='#what li ul '/>
  <ws:rendition selector='#what li:hover ul, #what li.sfhover ul '/>
  <ws:rendition selector='#what, #what ul '/>
  <ws:rendition selector='#word '/>
  <ws:rendition selector='#wwo '/>
  <ws:rendition selector='#wwolink '/>
  <ws:rendition selector='#wwolink a:active  '/>
  <ws:rendition selector='#wwolink a:hover  '/>
  <ws:rendition selector='#wwolink a:link  '/>
  <ws:rendition selector='#wwolink a:visited  '/>
  <ws:rendition selector='#wwosublink '/>
  <ws:rendition selector='* html #fancybox-loading '/>
  <ws:rendition selector='* html #fancybox-overlay '/>
  <ws:rendition selector='* html .jspCorner'/>
  <ws:rendition selector='* html button '/>
  <ws:rendition selector='* html select '/>
  <ws:rendition selector='* html textarea,'/>
  <ws:rendition selector='*.interest '/>
  <ws:rendition selector='*[data-ft-match] '/>
  <ws:rendition selector='*[data-ft-match][data-ft-match=exact] '/>
  <ws:rendition selector='.ATT '/>
  <ws:rendition selector='.BIG '/>
  <ws:rendition selector='.BIG-BLACK '/>
  <ws:rendition selector='.BIG-BLACK-CENTER '/>
  <ws:rendition selector='.BIG-BLOCK-ALLCAPS '/>
  <ws:rendition selector='.BIG-BLOCK-BLACKLETTER '/>
  <ws:rendition selector='.BIG-BLOCK-ITALIC '/>
  <ws:rendition selector='.BIG-BLUE-CENTER '/>
  <ws:rendition selector='.BIG-GREEN '/>
  <ws:rendition selector='.BIG-GREEN-CENTER '/>
  <ws:rendition selector='.BIG-RED '/>
  <ws:rendition selector='.BIG-RED-CENTER '/>
  <ws:rendition selector='.BLOCK-CENTER-ALLCAPS '/>
  <ws:rendition selector='.BLOCK-CENTER-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.BLOCK-CENTER-BLACKLETTER '/>
  <ws:rendition selector='.BLOCK-CENTER-ITALIC '/>
  <ws:rendition selector='.BLOCK-CENTER-SMALLCAPS '/>
  <ws:rendition selector='.BLOCK-CENTER-UPRIGHT '/>
  <ws:rendition selector='.BLOCK-CENTER-UPRIGHT-BOLD '/>
  <ws:rendition selector='.BLOCK-INDENTED-ALLCAPS '/>
  <ws:rendition selector='.BLOCK-INDENTED-ITALIC '/>
  <ws:rendition selector='.BLOCK-INDENTED-UPRIGHT '/>
  <ws:rendition selector='.BLOCK-LEFT-ALLCAPS '/>
  <ws:rendition selector='.BLOCK-LEFT-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.BLOCK-LEFT-BLACKLETTER '/>
  <ws:rendition selector='.BLOCK-LEFT-ITALIC '/>
  <ws:rendition selector='.BLOCK-LEFT-SMALLCAPS '/>
  <ws:rendition selector='.BLOCK-LEFT-UPRIGHT '/>
  <ws:rendition selector='.BLOCK-LEFT-UPRIGHT-BOLD '/>
  <ws:rendition selector='.BLOCK-LEFT-UPRIGHT-GREEN '/>
  <ws:rendition selector='.BLOCK-OVERHANG-ITALIC '/>
  <ws:rendition selector='.BLOCK-OVERHANG-UPRIGHT '/>
  <ws:rendition selector='.BLOCK-RIGHT-ALLCAPS '/>
  <ws:rendition selector='.BLOCK-RIGHT-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.BLOCK-RIGHT-ITALIC '/>
  <ws:rendition selector='.BLOCK-RIGHT-SMALLCAPS '/>
  <ws:rendition selector='.BLOCK-RIGHT-UPRIGHT '/>
  <ws:rendition selector='.BLOCK-RIGHT-UPRIGHT-BOLD '/>
  <ws:rendition selector='.BODY-FOR-HELP-DOC '/>
  <ws:rendition selector='.BODY-NAV '/>
  <ws:rendition selector='.BODY-REG '/>
  <ws:rendition selector='.BOOKINFO '/>
  <ws:rendition selector='.BigContent '/>
  <ws:rendition selector='.Body '/>
  <ws:rendition selector='.COM '/>
  <ws:rendition selector='.COM-REF '/>
  <ws:rendition selector='.Content '/>
  <ws:rendition selector='.ENTITY '/>
  <ws:rendition selector='.ENTRY-LINK '/>
  <ws:rendition selector='.ETAGC '/>
  <ws:rendition selector='.ETAGO '/>
  <ws:rendition selector='.EntryList '/>
  <ws:rendition selector='.EntryList, .HelpList, .TextList '/>
  <ws:rendition selector='.FIGDESC '/>
  <ws:rendition selector='.FILENAME '/>
  <ws:rendition selector='.GI '/>
  <ws:rendition selector='.GI    '/>
  <ws:rendition selector='.GLOSS '/>
  <ws:rendition selector='.HEAD-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.HEAD-ALLCAPS-UPRIGHT '/>
  <ws:rendition selector='.HEAD-BLACKLETTER '/>
  <ws:rendition selector='.HEAD-DOC-FIVE '/>
  <ws:rendition selector='.HEAD-DOC-FOUR '/>
  <ws:rendition selector='.HEAD-DOC-LIST '/>
  <ws:rendition selector='.HEAD-DOC-ONE '/>
  <ws:rendition selector='.HEAD-DOC-THREE '/>
  <ws:rendition selector='.HEAD-DOC-TWO '/>
  <ws:rendition selector='.HEAD-INLINE-ALLCAPS '/>
  <ws:rendition selector='.HEAD-INLINE-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.HEAD-INLINE-ITALIC '/>
  <ws:rendition selector='.HEAD-INLINE-SMALLCAPS '/>
  <ws:rendition selector='.HEAD-INLINE-UPRIGHT '/>
  <ws:rendition selector='.HEAD-ITALIC '/>
  <ws:rendition selector='.HEAD-LEFT-ALLCAPS '/>
  <ws:rendition selector='.HEAD-LEFT-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.HEAD-LEFT-ITALIC '/>
  <ws:rendition selector='.HEAD-LEFT-SMALLCAPS '/>
  <ws:rendition selector='.HEAD-LEFT-UPRIGHT '/>
  <ws:rendition selector='.HEAD-OVERHANG-ITALIC '/>
  <ws:rendition selector='.HEAD-OVERHANG-ITALIC-ALLCAPS '/>
  <ws:rendition selector='.HEAD-OVERHANG-UPRIGHT '/>
  <ws:rendition selector='.HEAD-RIGHT-ALLCAPS '/>
  <ws:rendition selector='.HEAD-RIGHT-ITALIC '/>
  <ws:rendition selector='.HEAD-RIGHT-SMALLCAPS '/>
  <ws:rendition selector='.HEAD-RIGHT-UPRIGHT '/>
  <ws:rendition selector='.HEAD-SMALLCAPS-ITALIC '/>
  <ws:rendition selector='.HEAD-SMALLCAPS-UPRIGHT '/>
  <ws:rendition selector='.HEAD-TOC '/>
  <ws:rendition selector='.HEAD-UPRIGHT '/>
  <ws:rendition selector='.HEADER '/>
  <ws:rendition selector='.HEADER-TOP '/>
  <ws:rendition selector='.HEADER2 '/>
  <ws:rendition selector='.HEADER2-1 '/>
  <ws:rendition selector='.HEADER3 '/>
  <ws:rendition selector='.HEADER3-1 '/>
  <ws:rendition selector='.HEADER4 '/>
  <ws:rendition selector='.HEADER4-1 '/>
  <ws:rendition selector='.HEADER5 '/>
  <ws:rendition selector='.HEADER5-1 '/>
  <ws:rendition selector='.HEADER6 '/>
  <ws:rendition selector='.HEADER6-1 '/>
  <ws:rendition selector='.HEADER7 '/>
  <ws:rendition selector='.HITWORD-FOR-KWIC-HEAD '/>
  <ws:rendition selector='.HR-CENTER '/>
  <ws:rendition selector='.HelpList '/>
  <ws:rendition selector='.INLINE-ALLCAPS '/>
  <ws:rendition selector='.INLINE-ALLCAPS-BLACKLETTER '/>
  <ws:rendition selector='.INLINE-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.INLINE-BACKGROUND-LIGHTGREEN '/>
  <ws:rendition selector='.INLINE-BACKGROUND-LIGHTGREY '/>
  <ws:rendition selector='.INLINE-BACKGROUND-LIGHTPINK '/>
  <ws:rendition selector='.INLINE-BACKGROUND-LIGHTSKYBLUE '/>
  <ws:rendition selector='.INLINE-BACKGROUND-ORANGE '/>
  <ws:rendition selector='.INLINE-BACKGROUND-RED '/>
  <ws:rendition selector='.INLINE-BACKGROUND-YELLOW '/>
  <ws:rendition selector='.INLINE-BLACKLETTER '/>
  <ws:rendition selector='.INLINE-BOLD '/>
  <ws:rendition selector='.INLINE-BOLD-GREEN '/>
  <ws:rendition selector='.INLINE-GREEN '/>
  <ws:rendition selector='.INLINE-INDENTED-ITALIC '/>
  <ws:rendition selector='.INLINE-INDENTED-UPRIGHT '/>
  <ws:rendition selector='.INLINE-ITALIC '/>
  <ws:rendition selector='.INLINE-LINK-TEST '/>
  <ws:rendition selector='.INLINE-SMALLCAPS '/>
  <ws:rendition selector='.INLINE-SMALLCAPS-ITALIC '/>
  <ws:rendition selector='.INLINE-UPRIGHT '/>
  <ws:rendition selector='.ITEM '/>
  <ws:rendition selector='.IndxBox2 '/>
  <ws:rendition selector='.IndxBox2, .IndxBox3, .IndxBox4, .IndxBox5, .TopBox1, .TopBox2, .TopBox3, .TopBox4, .TopBox5, .TopBox6 '/>
  <ws:rendition selector='.IndxBox2, .IndxBox3, .IndxBox4, .IndxBox5, .TopBox1, .TopBox2, .TopBox3, .TopBox4, .TopBox5, .TopBox6, .UnderTopFill, .PhiloLogo, .Side '/>
  <ws:rendition selector='.IndxBox3 '/>
  <ws:rendition selector='.IndxBox4 '/>
  <ws:rendition selector='.IndxBox5 '/>
  <ws:rendition selector='.KWIC-CHUNK '/>
  <ws:rendition selector='.KWIC-CONTEXT '/>
  <ws:rendition selector='.KWIC-CONTEXT-SMALL '/>
  <ws:rendition selector='.KWIC-HIT '/>
  <ws:rendition selector='.KWIC-HIT-SMALL '/>
  <ws:rendition selector='.KWIC-REF '/>
  <ws:rendition selector='.L '/>
  <ws:rendition selector='.LG-BLOCK '/>
  <ws:rendition selector='.LG-INNER '/>
  <ws:rendition selector='.LG-SECTION '/>
  <ws:rendition selector='.LG-WRAPPER '/>
  <ws:rendition selector='.LG-WRAPPER, .LG-SECTION, .LG-INNER, .L '/>
  <ws:rendition selector='.LITa '/>
  <ws:rendition selector='.LONG-SEARCH-STRING '/>
  <ws:rendition selector='.MAIN-HEAD '/>
  <ws:rendition selector='.MAJOR-LINK '/>
  <ws:rendition selector='.MDC '/>
  <ws:rendition selector='.MDO '/>
  <ws:rendition selector='.NAVIGATION-BLOCK '/>
  <ws:rendition selector='.NAVIGATION-INLINE '/>
  <ws:rendition selector='.NAVIGATION-TABLE '/>
  <ws:rendition selector='.NEXT '/>
  <ws:rendition selector='.ORIG '/>
  <ws:rendition selector='.PCDATA '/>
  <ws:rendition selector='.PIC '/>
  <ws:rendition selector='.PIO '/>
  <ws:rendition selector='.PIcontent '/>
  <ws:rendition selector='.PIname '/>
  <ws:rendition selector='.PLAINCELL '/>
  <ws:rendition selector='.PRE-ALONE '/>
  <ws:rendition selector='.PRE-INLINE '/>
  <ws:rendition selector='.PURPLE-LABEL '/>
  <ws:rendition selector='.PhiloLogo '/>
  <ws:rendition selector='.REALLY-LONG-SEARCH-STRING '/>
  <ws:rendition selector='.REG-CODE '/>
  <ws:rendition selector='.REND-LADDER-KEYWORD '/>
  <ws:rendition selector='.RUNNING-HEAD '/>
  <ws:rendition selector='.RUNNING-HEAD-BG '/>
  <ws:rendition selector='.RUNNING-HEADER '/>
  <ws:rendition selector='.RUNNING-HEADER2 '/>
  <ws:rendition selector='.ResultsPage, .SearchPage '/>
  <ws:rendition selector='.SCM-DOCAUTHOR '/>
  <ws:rendition selector='.SCM-DOCDATE '/>
  <ws:rendition selector='.SCM-DOCROLE '/>
  <ws:rendition selector='.SCM-HEAD '/>
  <ws:rendition selector='.SCM-LIST-ITEM '/>
  <ws:rendition selector='.SCM-SECTION-HEAD '/>
  <ws:rendition selector='.SCM-SECTION-SUBHEAD '/>
  <ws:rendition selector='.SCM-TP '/>
  <ws:rendition selector='.SECTION-HEAD '/>
  <ws:rendition selector='.SIC '/>
  <ws:rendition selector='.SMALL '/>
  <ws:rendition selector='.SMALL-BLACK '/>
  <ws:rendition selector='.SMALL-BLACK-CENTER '/>
  <ws:rendition selector='.SMALL-BLUE-CENTER '/>
  <ws:rendition selector='.SMALL-ENTRY-LINK '/>
  <ws:rendition selector='.SMALL-GREEN '/>
  <ws:rendition selector='.SMALL-GREEN-CENTER '/>
  <ws:rendition selector='.SMALL-RED '/>
  <ws:rendition selector='.SMALL-RED-CENTER '/>
  <ws:rendition selector='.SMALLCAPS '/>
  <ws:rendition selector='.SMALLCAPS-HACK '/>
  <ws:rendition selector='.SMALLCELL '/>
  <ws:rendition selector='.SMALLER '/>
  <ws:rendition selector='.SPEAKER '/>
  <ws:rendition selector='.SPECIAL-TO-MAKE-HTML-LESS-INVALID '/>
  <ws:rendition selector='.STAGC '/>
  <ws:rendition selector='.STAGE '/>
  <ws:rendition selector='.STAGE-BLOCK '/>
  <ws:rendition selector='.STAGO '/>
  <ws:rendition selector='.SUBSCRIPT-ITALIC '/>
  <ws:rendition selector='.SUBSCRIPT-UPRIGHT '/>
  <ws:rendition selector='.SUPERSCRIPT-ITALIC '/>
  <ws:rendition selector='.SUPERSCRIPT-UPRIGHT '/>
  <ws:rendition selector='.SearchPage '/>
  <ws:rendition selector='.Side '/>
  <ws:rendition selector='.SideBox, .SideBoxSpecial '/>
  <ws:rendition selector='.SideSpecial '/>
  <ws:rendition selector='.TAG '/>
  <ws:rendition selector='.TAG-SMALL '/>
  <ws:rendition selector='.TB-BLOCK '/>
  <ws:rendition selector='.TB-BLOCK-ALLCAPS '/>
  <ws:rendition selector='.TB-BLOCK-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.TB-BLOCK-BLACKLETTER '/>
  <ws:rendition selector='.TB-BLOCK-ITALIC '/>
  <ws:rendition selector='.TB-FIGDESC '/>
  <ws:rendition selector='.TB-LIST-ITEM-BOLD '/>
  <ws:rendition selector='.TB-TP-MAIN-ALLCAPS '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-ALLCAPS '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-BLACKLETTER '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-ITALIC '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-SMALLCAPS '/>
  <ws:rendition selector='.TB-TP-MAIN-INLINE-UPRIGHT '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-ALLCAPS '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-ALLCAPS-ITALIC '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-BLACKLETTER '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-ITALIC '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-SMALLCAPS '/>
  <ws:rendition selector='.TB-TP-SUB-INLINE-UPRIGHT '/>
  <ws:rendition selector='.TB-TP-SUB-UPRIGHT '/>
  <ws:rendition selector='.TERM '/>
  <ws:rendition selector='.TEST '/>
  <ws:rendition selector='.TP-BLOCK '/>
  <ws:rendition selector='.TP-LIST-ITEM-BOLD '/>
  <ws:rendition selector='.TP-TITLEPART-MAIN-ALLCAPS '/>
  <ws:rendition selector='.TP-TITLEPART-MAIN-UPRIGHT '/>
  <ws:rendition selector='.TP-TITLEPART-SUB-UPRIGHT '/>
  <ws:rendition selector='.TP-TITLEPART-SUB-UPRIGHT-ACH '/>
  <ws:rendition selector='.Tabs '/>
  <ws:rendition selector='.Tabs div '/>
  <ws:rendition selector='.Tabs li.Active '/>
  <ws:rendition selector='.Tabs li.Active a '/>
  <ws:rendition selector='.Tabs li.Tab '/>
  <ws:rendition selector='.Tabs li.Tab a '/>
  <ws:rendition selector='.Tabs ul '/>
  <ws:rendition selector='.TopBox1 '/>
  <ws:rendition selector='.TopBox2 '/>
  <ws:rendition selector='.TopBox3 '/>
  <ws:rendition selector='.TopBox4 '/>
  <ws:rendition selector='.TopBox5 '/>
  <ws:rendition selector='.TopBox6 '/>
  <ws:rendition selector='.UnderTopFill '/>
  <ws:rendition selector='.VAL '/>
  <ws:rendition selector='.VI '/>
  <ws:rendition selector='.WHITESPACE'/>
  <ws:rendition selector='.WHITESPACE '/>
  <ws:rendition selector='.WWP-ANCHOR-INFO '/>
  <ws:rendition selector='.WWP-BLOCK-EDITORIAL '/>
  <ws:rendition selector='.WWP-INLINE-EDITORIAL '/>
  <ws:rendition selector='.WWP-INLINE-TEXTINFO '/>
  <ws:rendition selector='.WWP-INLINE-TEXTINFO-HEAD '/>
  <ws:rendition selector='.WWP-MAIN-NAVCHOICE '/>
  <ws:rendition selector='.WWP-MILESTONES '/>
  <ws:rendition selector='.WWP-NOTE-INFO '/>
  <ws:rendition selector='.WWP-TEXTINFO '/>
  <ws:rendition selector='.ZING '/>
  <ws:rendition selector='.ZING2 '/>
  <ws:rendition selector='.aboutsublink '/>
  <ws:rendition selector='.accRef '/>
  <ws:rendition selector='.affix'/>
  <ws:rendition selector='.alert'/>
  <ws:rendition selector='.alert .alert-link'/>
  <ws:rendition selector='.alert h4'/>
  <ws:rendition selector='.alert-danger'/>
  <ws:rendition selector='.alert-danger .alert-link'/>
  <ws:rendition selector='.alert-danger hr'/>
  <ws:rendition selector='.alert-dismissable .close,.alert-dismissible .close'/>
  <ws:rendition selector='.alert-dismissable,.alert-dismissible'/>
  <ws:rendition selector='.alert-info'/>
  <ws:rendition selector='.alert-info .alert-link'/>
  <ws:rendition selector='.alert-info hr'/>
  <ws:rendition selector='.alert-success'/>
  <ws:rendition selector='.alert-success .alert-link'/>
  <ws:rendition selector='.alert-success hr'/>
  <ws:rendition selector='.alert-warning'/>
  <ws:rendition selector='.alert-warning .alert-link'/>
  <ws:rendition selector='.alert-warning hr'/>
  <ws:rendition selector='.alert>p+p'/>
  <ws:rendition selector='.alert>p,.alert>ul'/>
  <ws:rendition selector='.attrName '/>
  <ws:rendition selector='.attrVal '/>
  <ws:rendition selector='.badge'/>
  <ws:rendition selector='.badge '/>
  <ws:rendition selector='.badge:empty'/>
  <ws:rendition selector='.bg-danger'/>
  <ws:rendition selector='.bg-info'/>
  <ws:rendition selector='.bg-primary'/>
  <ws:rendition selector='.bg-success'/>
  <ws:rendition selector='.bg-warning'/>
  <ws:rendition selector='.blockimage '/>
  <ws:rendition selector='.blockquote-reverse .small:after,.blockquote-reverse footer:after,.blockquote-reverse small:after,blockquote.pull-right .small:after,blockquote.pull-right footer:after,blockquote.pull-right small:after'/>
  <ws:rendition selector='.blockquote-reverse .small:before,.blockquote-reverse footer:before,.blockquote-reverse small:before,blockquote.pull-right .small:before,blockquote.pull-right footer:before,blockquote.pull-right small:before'/>
  <ws:rendition selector='.blockquote-reverse,blockquote.pull-right'/>
  <ws:rendition selector='.bold '/>
  <ws:rendition selector='.booktitle '/>
  <ws:rendition selector='.breadcrumb'/>
  <ws:rendition selector='.breadcrumb>.active'/>
  <ws:rendition selector='.breadcrumb>li'/>
  <ws:rendition selector='.breadcrumb>li+li:before'/>
  <ws:rendition selector='.brownlogo '/>
  <ws:rendition selector='.brownlogo img '/>
  <ws:rendition selector='.brownlogosub '/>
  <ws:rendition selector='.brownlogosub img '/>
  <ws:rendition selector='.btn'/>
  <ws:rendition selector='.btn .badge'/>
  <ws:rendition selector='.btn .caret'/>
  <ws:rendition selector='.btn .label'/>
  <ws:rendition selector='.btn-block'/>
  <ws:rendition selector='.btn-block+.btn-block'/>
  <ws:rendition selector='.btn-danger'/>
  <ws:rendition selector='.btn-danger .badge'/>
  <ws:rendition selector='.btn-danger.active,.btn-danger:active,.open>.dropdown-toggle.btn-danger'/>
  <ws:rendition selector='.btn-danger.active.focus,.btn-danger.active:focus,.btn-danger.active:hover,.btn-danger:active.focus,.btn-danger:active:focus,.btn-danger:active:hover,.open>.dropdown-toggle.btn-danger.focus,.open>.dropdown-toggle.btn-danger:focus,.open>.dropdown-toggle.btn-danger:hover'/>
  <ws:rendition selector='.btn-danger.disabled.focus,.btn-danger.disabled:focus,.btn-danger.disabled:hover,.btn-danger[disabled].focus,.btn-danger[disabled]:focus,.btn-danger[disabled]:hover,fieldset[disabled] .btn-danger.focus,fieldset[disabled] .btn-danger:focus,fieldset[disabled] .btn-danger:hover'/>
  <ws:rendition selector='.btn-danger.focus,.btn-danger:focus'/>
  <ws:rendition selector='.btn-danger:hover'/>
  <ws:rendition selector='.btn-default'/>
  <ws:rendition selector='.btn-default .badge'/>
  <ws:rendition selector='.btn-default.active,.btn-default:active,.open>.dropdown-toggle.btn-default'/>
  <ws:rendition selector='.btn-default.active.focus,.btn-default.active:focus,.btn-default.active:hover,.btn-default:active.focus,.btn-default:active:focus,.btn-default:active:hover,.open>.dropdown-toggle.btn-default.focus,.open>.dropdown-toggle.btn-default:focus,.open>.dropdown-toggle.btn-default:hover'/>
  <ws:rendition selector='.btn-default.disabled.focus,.btn-default.disabled:focus,.btn-default.disabled:hover,.btn-default[disabled].focus,.btn-default[disabled]:focus,.btn-default[disabled]:hover,fieldset[disabled] .btn-default.focus,fieldset[disabled] .btn-default:focus,fieldset[disabled] .btn-default:hover'/>
  <ws:rendition selector='.btn-default.focus,.btn-default:focus'/>
  <ws:rendition selector='.btn-default:hover'/>
  <ws:rendition selector='.btn-group .btn+.btn,.btn-group .btn+.btn-group,.btn-group .btn-group+.btn,.btn-group .btn-group+.btn-group'/>
  <ws:rendition selector='.btn-group .dropdown-toggle:active,.btn-group.open .dropdown-toggle'/>
  <ws:rendition selector='.btn-group,.btn-group-vertical'/>
  <ws:rendition selector='.btn-group-justified'/>
  <ws:rendition selector='.btn-group-justified>.btn,.btn-group-justified>.btn-group'/>
  <ws:rendition selector='.btn-group-justified>.btn-group .btn'/>
  <ws:rendition selector='.btn-group-justified>.btn-group .dropdown-menu'/>
  <ws:rendition selector='.btn-group-lg>.btn,.btn-lg'/>
  <ws:rendition selector='.btn-group-sm>.btn,.btn-sm'/>
  <ws:rendition selector='.btn-group-vertical>.btn+.btn,.btn-group-vertical>.btn+.btn-group,.btn-group-vertical>.btn-group+.btn,.btn-group-vertical>.btn-group+.btn-group'/>
  <ws:rendition selector='.btn-group-vertical>.btn,.btn-group-vertical>.btn-group,.btn-group-vertical>.btn-group>.btn'/>
  <ws:rendition selector='.btn-group-vertical>.btn,.btn-group>.btn'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group:after,.btn-group-vertical>.btn-group:before,.btn-toolbar:after,.btn-toolbar:before,.clearfix:after,.clearfix:before,.container-fluid:after,.container-fluid:before,.container:after,.container:before,.dl-horizontal dd:after,.dl-horizontal dd:before,.form-horizontal .form-group:after,.form-horizontal .form-group:before,.modal-footer:after,.modal-footer:before,.modal-header:after,.modal-header:before,.nav:after,.nav:before,.navbar-collapse:after,.navbar-collapse:before,.navbar-header:after,.navbar-header:before,.navbar:after,.navbar:before,.pager:after,.pager:before,.panel-body:after,.panel-body:before,.row:after,.row:before'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group:after,.btn-toolbar:after,.clearfix:after,.container-fluid:after,.container:after,.dl-horizontal dd:after,.form-horizontal .form-group:after,.modal-footer:after,.modal-header:after,.nav:after,.navbar-collapse:after,.navbar-header:after,.navbar:after,.pager:after,.panel-body:after,.row:after'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group:first-child:not(:last-child)>.btn:last-child,.btn-group-vertical>.btn-group:first-child:not(:last-child)>.dropdown-toggle'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group:last-child:not(:first-child)>.btn:first-child'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group:not(:first-child):not(:last-child)>.btn'/>
  <ws:rendition selector='.btn-group-vertical>.btn-group>.btn'/>
  <ws:rendition selector='.btn-group-vertical>.btn.active,.btn-group-vertical>.btn:active,.btn-group-vertical>.btn:focus,.btn-group-vertical>.btn:hover,.btn-group>.btn.active,.btn-group>.btn:active,.btn-group>.btn:focus,.btn-group>.btn:hover'/>
  <ws:rendition selector='.btn-group-vertical>.btn:first-child:not(:last-child)'/>
  <ws:rendition selector='.btn-group-vertical>.btn:last-child:not(:first-child)'/>
  <ws:rendition selector='.btn-group-vertical>.btn:not(:first-child):not(:last-child)'/>
  <ws:rendition selector='.btn-group-xs>.btn .badge,.btn-xs .badge'/>
  <ws:rendition selector='.btn-group-xs>.btn,.btn-xs'/>
  <ws:rendition selector='.btn-group.open .dropdown-toggle'/>
  <ws:rendition selector='.btn-group.open .dropdown-toggle.btn-link'/>
  <ws:rendition selector='.btn-group>.btn+.dropdown-toggle'/>
  <ws:rendition selector='.btn-group>.btn-group'/>
  <ws:rendition selector='.btn-group>.btn-group:first-child:not(:last-child)>.btn:last-child,.btn-group>.btn-group:first-child:not(:last-child)>.dropdown-toggle'/>
  <ws:rendition selector='.btn-group>.btn-group:last-child:not(:first-child)>.btn:first-child'/>
  <ws:rendition selector='.btn-group>.btn-group:not(:first-child):not(:last-child)>.btn'/>
  <ws:rendition selector='.btn-group>.btn-lg+.dropdown-toggle'/>
  <ws:rendition selector='.btn-group>.btn:first-child'/>
  <ws:rendition selector='.btn-group>.btn:first-child:not(:last-child):not(.dropdown-toggle)'/>
  <ws:rendition selector='.btn-group>.btn:last-child:not(:first-child),.btn-group>.dropdown-toggle:not(:first-child)'/>
  <ws:rendition selector='.btn-group>.btn:not(:first-child):not(:last-child):not(.dropdown-toggle)'/>
  <ws:rendition selector='.btn-info'/>
  <ws:rendition selector='.btn-info .badge'/>
  <ws:rendition selector='.btn-info.active,.btn-info:active,.open>.dropdown-toggle.btn-info'/>
  <ws:rendition selector='.btn-info.active.focus,.btn-info.active:focus,.btn-info.active:hover,.btn-info:active.focus,.btn-info:active:focus,.btn-info:active:hover,.open>.dropdown-toggle.btn-info.focus,.open>.dropdown-toggle.btn-info:focus,.open>.dropdown-toggle.btn-info:hover'/>
  <ws:rendition selector='.btn-info.disabled.focus,.btn-info.disabled:focus,.btn-info.disabled:hover,.btn-info[disabled].focus,.btn-info[disabled]:focus,.btn-info[disabled]:hover,fieldset[disabled] .btn-info.focus,fieldset[disabled] .btn-info:focus,fieldset[disabled] .btn-info:hover'/>
  <ws:rendition selector='.btn-info.focus,.btn-info:focus'/>
  <ws:rendition selector='.btn-info:hover'/>
  <ws:rendition selector='.btn-lg .caret'/>
  <ws:rendition selector='.btn-link'/>
  <ws:rendition selector='.btn-link,.btn-link.active,.btn-link:active,.btn-link[disabled],fieldset[disabled] .btn-link'/>
  <ws:rendition selector='.btn-link,.btn-link:active,.btn-link:focus,.btn-link:hover'/>
  <ws:rendition selector='.btn-link:focus,.btn-link:hover'/>
  <ws:rendition selector='.btn-link[disabled]:focus,.btn-link[disabled]:hover,fieldset[disabled] .btn-link:focus,fieldset[disabled] .btn-link:hover'/>
  <ws:rendition selector='.btn-primary'/>
  <ws:rendition selector='.btn-primary .badge'/>
  <ws:rendition selector='.btn-primary.active,.btn-primary:active,.open>.dropdown-toggle.btn-primary'/>
  <ws:rendition selector='.btn-primary.active.focus,.btn-primary.active:focus,.btn-primary.active:hover,.btn-primary:active.focus,.btn-primary:active:focus,.btn-primary:active:hover,.open>.dropdown-toggle.btn-primary.focus,.open>.dropdown-toggle.btn-primary:focus,.open>.dropdown-toggle.btn-primary:hover'/>
  <ws:rendition selector='.btn-primary.disabled.focus,.btn-primary.disabled:focus,.btn-primary.disabled:hover,.btn-primary[disabled].focus,.btn-primary[disabled]:focus,.btn-primary[disabled]:hover,fieldset[disabled] .btn-primary.focus,fieldset[disabled] .btn-primary:focus,fieldset[disabled] .btn-primary:hover'/>
  <ws:rendition selector='.btn-primary.focus,.btn-primary:focus'/>
  <ws:rendition selector='.btn-primary:hover'/>
  <ws:rendition selector='.btn-success'/>
  <ws:rendition selector='.btn-success .badge'/>
  <ws:rendition selector='.btn-success.active,.btn-success:active,.open>.dropdown-toggle.btn-success'/>
  <ws:rendition selector='.btn-success.active.focus,.btn-success.active:focus,.btn-success.active:hover,.btn-success:active.focus,.btn-success:active:focus,.btn-success:active:hover,.open>.dropdown-toggle.btn-success.focus,.open>.dropdown-toggle.btn-success:focus,.open>.dropdown-toggle.btn-success:hover'/>
  <ws:rendition selector='.btn-success.disabled.focus,.btn-success.disabled:focus,.btn-success.disabled:hover,.btn-success[disabled].focus,.btn-success[disabled]:focus,.btn-success[disabled]:hover,fieldset[disabled] .btn-success.focus,fieldset[disabled] .btn-success:focus,fieldset[disabled] .btn-success:hover'/>
  <ws:rendition selector='.btn-success.focus,.btn-success:focus'/>
  <ws:rendition selector='.btn-success:hover'/>
  <ws:rendition selector='.btn-toolbar'/>
  <ws:rendition selector='.btn-toolbar .btn,.btn-toolbar .btn-group,.btn-toolbar .input-group'/>
  <ws:rendition selector='.btn-toolbar>.btn,.btn-toolbar>.btn-group,.btn-toolbar>.input-group'/>
  <ws:rendition selector='.btn-warning'/>
  <ws:rendition selector='.btn-warning '/>
  <ws:rendition selector='.btn-warning .badge'/>
  <ws:rendition selector='.btn-warning.active,.btn-warning:active,.open>.dropdown-toggle.btn-warning'/>
  <ws:rendition selector='.btn-warning.active.focus,.btn-warning.active:focus,.btn-warning.active:hover,.btn-warning:active.focus,.btn-warning:active:focus,.btn-warning:active:hover,.open>.dropdown-toggle.btn-warning.focus,.open>.dropdown-toggle.btn-warning:focus,.open>.dropdown-toggle.btn-warning:hover'/>
  <ws:rendition selector='.btn-warning.disabled.focus,.btn-warning.disabled:focus,.btn-warning.disabled:hover,.btn-warning[disabled].focus,.btn-warning[disabled]:focus,.btn-warning[disabled]:hover,fieldset[disabled] .btn-warning.focus,fieldset[disabled] .btn-warning:focus,fieldset[disabled] .btn-warning:hover'/>
  <ws:rendition selector='.btn-warning.focus,.btn-warning:focus'/>
  <ws:rendition selector='.btn-warning:hover'/>
  <ws:rendition selector='.btn.active,.btn:active'/>
  <ws:rendition selector='.btn.active.focus,.btn.active:focus,.btn.focus,.btn:active.focus,.btn:active:focus,.btn:focus'/>
  <ws:rendition selector='.btn.disabled,.btn[disabled],fieldset[disabled] .btn'/>
  <ws:rendition selector='.btn.focus,.btn:focus,.btn:hover'/>
  <ws:rendition selector='.btn>.caret,.dropup>.btn>.caret'/>
  <ws:rendition selector='.caret'/>
  <ws:rendition selector='.carousel'/>
  <ws:rendition selector='.carousel .carousel-control '/>
  <ws:rendition selector='.carousel .carousel-control .glyphicon '/>
  <ws:rendition selector='.carousel .carousel-control.left '/>
  <ws:rendition selector='.carousel .carousel-control.right '/>
  <ws:rendition selector='.carousel .carousel-inner .item img '/>
  <ws:rendition selector='.carousel-caption'/>
  <ws:rendition selector='.carousel-caption .btn'/>
  <ws:rendition selector='.carousel-control'/>
  <ws:rendition selector='.carousel-control .glyphicon-chevron-left,.carousel-control .glyphicon-chevron-right,.carousel-control .icon-next,.carousel-control .icon-prev'/>
  <ws:rendition selector='.carousel-control .glyphicon-chevron-left,.carousel-control .icon-prev'/>
  <ws:rendition selector='.carousel-control .glyphicon-chevron-right,.carousel-control .icon-next'/>
  <ws:rendition selector='.carousel-control .icon-next,.carousel-control .icon-prev'/>
  <ws:rendition selector='.carousel-control .icon-next:before'/>
  <ws:rendition selector='.carousel-control .icon-prev:before'/>
  <ws:rendition selector='.carousel-control.left'/>
  <ws:rendition selector='.carousel-control.right'/>
  <ws:rendition selector='.carousel-control:focus,.carousel-control:hover'/>
  <ws:rendition selector='.carousel-indicators'/>
  <ws:rendition selector='.carousel-indicators .active'/>
  <ws:rendition selector='.carousel-indicators li'/>
  <ws:rendition selector='.carousel-inner'/>
  <ws:rendition selector='.carousel-inner>.active'/>
  <ws:rendition selector='.carousel-inner>.active,.carousel-inner>.next,.carousel-inner>.prev'/>
  <ws:rendition selector='.carousel-inner>.active.left'/>
  <ws:rendition selector='.carousel-inner>.active.right'/>
  <ws:rendition selector='.carousel-inner>.item'/>
  <ws:rendition selector='.carousel-inner>.item.active,.carousel-inner>.item.next.left,.carousel-inner>.item.prev.right'/>
  <ws:rendition selector='.carousel-inner>.item.active.left,.carousel-inner>.item.prev'/>
  <ws:rendition selector='.carousel-inner>.item.active.right,.carousel-inner>.item.next'/>
  <ws:rendition selector='.carousel-inner>.item>a>img,.carousel-inner>.item>img'/>
  <ws:rendition selector='.carousel-inner>.item>a>img,.carousel-inner>.item>img,.img-responsive,.thumbnail a>img,.thumbnail>img'/>
  <ws:rendition selector='.carousel-inner>.next'/>
  <ws:rendition selector='.carousel-inner>.next,.carousel-inner>.prev'/>
  <ws:rendition selector='.carousel-inner>.next.left,.carousel-inner>.prev.right'/>
  <ws:rendition selector='.carousel-inner>.prev'/>
  <ws:rendition selector='.center-block'/>
  <ws:rendition selector='.centered '/>
  <ws:rendition selector='.checkbox input[type=checkbox],.checkbox-inline input[type=checkbox],.radio input[type=radio],.radio-inline input[type=radio]'/>
  <ws:rendition selector='.checkbox label,.radio label'/>
  <ws:rendition selector='.checkbox+.checkbox,.radio+.radio'/>
  <ws:rendition selector='.checkbox,.radio'/>
  <ws:rendition selector='.checkbox-inline+.checkbox-inline,.radio-inline+.radio-inline'/>
  <ws:rendition selector='.checkbox-inline,.radio-inline'/>
  <ws:rendition selector='.checkbox-inline.disabled,.radio-inline.disabled,fieldset[disabled] .checkbox-inline,fieldset[disabled] .radio-inline'/>
  <ws:rendition selector='.checkbox.disabled label,.radio.disabled label,fieldset[disabled] .checkbox label,fieldset[disabled] .radio label'/>
  <ws:rendition selector='.close'/>
  <ws:rendition selector='.close:focus,.close:hover'/>
  <ws:rendition selector='.col-lg-1'/>
  <ws:rendition selector='.col-lg-1,.col-lg-10,.col-lg-11,.col-lg-12,.col-lg-2,.col-lg-3,.col-lg-4,.col-lg-5,.col-lg-6,.col-lg-7,.col-lg-8,.col-lg-9,.col-md-1,.col-md-10,.col-md-11,.col-md-12,.col-md-2,.col-md-3,.col-md-4,.col-md-5,.col-md-6,.col-md-7,.col-md-8,.col-md-9,.col-sm-1,.col-sm-10,.col-sm-11,.col-sm-12,.col-sm-2,.col-sm-3,.col-sm-4,.col-sm-5,.col-sm-6,.col-sm-7,.col-sm-8,.col-sm-9,.col-xs-1,.col-xs-10,.col-xs-11,.col-xs-12,.col-xs-2,.col-xs-3,.col-xs-4,.col-xs-5,.col-xs-6,.col-xs-7,.col-xs-8,.col-xs-9'/>
  <ws:rendition selector='.col-lg-10'/>
  <ws:rendition selector='.col-lg-11'/>
  <ws:rendition selector='.col-lg-12'/>
  <ws:rendition selector='.col-lg-2'/>
  <ws:rendition selector='.col-lg-3'/>
  <ws:rendition selector='.col-lg-4'/>
  <ws:rendition selector='.col-lg-5'/>
  <ws:rendition selector='.col-lg-6'/>
  <ws:rendition selector='.col-lg-7'/>
  <ws:rendition selector='.col-lg-8'/>
  <ws:rendition selector='.col-lg-9'/>
  <ws:rendition selector='.col-lg-offset-0'/>
  <ws:rendition selector='.col-lg-offset-1'/>
  <ws:rendition selector='.col-lg-offset-10'/>
  <ws:rendition selector='.col-lg-offset-11'/>
  <ws:rendition selector='.col-lg-offset-12'/>
  <ws:rendition selector='.col-lg-offset-2'/>
  <ws:rendition selector='.col-lg-offset-3'/>
  <ws:rendition selector='.col-lg-offset-4'/>
  <ws:rendition selector='.col-lg-offset-5'/>
  <ws:rendition selector='.col-lg-offset-6'/>
  <ws:rendition selector='.col-lg-offset-7'/>
  <ws:rendition selector='.col-lg-offset-8'/>
  <ws:rendition selector='.col-lg-offset-9'/>
  <ws:rendition selector='.col-lg-pull-0'/>
  <ws:rendition selector='.col-lg-pull-1'/>
  <ws:rendition selector='.col-lg-pull-10'/>
  <ws:rendition selector='.col-lg-pull-11'/>
  <ws:rendition selector='.col-lg-pull-12'/>
  <ws:rendition selector='.col-lg-pull-2'/>
  <ws:rendition selector='.col-lg-pull-3'/>
  <ws:rendition selector='.col-lg-pull-4'/>
  <ws:rendition selector='.col-lg-pull-5'/>
  <ws:rendition selector='.col-lg-pull-6'/>
  <ws:rendition selector='.col-lg-pull-7'/>
  <ws:rendition selector='.col-lg-pull-8'/>
  <ws:rendition selector='.col-lg-pull-9'/>
  <ws:rendition selector='.col-lg-push-0'/>
  <ws:rendition selector='.col-lg-push-1'/>
  <ws:rendition selector='.col-lg-push-10'/>
  <ws:rendition selector='.col-lg-push-11'/>
  <ws:rendition selector='.col-lg-push-12'/>
  <ws:rendition selector='.col-lg-push-2'/>
  <ws:rendition selector='.col-lg-push-3'/>
  <ws:rendition selector='.col-lg-push-4'/>
  <ws:rendition selector='.col-lg-push-5'/>
  <ws:rendition selector='.col-lg-push-6'/>
  <ws:rendition selector='.col-lg-push-7'/>
  <ws:rendition selector='.col-lg-push-8'/>
  <ws:rendition selector='.col-lg-push-9'/>
  <ws:rendition selector='.col-md-1'/>
  <ws:rendition selector='.col-md-10'/>
  <ws:rendition selector='.col-md-11'/>
  <ws:rendition selector='.col-md-12'/>
  <ws:rendition selector='.col-md-2'/>
  <ws:rendition selector='.col-md-3'/>
  <ws:rendition selector='.col-md-4'/>
  <ws:rendition selector='.col-md-5'/>
  <ws:rendition selector='.col-md-6'/>
  <ws:rendition selector='.col-md-7'/>
  <ws:rendition selector='.col-md-8'/>
  <ws:rendition selector='.col-md-9'/>
  <ws:rendition selector='.col-md-offset-0'/>
  <ws:rendition selector='.col-md-offset-1'/>
  <ws:rendition selector='.col-md-offset-10'/>
  <ws:rendition selector='.col-md-offset-11'/>
  <ws:rendition selector='.col-md-offset-12'/>
  <ws:rendition selector='.col-md-offset-2'/>
  <ws:rendition selector='.col-md-offset-3'/>
  <ws:rendition selector='.col-md-offset-4'/>
  <ws:rendition selector='.col-md-offset-5'/>
  <ws:rendition selector='.col-md-offset-6'/>
  <ws:rendition selector='.col-md-offset-7'/>
  <ws:rendition selector='.col-md-offset-8'/>
  <ws:rendition selector='.col-md-offset-9'/>
  <ws:rendition selector='.col-md-pull-0'/>
  <ws:rendition selector='.col-md-pull-1'/>
  <ws:rendition selector='.col-md-pull-10'/>
  <ws:rendition selector='.col-md-pull-11'/>
  <ws:rendition selector='.col-md-pull-12'/>
  <ws:rendition selector='.col-md-pull-2'/>
  <ws:rendition selector='.col-md-pull-3'/>
  <ws:rendition selector='.col-md-pull-4'/>
  <ws:rendition selector='.col-md-pull-5'/>
  <ws:rendition selector='.col-md-pull-6'/>
  <ws:rendition selector='.col-md-pull-7'/>
  <ws:rendition selector='.col-md-pull-8'/>
  <ws:rendition selector='.col-md-pull-9'/>
  <ws:rendition selector='.col-md-push-0'/>
  <ws:rendition selector='.col-md-push-1'/>
  <ws:rendition selector='.col-md-push-10'/>
  <ws:rendition selector='.col-md-push-11'/>
  <ws:rendition selector='.col-md-push-12'/>
  <ws:rendition selector='.col-md-push-2'/>
  <ws:rendition selector='.col-md-push-3'/>
  <ws:rendition selector='.col-md-push-4'/>
  <ws:rendition selector='.col-md-push-5'/>
  <ws:rendition selector='.col-md-push-6'/>
  <ws:rendition selector='.col-md-push-7'/>
  <ws:rendition selector='.col-md-push-8'/>
  <ws:rendition selector='.col-md-push-9'/>
  <ws:rendition selector='.col-sm-1'/>
  <ws:rendition selector='.col-sm-10'/>
  <ws:rendition selector='.col-sm-11'/>
  <ws:rendition selector='.col-sm-12'/>
  <ws:rendition selector='.col-sm-2'/>
  <ws:rendition selector='.col-sm-3'/>
  <ws:rendition selector='.col-sm-4'/>
  <ws:rendition selector='.col-sm-5'/>
  <ws:rendition selector='.col-sm-6'/>
  <ws:rendition selector='.col-sm-7'/>
  <ws:rendition selector='.col-sm-8'/>
  <ws:rendition selector='.col-sm-9'/>
  <ws:rendition selector='.col-sm-offset-0'/>
  <ws:rendition selector='.col-sm-offset-1'/>
  <ws:rendition selector='.col-sm-offset-10'/>
  <ws:rendition selector='.col-sm-offset-11'/>
  <ws:rendition selector='.col-sm-offset-12'/>
  <ws:rendition selector='.col-sm-offset-2'/>
  <ws:rendition selector='.col-sm-offset-3'/>
  <ws:rendition selector='.col-sm-offset-4'/>
  <ws:rendition selector='.col-sm-offset-5'/>
  <ws:rendition selector='.col-sm-offset-6'/>
  <ws:rendition selector='.col-sm-offset-7'/>
  <ws:rendition selector='.col-sm-offset-8'/>
  <ws:rendition selector='.col-sm-offset-9'/>
  <ws:rendition selector='.col-sm-pull-0'/>
  <ws:rendition selector='.col-sm-pull-1'/>
  <ws:rendition selector='.col-sm-pull-10'/>
  <ws:rendition selector='.col-sm-pull-11'/>
  <ws:rendition selector='.col-sm-pull-12'/>
  <ws:rendition selector='.col-sm-pull-2'/>
  <ws:rendition selector='.col-sm-pull-3'/>
  <ws:rendition selector='.col-sm-pull-4'/>
  <ws:rendition selector='.col-sm-pull-5'/>
  <ws:rendition selector='.col-sm-pull-6'/>
  <ws:rendition selector='.col-sm-pull-7'/>
  <ws:rendition selector='.col-sm-pull-8'/>
  <ws:rendition selector='.col-sm-pull-9'/>
  <ws:rendition selector='.col-sm-push-0'/>
  <ws:rendition selector='.col-sm-push-1'/>
  <ws:rendition selector='.col-sm-push-10'/>
  <ws:rendition selector='.col-sm-push-11'/>
  <ws:rendition selector='.col-sm-push-12'/>
  <ws:rendition selector='.col-sm-push-2'/>
  <ws:rendition selector='.col-sm-push-3'/>
  <ws:rendition selector='.col-sm-push-4'/>
  <ws:rendition selector='.col-sm-push-5'/>
  <ws:rendition selector='.col-sm-push-6'/>
  <ws:rendition selector='.col-sm-push-7'/>
  <ws:rendition selector='.col-sm-push-8'/>
  <ws:rendition selector='.col-sm-push-9'/>
  <ws:rendition selector='.col-xs-1'/>
  <ws:rendition selector='.col-xs-1,.col-xs-10,.col-xs-11,.col-xs-12,.col-xs-2,.col-xs-3,.col-xs-4,.col-xs-5,.col-xs-6,.col-xs-7,.col-xs-8,.col-xs-9'/>
  <ws:rendition selector='.col-xs-10'/>
  <ws:rendition selector='.col-xs-11'/>
  <ws:rendition selector='.col-xs-12'/>
  <ws:rendition selector='.col-xs-2'/>
  <ws:rendition selector='.col-xs-3'/>
  <ws:rendition selector='.col-xs-4'/>
  <ws:rendition selector='.col-xs-5'/>
  <ws:rendition selector='.col-xs-6'/>
  <ws:rendition selector='.col-xs-7'/>
  <ws:rendition selector='.col-xs-8'/>
  <ws:rendition selector='.col-xs-9'/>
  <ws:rendition selector='.col-xs-offset-0'/>
  <ws:rendition selector='.col-xs-offset-1'/>
  <ws:rendition selector='.col-xs-offset-10'/>
  <ws:rendition selector='.col-xs-offset-11'/>
  <ws:rendition selector='.col-xs-offset-12'/>
  <ws:rendition selector='.col-xs-offset-2'/>
  <ws:rendition selector='.col-xs-offset-3'/>
  <ws:rendition selector='.col-xs-offset-4'/>
  <ws:rendition selector='.col-xs-offset-5'/>
  <ws:rendition selector='.col-xs-offset-6'/>
  <ws:rendition selector='.col-xs-offset-7'/>
  <ws:rendition selector='.col-xs-offset-8'/>
  <ws:rendition selector='.col-xs-offset-9'/>
  <ws:rendition selector='.col-xs-pull-0'/>
  <ws:rendition selector='.col-xs-pull-1'/>
  <ws:rendition selector='.col-xs-pull-10'/>
  <ws:rendition selector='.col-xs-pull-11'/>
  <ws:rendition selector='.col-xs-pull-12'/>
  <ws:rendition selector='.col-xs-pull-2'/>
  <ws:rendition selector='.col-xs-pull-3'/>
  <ws:rendition selector='.col-xs-pull-4'/>
  <ws:rendition selector='.col-xs-pull-5'/>
  <ws:rendition selector='.col-xs-pull-6'/>
  <ws:rendition selector='.col-xs-pull-7'/>
  <ws:rendition selector='.col-xs-pull-8'/>
  <ws:rendition selector='.col-xs-pull-9'/>
  <ws:rendition selector='.col-xs-push-0'/>
  <ws:rendition selector='.col-xs-push-1'/>
  <ws:rendition selector='.col-xs-push-10'/>
  <ws:rendition selector='.col-xs-push-11'/>
  <ws:rendition selector='.col-xs-push-12'/>
  <ws:rendition selector='.col-xs-push-2'/>
  <ws:rendition selector='.col-xs-push-3'/>
  <ws:rendition selector='.col-xs-push-4'/>
  <ws:rendition selector='.col-xs-push-5'/>
  <ws:rendition selector='.col-xs-push-6'/>
  <ws:rendition selector='.col-xs-push-7'/>
  <ws:rendition selector='.col-xs-push-8'/>
  <ws:rendition selector='.col-xs-push-9'/>
  <ws:rendition selector='.collapse'/>
  <ws:rendition selector='.collapse.in'/>
  <ws:rendition selector='.collapsing'/>
  <ws:rendition selector='.comment '/>
  <ws:rendition selector='.container'/>
  <ws:rendition selector='.container .jumbotron,.container-fluid .jumbotron'/>
  <ws:rendition selector='.container-fluid'/>
  <ws:rendition selector='.container-fluid>.navbar-collapse,.container-fluid>.navbar-header,.container>.navbar-collapse,.container>.navbar-header'/>
  <ws:rendition selector='.container-nopad '/>
  <ws:rendition selector='.current '/>
  <ws:rendition selector='.darkgreen '/>
  <ws:rendition selector='.dl-horizontal dd'/>
  <ws:rendition selector='.dropdown,.dropup'/>
  <ws:rendition selector='.dropdown-backdrop'/>
  <ws:rendition selector='.dropdown-header'/>
  <ws:rendition selector='.dropdown-menu'/>
  <ws:rendition selector='.dropdown-menu .divider'/>
  <ws:rendition selector='.dropdown-menu-left'/>
  <ws:rendition selector='.dropdown-menu-right'/>
  <ws:rendition selector='.dropdown-menu.pull-right'/>
  <ws:rendition selector='.dropdown-menu>.active>a,.dropdown-menu>.active>a:focus,.dropdown-menu>.active>a:hover'/>
  <ws:rendition selector='.dropdown-menu>.disabled>a,.dropdown-menu>.disabled>a:focus,.dropdown-menu>.disabled>a:hover'/>
  <ws:rendition selector='.dropdown-menu>.disabled>a:focus,.dropdown-menu>.disabled>a:hover'/>
  <ws:rendition selector='.dropdown-menu>li>a'/>
  <ws:rendition selector='.dropdown-menu>li>a:focus,.dropdown-menu>li>a:hover'/>
  <ws:rendition selector='.dropdown-toggle:focus'/>
  <ws:rendition selector='.dropup .btn-lg .caret'/>
  <ws:rendition selector='.dropup .caret,.navbar-fixed-bottom .dropdown .caret'/>
  <ws:rendition selector='.dropup .dropdown-menu,.navbar-fixed-bottom .dropdown .dropdown-menu'/>
  <ws:rendition selector='.embed-responsive'/>
  <ws:rendition selector='.embed-responsive .embed-responsive-item,.embed-responsive embed,.embed-responsive iframe,.embed-responsive object,.embed-responsive video'/>
  <ws:rendition selector='.embed-responsive-16by9'/>
  <ws:rendition selector='.embed-responsive-4by3'/>
  <ws:rendition selector='.entry:hover '/>
  <ws:rendition selector='.entry:link '/>
  <ws:rendition selector='.entry:visited '/>
  <ws:rendition selector='.example '/>
  <ws:rendition selector='.fade'/>
  <ws:rendition selector='.fade.in'/>
  <ws:rendition selector='.fancy-bg '/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-e	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-n	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-ne	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-nw	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-s	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-se	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-sw	'/>
  <ws:rendition selector='.fancybox-ie #fancy-bg-w	'/>
  <ws:rendition selector='.fancybox-ie #fancybox-close		'/>
  <ws:rendition selector='.fancybox-ie #fancybox-left-ico		'/>
  <ws:rendition selector='.fancybox-ie #fancybox-right-ico	'/>
  <ws:rendition selector='.fancybox-ie #fancybox-title-left	'/>
  <ws:rendition selector='.fancybox-ie #fancybox-title-main	'/>
  <ws:rendition selector='.fancybox-ie #fancybox-title-over	'/>
  <ws:rendition selector='.fancybox-ie #fancybox-title-right	'/>
  <ws:rendition selector='.fancybox-ie .fancy-bg '/>
  <ws:rendition selector='.fancybox-title-inside '/>
  <ws:rendition selector='.fancybox-title-outside '/>
  <ws:rendition selector='.fancybox-title-over '/>
  <ws:rendition selector='.figGrp '/>
  <ws:rendition selector='.figGrp .figure '/>
  <ws:rendition selector='.figGrp .figure:nth-child(2n) '/>
  <ws:rendition selector='.figcaption '/>
  <ws:rendition selector='.figcaption .credit '/>
  <ws:rendition selector='.figcaption .credit .icon '/>
  <ws:rendition selector='.figure '/>
  <ws:rendition selector='.figure.inset-left '/>
  <ws:rendition selector='.figure.inset-right '/>
  <ws:rendition selector='.form-control'/>
  <ws:rendition selector='.form-control-feedback'/>
  <ws:rendition selector='.form-control-static'/>
  <ws:rendition selector='.form-control-static.input-lg,.form-control-static.input-sm'/>
  <ws:rendition selector='.form-control:-ms-input-placeholder'/>
  <ws:rendition selector='.form-control::-moz-placeholder'/>
  <ws:rendition selector='.form-control::-ms-expand'/>
  <ws:rendition selector='.form-control::-webkit-input-placeholder'/>
  <ws:rendition selector='.form-control:focus'/>
  <ws:rendition selector='.form-control[disabled],.form-control[readonly],fieldset[disabled] .form-control'/>
  <ws:rendition selector='.form-control[disabled],fieldset[disabled] .form-control'/>
  <ws:rendition selector='.form-group'/>
  <ws:rendition selector='.form-group-lg .form-control'/>
  <ws:rendition selector='.form-group-lg .form-control+.form-control-feedback,.input-group-lg+.form-control-feedback,.input-lg+.form-control-feedback'/>
  <ws:rendition selector='.form-group-lg .form-control-static'/>
  <ws:rendition selector='.form-group-lg select.form-control'/>
  <ws:rendition selector='.form-group-lg select[multiple].form-control,.form-group-lg textarea.form-control'/>
  <ws:rendition selector='.form-group-sm .form-control'/>
  <ws:rendition selector='.form-group-sm .form-control+.form-control-feedback,.input-group-sm+.form-control-feedback,.input-sm+.form-control-feedback'/>
  <ws:rendition selector='.form-group-sm .form-control-static'/>
  <ws:rendition selector='.form-group-sm select.form-control'/>
  <ws:rendition selector='.form-group-sm select[multiple].form-control,.form-group-sm textarea.form-control'/>
  <ws:rendition selector='.form-horizontal .checkbox,.form-horizontal .checkbox-inline,.form-horizontal .radio,.form-horizontal .radio-inline'/>
  <ws:rendition selector='.form-horizontal .checkbox,.form-horizontal .radio'/>
  <ws:rendition selector='.form-horizontal .form-group'/>
  <ws:rendition selector='.form-horizontal .has-feedback .form-control-feedback'/>
  <ws:rendition selector='.form-inline '/>
  <ws:rendition selector='.form-inline .checkbox input[type=checkbox],.form-inline .radio input[type=radio]'/>
  <ws:rendition selector='.form-inline .checkbox label,.form-inline .radio label'/>
  <ws:rendition selector='.form-inline .checkbox,.form-inline .radio'/>
  <ws:rendition selector='.form-inline .control-label'/>
  <ws:rendition selector='.form-inline .form-control'/>
  <ws:rendition selector='.form-inline .form-control-static'/>
  <ws:rendition selector='.form-inline .has-feedback .form-control-feedback'/>
  <ws:rendition selector='.form-inline .input-group'/>
  <ws:rendition selector='.form-inline .input-group .form-control,.form-inline .input-group .input-group-addon,.form-inline .input-group .input-group-btn'/>
  <ws:rendition selector='.form-inline .input-group>.form-control'/>
  <ws:rendition selector='.freqtable '/>
  <ws:rendition selector='.fun:hover '/>
  <ws:rendition selector='.fun:link '/>
  <ws:rendition selector='.fun:visited '/>
  <ws:rendition selector='.funTD:hover '/>
  <ws:rendition selector='.funTD:link '/>
  <ws:rendition selector='.funTD:visited '/>
  <ws:rendition selector='.glyphicon'/>
  <ws:rendition selector='.glyphicon-adjust:before'/>
  <ws:rendition selector='.glyphicon-alert:before'/>
  <ws:rendition selector='.glyphicon-align-center:before'/>
  <ws:rendition selector='.glyphicon-align-justify:before'/>
  <ws:rendition selector='.glyphicon-align-left:before'/>
  <ws:rendition selector='.glyphicon-align-right:before'/>
  <ws:rendition selector='.glyphicon-apple:before'/>
  <ws:rendition selector='.glyphicon-arrow-down:before'/>
  <ws:rendition selector='.glyphicon-arrow-left:before'/>
  <ws:rendition selector='.glyphicon-arrow-right:before'/>
  <ws:rendition selector='.glyphicon-arrow-up:before'/>
  <ws:rendition selector='.glyphicon-asterisk:before'/>
  <ws:rendition selector='.glyphicon-baby-formula:before'/>
  <ws:rendition selector='.glyphicon-backward:before'/>
  <ws:rendition selector='.glyphicon-ban-circle:before'/>
  <ws:rendition selector='.glyphicon-barcode:before'/>
  <ws:rendition selector='.glyphicon-bed:before'/>
  <ws:rendition selector='.glyphicon-bell:before'/>
  <ws:rendition selector='.glyphicon-bishop:before'/>
  <ws:rendition selector='.glyphicon-bitcoin:before'/>
  <ws:rendition selector='.glyphicon-blackboard:before'/>
  <ws:rendition selector='.glyphicon-bold:before'/>
  <ws:rendition selector='.glyphicon-book:before'/>
  <ws:rendition selector='.glyphicon-bookmark:before'/>
  <ws:rendition selector='.glyphicon-briefcase:before'/>
  <ws:rendition selector='.glyphicon-btc:before'/>
  <ws:rendition selector='.glyphicon-bullhorn:before'/>
  <ws:rendition selector='.glyphicon-calendar:before'/>
  <ws:rendition selector='.glyphicon-camera:before'/>
  <ws:rendition selector='.glyphicon-cd:before'/>
  <ws:rendition selector='.glyphicon-certificate:before'/>
  <ws:rendition selector='.glyphicon-check:before'/>
  <ws:rendition selector='.glyphicon-chevron-down:before'/>
  <ws:rendition selector='.glyphicon-chevron-left:before'/>
  <ws:rendition selector='.glyphicon-chevron-right:before'/>
  <ws:rendition selector='.glyphicon-chevron-up:before'/>
  <ws:rendition selector='.glyphicon-circle-arrow-down:before'/>
  <ws:rendition selector='.glyphicon-circle-arrow-left:before'/>
  <ws:rendition selector='.glyphicon-circle-arrow-right:before'/>
  <ws:rendition selector='.glyphicon-circle-arrow-up:before'/>
  <ws:rendition selector='.glyphicon-cloud-download:before'/>
  <ws:rendition selector='.glyphicon-cloud-upload:before'/>
  <ws:rendition selector='.glyphicon-cloud:before'/>
  <ws:rendition selector='.glyphicon-cog:before'/>
  <ws:rendition selector='.glyphicon-collapse-down:before'/>
  <ws:rendition selector='.glyphicon-collapse-up:before'/>
  <ws:rendition selector='.glyphicon-comment:before'/>
  <ws:rendition selector='.glyphicon-compressed:before'/>
  <ws:rendition selector='.glyphicon-console:before'/>
  <ws:rendition selector='.glyphicon-copy:before'/>
  <ws:rendition selector='.glyphicon-copyright-mark:before'/>
  <ws:rendition selector='.glyphicon-credit-card:before'/>
  <ws:rendition selector='.glyphicon-cutlery:before'/>
  <ws:rendition selector='.glyphicon-dashboard:before'/>
  <ws:rendition selector='.glyphicon-download-alt:before'/>
  <ws:rendition selector='.glyphicon-download:before'/>
  <ws:rendition selector='.glyphicon-duplicate:before'/>
  <ws:rendition selector='.glyphicon-earphone:before'/>
  <ws:rendition selector='.glyphicon-edit:before'/>
  <ws:rendition selector='.glyphicon-education:before'/>
  <ws:rendition selector='.glyphicon-eject:before'/>
  <ws:rendition selector='.glyphicon-envelope:before'/>
  <ws:rendition selector='.glyphicon-equalizer:before'/>
  <ws:rendition selector='.glyphicon-erase:before'/>
  <ws:rendition selector='.glyphicon-eur:before,.glyphicon-euro:before'/>
  <ws:rendition selector='.glyphicon-exclamation-sign:before'/>
  <ws:rendition selector='.glyphicon-expand:before'/>
  <ws:rendition selector='.glyphicon-export:before'/>
  <ws:rendition selector='.glyphicon-eye-close:before'/>
  <ws:rendition selector='.glyphicon-eye-open:before'/>
  <ws:rendition selector='.glyphicon-facetime-video:before'/>
  <ws:rendition selector='.glyphicon-fast-backward:before'/>
  <ws:rendition selector='.glyphicon-fast-forward:before'/>
  <ws:rendition selector='.glyphicon-file:before'/>
  <ws:rendition selector='.glyphicon-film:before'/>
  <ws:rendition selector='.glyphicon-filter:before'/>
  <ws:rendition selector='.glyphicon-fire:before'/>
  <ws:rendition selector='.glyphicon-flag:before'/>
  <ws:rendition selector='.glyphicon-flash:before'/>
  <ws:rendition selector='.glyphicon-floppy-disk:before'/>
  <ws:rendition selector='.glyphicon-floppy-open:before'/>
  <ws:rendition selector='.glyphicon-floppy-remove:before'/>
  <ws:rendition selector='.glyphicon-floppy-save:before'/>
  <ws:rendition selector='.glyphicon-floppy-saved:before'/>
  <ws:rendition selector='.glyphicon-folder-close:before'/>
  <ws:rendition selector='.glyphicon-folder-open:before'/>
  <ws:rendition selector='.glyphicon-font:before'/>
  <ws:rendition selector='.glyphicon-forward:before'/>
  <ws:rendition selector='.glyphicon-fullscreen:before'/>
  <ws:rendition selector='.glyphicon-gbp:before'/>
  <ws:rendition selector='.glyphicon-gift:before'/>
  <ws:rendition selector='.glyphicon-glass:before'/>
  <ws:rendition selector='.glyphicon-globe:before'/>
  <ws:rendition selector='.glyphicon-grain:before'/>
  <ws:rendition selector='.glyphicon-hand-down:before'/>
  <ws:rendition selector='.glyphicon-hand-left:before'/>
  <ws:rendition selector='.glyphicon-hand-right:before'/>
  <ws:rendition selector='.glyphicon-hand-up:before'/>
  <ws:rendition selector='.glyphicon-hd-video:before'/>
  <ws:rendition selector='.glyphicon-hdd:before'/>
  <ws:rendition selector='.glyphicon-header:before'/>
  <ws:rendition selector='.glyphicon-headphones:before'/>
  <ws:rendition selector='.glyphicon-heart-empty:before'/>
  <ws:rendition selector='.glyphicon-heart:before'/>
  <ws:rendition selector='.glyphicon-home:before'/>
  <ws:rendition selector='.glyphicon-hourglass:before'/>
  <ws:rendition selector='.glyphicon-ice-lolly-tasted:before'/>
  <ws:rendition selector='.glyphicon-ice-lolly:before'/>
  <ws:rendition selector='.glyphicon-import:before'/>
  <ws:rendition selector='.glyphicon-inbox:before'/>
  <ws:rendition selector='.glyphicon-indent-left:before'/>
  <ws:rendition selector='.glyphicon-indent-right:before'/>
  <ws:rendition selector='.glyphicon-info-sign:before'/>
  <ws:rendition selector='.glyphicon-italic:before'/>
  <ws:rendition selector='.glyphicon-jpy:before'/>
  <ws:rendition selector='.glyphicon-king:before'/>
  <ws:rendition selector='.glyphicon-knight:before'/>
  <ws:rendition selector='.glyphicon-lamp:before'/>
  <ws:rendition selector='.glyphicon-leaf:before'/>
  <ws:rendition selector='.glyphicon-level-up:before'/>
  <ws:rendition selector='.glyphicon-link:before'/>
  <ws:rendition selector='.glyphicon-list-alt:before'/>
  <ws:rendition selector='.glyphicon-list:before'/>
  <ws:rendition selector='.glyphicon-lock:before'/>
  <ws:rendition selector='.glyphicon-log-in:before'/>
  <ws:rendition selector='.glyphicon-log-out:before'/>
  <ws:rendition selector='.glyphicon-magnet:before'/>
  <ws:rendition selector='.glyphicon-map-marker:before'/>
  <ws:rendition selector='.glyphicon-menu-down:before'/>
  <ws:rendition selector='.glyphicon-menu-hamburger:before'/>
  <ws:rendition selector='.glyphicon-menu-left:before'/>
  <ws:rendition selector='.glyphicon-menu-right:before'/>
  <ws:rendition selector='.glyphicon-menu-up:before'/>
  <ws:rendition selector='.glyphicon-minus-sign:before'/>
  <ws:rendition selector='.glyphicon-minus:before'/>
  <ws:rendition selector='.glyphicon-modal-window:before'/>
  <ws:rendition selector='.glyphicon-move:before'/>
  <ws:rendition selector='.glyphicon-music:before'/>
  <ws:rendition selector='.glyphicon-new-window:before'/>
  <ws:rendition selector='.glyphicon-object-align-bottom:before'/>
  <ws:rendition selector='.glyphicon-object-align-horizontal:before'/>
  <ws:rendition selector='.glyphicon-object-align-left:before'/>
  <ws:rendition selector='.glyphicon-object-align-right:before'/>
  <ws:rendition selector='.glyphicon-object-align-top:before'/>
  <ws:rendition selector='.glyphicon-object-align-vertical:before'/>
  <ws:rendition selector='.glyphicon-off:before'/>
  <ws:rendition selector='.glyphicon-oil:before'/>
  <ws:rendition selector='.glyphicon-ok-circle:before'/>
  <ws:rendition selector='.glyphicon-ok-sign:before'/>
  <ws:rendition selector='.glyphicon-ok:before'/>
  <ws:rendition selector='.glyphicon-open-file:before'/>
  <ws:rendition selector='.glyphicon-open:before'/>
  <ws:rendition selector='.glyphicon-option-horizontal:before'/>
  <ws:rendition selector='.glyphicon-option-vertical:before'/>
  <ws:rendition selector='.glyphicon-paperclip:before'/>
  <ws:rendition selector='.glyphicon-paste:before'/>
  <ws:rendition selector='.glyphicon-pause:before'/>
  <ws:rendition selector='.glyphicon-pawn:before'/>
  <ws:rendition selector='.glyphicon-pencil:before'/>
  <ws:rendition selector='.glyphicon-phone-alt:before'/>
  <ws:rendition selector='.glyphicon-phone:before'/>
  <ws:rendition selector='.glyphicon-picture:before'/>
  <ws:rendition selector='.glyphicon-piggy-bank:before'/>
  <ws:rendition selector='.glyphicon-plane:before'/>
  <ws:rendition selector='.glyphicon-play-circle:before'/>
  <ws:rendition selector='.glyphicon-play:before'/>
  <ws:rendition selector='.glyphicon-plus-sign:before'/>
  <ws:rendition selector='.glyphicon-plus:before'/>
  <ws:rendition selector='.glyphicon-print:before'/>
  <ws:rendition selector='.glyphicon-pushpin:before'/>
  <ws:rendition selector='.glyphicon-qrcode:before'/>
  <ws:rendition selector='.glyphicon-queen:before'/>
  <ws:rendition selector='.glyphicon-question-sign:before'/>
  <ws:rendition selector='.glyphicon-random:before'/>
  <ws:rendition selector='.glyphicon-record:before'/>
  <ws:rendition selector='.glyphicon-refresh:before'/>
  <ws:rendition selector='.glyphicon-registration-mark:before'/>
  <ws:rendition selector='.glyphicon-remove-circle:before'/>
  <ws:rendition selector='.glyphicon-remove-sign:before'/>
  <ws:rendition selector='.glyphicon-remove:before'/>
  <ws:rendition selector='.glyphicon-repeat:before'/>
  <ws:rendition selector='.glyphicon-resize-full:before'/>
  <ws:rendition selector='.glyphicon-resize-horizontal:before'/>
  <ws:rendition selector='.glyphicon-resize-small:before'/>
  <ws:rendition selector='.glyphicon-resize-vertical:before'/>
  <ws:rendition selector='.glyphicon-retweet:before'/>
  <ws:rendition selector='.glyphicon-road:before'/>
  <ws:rendition selector='.glyphicon-rub:before'/>
  <ws:rendition selector='.glyphicon-ruble:before'/>
  <ws:rendition selector='.glyphicon-save-file:before'/>
  <ws:rendition selector='.glyphicon-save:before'/>
  <ws:rendition selector='.glyphicon-saved:before'/>
  <ws:rendition selector='.glyphicon-scale:before'/>
  <ws:rendition selector='.glyphicon-scissors:before'/>
  <ws:rendition selector='.glyphicon-screenshot:before'/>
  <ws:rendition selector='.glyphicon-sd-video:before'/>
  <ws:rendition selector='.glyphicon-search:before'/>
  <ws:rendition selector='.glyphicon-send:before'/>
  <ws:rendition selector='.glyphicon-share-alt:before'/>
  <ws:rendition selector='.glyphicon-share:before'/>
  <ws:rendition selector='.glyphicon-shopping-cart:before'/>
  <ws:rendition selector='.glyphicon-signal:before'/>
  <ws:rendition selector='.glyphicon-sort-by-alphabet-alt:before'/>
  <ws:rendition selector='.glyphicon-sort-by-alphabet:before'/>
  <ws:rendition selector='.glyphicon-sort-by-attributes-alt:before'/>
  <ws:rendition selector='.glyphicon-sort-by-attributes:before'/>
  <ws:rendition selector='.glyphicon-sort-by-order-alt:before'/>
  <ws:rendition selector='.glyphicon-sort-by-order:before'/>
  <ws:rendition selector='.glyphicon-sort:before'/>
  <ws:rendition selector='.glyphicon-sound-5-1:before'/>
  <ws:rendition selector='.glyphicon-sound-6-1:before'/>
  <ws:rendition selector='.glyphicon-sound-7-1:before'/>
  <ws:rendition selector='.glyphicon-sound-dolby:before'/>
  <ws:rendition selector='.glyphicon-sound-stereo:before'/>
  <ws:rendition selector='.glyphicon-star-empty:before'/>
  <ws:rendition selector='.glyphicon-star:before'/>
  <ws:rendition selector='.glyphicon-stats:before'/>
  <ws:rendition selector='.glyphicon-step-backward:before'/>
  <ws:rendition selector='.glyphicon-step-forward:before'/>
  <ws:rendition selector='.glyphicon-stop:before'/>
  <ws:rendition selector='.glyphicon-subscript:before'/>
  <ws:rendition selector='.glyphicon-subtitles:before'/>
  <ws:rendition selector='.glyphicon-sunglasses:before'/>
  <ws:rendition selector='.glyphicon-superscript:before'/>
  <ws:rendition selector='.glyphicon-tag:before'/>
  <ws:rendition selector='.glyphicon-tags:before'/>
  <ws:rendition selector='.glyphicon-tasks:before'/>
  <ws:rendition selector='.glyphicon-tent:before'/>
  <ws:rendition selector='.glyphicon-text-background:before'/>
  <ws:rendition selector='.glyphicon-text-color:before'/>
  <ws:rendition selector='.glyphicon-text-height:before'/>
  <ws:rendition selector='.glyphicon-text-size:before'/>
  <ws:rendition selector='.glyphicon-text-width:before'/>
  <ws:rendition selector='.glyphicon-th-large:before'/>
  <ws:rendition selector='.glyphicon-th-list:before'/>
  <ws:rendition selector='.glyphicon-th:before'/>
  <ws:rendition selector='.glyphicon-thumbs-down:before'/>
  <ws:rendition selector='.glyphicon-thumbs-up:before'/>
  <ws:rendition selector='.glyphicon-time:before'/>
  <ws:rendition selector='.glyphicon-tint:before'/>
  <ws:rendition selector='.glyphicon-tower:before'/>
  <ws:rendition selector='.glyphicon-transfer:before'/>
  <ws:rendition selector='.glyphicon-trash:before'/>
  <ws:rendition selector='.glyphicon-tree-conifer:before'/>
  <ws:rendition selector='.glyphicon-tree-deciduous:before'/>
  <ws:rendition selector='.glyphicon-triangle-bottom:before'/>
  <ws:rendition selector='.glyphicon-triangle-left:before'/>
  <ws:rendition selector='.glyphicon-triangle-right:before'/>
  <ws:rendition selector='.glyphicon-triangle-top:before'/>
  <ws:rendition selector='.glyphicon-unchecked:before'/>
  <ws:rendition selector='.glyphicon-upload:before'/>
  <ws:rendition selector='.glyphicon-usd:before'/>
  <ws:rendition selector='.glyphicon-user:before'/>
  <ws:rendition selector='.glyphicon-volume-down:before'/>
  <ws:rendition selector='.glyphicon-volume-off:before'/>
  <ws:rendition selector='.glyphicon-volume-up:before'/>
  <ws:rendition selector='.glyphicon-warning-sign:before'/>
  <ws:rendition selector='.glyphicon-wrench:before'/>
  <ws:rendition selector='.glyphicon-xbt:before'/>
  <ws:rendition selector='.glyphicon-yen:before'/>
  <ws:rendition selector='.glyphicon-zoom-in:before'/>
  <ws:rendition selector='.glyphicon-zoom-out:before'/>
  <ws:rendition selector='.green '/>
  <ws:rendition selector='.h1 .small,.h1 small,.h2 .small,.h2 small,.h3 .small,.h3 small,.h4 .small,.h4 small,.h5 .small,.h5 small,.h6 .small,.h6 small,h1 .small,h1 small,h2 .small,h2 small,h3 .small,h3 small,h4 .small,h4 small,h5 .small,h5 small,h6 .small,h6 small'/>
  <ws:rendition selector='.h1 .small,.h1 small,.h2 .small,.h2 small,.h3 .small,.h3 small,h1 .small,h1 small,h2 .small,h2 small,h3 .small,h3 small'/>
  <ws:rendition selector='.h1,.h2,.h3,.h4,.h5,.h6,h1,h2,h3,h4,h5,h6'/>
  <ws:rendition selector='.h1,.h2,.h3,h1,h2,h3'/>
  <ws:rendition selector='.h1,h1'/>
  <ws:rendition selector='.h2,h2'/>
  <ws:rendition selector='.h3,h3'/>
  <ws:rendition selector='.h4 .small,.h4 small,.h5 .small,.h5 small,.h6 .small,.h6 small,h4 .small,h4 small,h5 .small,h5 small,h6 .small,h6 small'/>
  <ws:rendition selector='.h4,.h5,.h6,h4,h5,h6'/>
  <ws:rendition selector='.h4,h4'/>
  <ws:rendition selector='.h5,h5'/>
  <ws:rendition selector='.h6,h6'/>
  <ws:rendition selector='.has-error .checkbox,.has-error .checkbox-inline,.has-error .control-label,.has-error .help-block,.has-error .radio,.has-error .radio-inline,.has-error.checkbox label,.has-error.checkbox-inline label,.has-error.radio label,.has-error.radio-inline label'/>
  <ws:rendition selector='.has-error .form-control'/>
  <ws:rendition selector='.has-error .form-control-feedback'/>
  <ws:rendition selector='.has-error .form-control:focus'/>
  <ws:rendition selector='.has-error .input-group-addon'/>
  <ws:rendition selector='.has-feedback'/>
  <ws:rendition selector='.has-feedback .form-control'/>
  <ws:rendition selector='.has-feedback label.sr-only~.form-control-feedback'/>
  <ws:rendition selector='.has-feedback label~.form-control-feedback'/>
  <ws:rendition selector='.has-success .checkbox,.has-success .checkbox-inline,.has-success .control-label,.has-success .help-block,.has-success .radio,.has-success .radio-inline,.has-success.checkbox label,.has-success.checkbox-inline label,.has-success.radio label,.has-success.radio-inline label'/>
  <ws:rendition selector='.has-success .form-control'/>
  <ws:rendition selector='.has-success .form-control-feedback'/>
  <ws:rendition selector='.has-success .form-control:focus'/>
  <ws:rendition selector='.has-success .input-group-addon'/>
  <ws:rendition selector='.has-warning .checkbox,.has-warning .checkbox-inline,.has-warning .control-label,.has-warning .help-block,.has-warning .radio,.has-warning .radio-inline,.has-warning.checkbox label,.has-warning.checkbox-inline label,.has-warning.radio label,.has-warning.radio-inline label'/>
  <ws:rendition selector='.has-warning .form-control'/>
  <ws:rendition selector='.has-warning .form-control-feedback'/>
  <ws:rendition selector='.has-warning .form-control:focus'/>
  <ws:rendition selector='.has-warning .input-group-addon'/>
  <ws:rendition selector='.help-block'/>
  <ws:rendition selector='.hidden'/>
  <ws:rendition selector='.hidden '/>
  <ws:rendition selector='.hide'/>
  <ws:rendition selector='.ie6_button,'/>
  <ws:rendition selector='.ie6_button_disabled '/>
  <ws:rendition selector='.ie6_input,'/>
  <ws:rendition selector='.ie6_input_disabled '/>
  <ws:rendition selector='.ie6_input_disabled,'/>
  <ws:rendition selector='.img-circle'/>
  <ws:rendition selector='.img-rounded'/>
  <ws:rendition selector='.img-thumbnail'/>
  <ws:rendition selector='.inherownwords '/>
  <ws:rendition selector='.initialism'/>
  <ws:rendition selector='.input-group'/>
  <ws:rendition selector='.input-group .form-control'/>
  <ws:rendition selector='.input-group .form-control,.input-group-addon,.input-group-btn'/>
  <ws:rendition selector='.input-group .form-control:first-child,.input-group-addon:first-child,.input-group-btn:first-child>.btn,.input-group-btn:first-child>.btn-group>.btn,.input-group-btn:first-child>.dropdown-toggle,.input-group-btn:last-child>.btn-group:not(:last-child)>.btn,.input-group-btn:last-child>.btn:not(:last-child):not(.dropdown-toggle)'/>
  <ws:rendition selector='.input-group .form-control:focus'/>
  <ws:rendition selector='.input-group .form-control:last-child,.input-group-addon:last-child,.input-group-btn:first-child>.btn-group:not(:first-child)>.btn,.input-group-btn:first-child>.btn:not(:first-child),.input-group-btn:last-child>.btn,.input-group-btn:last-child>.btn-group>.btn,.input-group-btn:last-child>.dropdown-toggle'/>
  <ws:rendition selector='.input-group .form-control:not(:first-child):not(:last-child),.input-group-addon:not(:first-child):not(:last-child),.input-group-btn:not(:first-child):not(:last-child)'/>
  <ws:rendition selector='.input-group-addon'/>
  <ws:rendition selector='.input-group-addon input[type=checkbox],.input-group-addon input[type=radio]'/>
  <ws:rendition selector='.input-group-addon,.input-group-btn'/>
  <ws:rendition selector='.input-group-addon.input-lg'/>
  <ws:rendition selector='.input-group-addon.input-sm'/>
  <ws:rendition selector='.input-group-addon:first-child'/>
  <ws:rendition selector='.input-group-addon:last-child'/>
  <ws:rendition selector='.input-group-btn'/>
  <ws:rendition selector='.input-group-btn:first-child>.btn,.input-group-btn:first-child>.btn-group'/>
  <ws:rendition selector='.input-group-btn:last-child>.btn,.input-group-btn:last-child>.btn-group'/>
  <ws:rendition selector='.input-group-btn>.btn'/>
  <ws:rendition selector='.input-group-btn>.btn+.btn'/>
  <ws:rendition selector='.input-group-btn>.btn:active,.input-group-btn>.btn:focus,.input-group-btn>.btn:hover'/>
  <ws:rendition selector='.input-group-lg input[type=date],.input-group-lg input[type=time],.input-group-lg input[type=datetime-local],.input-group-lg input[type=month],input[type=date].input-lg,input[type=time].input-lg,input[type=datetime-local].input-lg,input[type=month].input-lg'/>
  <ws:rendition selector='.input-group-lg>.form-control,.input-group-lg>.input-group-addon,.input-group-lg>.input-group-btn>.btn'/>
  <ws:rendition selector='.input-group-sm input[type=date],.input-group-sm input[type=time],.input-group-sm input[type=datetime-local],.input-group-sm input[type=month],input[type=date].input-sm,input[type=time].input-sm,input[type=datetime-local].input-sm,input[type=month].input-sm'/>
  <ws:rendition selector='.input-group-sm>.form-control,.input-group-sm>.input-group-addon,.input-group-sm>.input-group-btn>.btn'/>
  <ws:rendition selector='.input-group[class*=col-]'/>
  <ws:rendition selector='.input-lg'/>
  <ws:rendition selector='.input-sm'/>
  <ws:rendition selector='.input_full '/>
  <ws:rendition selector='.input_full_wrap '/>
  <ws:rendition selector='.input_large '/>
  <ws:rendition selector='.input_medium '/>
  <ws:rendition selector='.input_small '/>
  <ws:rendition selector='.input_tiny '/>
  <ws:rendition selector='.input_xlarge '/>
  <ws:rendition selector='.input_xxlarge '/>
  <ws:rendition selector='.invisible'/>
  <ws:rendition selector='.italic '/>
  <ws:rendition selector='.jspArrow'/>
  <ws:rendition selector='.jspArrow.jspDisabled'/>
  <ws:rendition selector='.jspCap'/>
  <ws:rendition selector='.jspContainer'/>
  <ws:rendition selector='.jspCorner'/>
  <ws:rendition selector='.jspDrag'/>
  <ws:rendition selector='.jspDrag '/>
  <ws:rendition selector='.jspHorizontalBar'/>
  <ws:rendition selector='.jspHorizontalBar *'/>
  <ws:rendition selector='.jspHorizontalBar .jspArrow'/>
  <ws:rendition selector='.jspHorizontalBar .jspCap'/>
  <ws:rendition selector='.jspHorizontalBar .jspDrag'/>
  <ws:rendition selector='.jspHorizontalBar .jspTrack,'/>
  <ws:rendition selector='.jspPane'/>
  <ws:rendition selector='.jspTrack'/>
  <ws:rendition selector='.jspTrack '/>
  <ws:rendition selector='.jspVerticalBar'/>
  <ws:rendition selector='.jspVerticalBar '/>
  <ws:rendition selector='.jspVerticalBar *,'/>
  <ws:rendition selector='.jspVerticalBar .jspArrow'/>
  <ws:rendition selector='.jspVerticalBar .jspArrow:focus'/>
  <ws:rendition selector='.jumbotron'/>
  <ws:rendition selector='.jumbotron .container'/>
  <ws:rendition selector='.jumbotron .h1,.jumbotron h1'/>
  <ws:rendition selector='.jumbotron p'/>
  <ws:rendition selector='.jumbotron>hr'/>
  <ws:rendition selector='.keynav '/>
  <ws:rendition selector='.label'/>
  <ws:rendition selector='.label-danger'/>
  <ws:rendition selector='.label-danger[href]:focus,.label-danger[href]:hover'/>
  <ws:rendition selector='.label-default'/>
  <ws:rendition selector='.label-default[href]:focus,.label-default[href]:hover'/>
  <ws:rendition selector='.label-info'/>
  <ws:rendition selector='.label-info[href]:focus,.label-info[href]:hover'/>
  <ws:rendition selector='.label-primary'/>
  <ws:rendition selector='.label-primary[href]:focus,.label-primary[href]:hover'/>
  <ws:rendition selector='.label-success'/>
  <ws:rendition selector='.label-success[href]:focus,.label-success[href]:hover'/>
  <ws:rendition selector='.label-warning'/>
  <ws:rendition selector='.label-warning[href]:focus,.label-warning[href]:hover'/>
  <ws:rendition selector='.label:empty'/>
  <ws:rendition selector='.lead'/>
  <ws:rendition selector='.libreak '/>
  <ws:rendition selector='.list-group'/>
  <ws:rendition selector='.list-group+.panel-footer'/>
  <ws:rendition selector='.list-group-item'/>
  <ws:rendition selector='.list-group-item-danger'/>
  <ws:rendition selector='.list-group-item-heading'/>
  <ws:rendition selector='.list-group-item-info'/>
  <ws:rendition selector='.list-group-item-success'/>
  <ws:rendition selector='.list-group-item-text'/>
  <ws:rendition selector='.list-group-item-warning'/>
  <ws:rendition selector='.list-group-item.active .list-group-item-heading,.list-group-item.active .list-group-item-heading>.small,.list-group-item.active .list-group-item-heading>small,.list-group-item.active:focus .list-group-item-heading,.list-group-item.active:focus .list-group-item-heading>.small,.list-group-item.active:focus .list-group-item-heading>small,.list-group-item.active:hover .list-group-item-heading,.list-group-item.active:hover .list-group-item-heading>.small,.list-group-item.active:hover .list-group-item-heading>small'/>
  <ws:rendition selector='.list-group-item.active .list-group-item-text,.list-group-item.active:focus .list-group-item-text,.list-group-item.active:hover .list-group-item-text'/>
  <ws:rendition selector='.list-group-item.active,.list-group-item.active:focus,.list-group-item.active:hover'/>
  <ws:rendition selector='.list-group-item.active>.badge,.nav-pills>.active>a>.badge'/>
  <ws:rendition selector='.list-group-item.disabled .list-group-item-heading,.list-group-item.disabled:focus .list-group-item-heading,.list-group-item.disabled:hover .list-group-item-heading'/>
  <ws:rendition selector='.list-group-item.disabled .list-group-item-text,.list-group-item.disabled:focus .list-group-item-text,.list-group-item.disabled:hover .list-group-item-text'/>
  <ws:rendition selector='.list-group-item.disabled,.list-group-item.disabled:focus,.list-group-item.disabled:hover'/>
  <ws:rendition selector='.list-group-item:first-child'/>
  <ws:rendition selector='.list-group-item:last-child'/>
  <ws:rendition selector='.list-group-item>.badge'/>
  <ws:rendition selector='.list-group-item>.badge+.badge'/>
  <ws:rendition selector='.list-inline'/>
  <ws:rendition selector='.list-inline>li'/>
  <ws:rendition selector='.list-unstyled'/>
  <ws:rendition selector='.map '/>
  <ws:rendition selector='.mark,mark'/>
  <ws:rendition selector='.media'/>
  <ws:rendition selector='.media,.media-body'/>
  <ws:rendition selector='.media-body'/>
  <ws:rendition selector='.media-body,.media-left,.media-right'/>
  <ws:rendition selector='.media-bottom'/>
  <ws:rendition selector='.media-heading'/>
  <ws:rendition selector='.media-left,.media>.pull-left'/>
  <ws:rendition selector='.media-list'/>
  <ws:rendition selector='.media-middle'/>
  <ws:rendition selector='.media-object'/>
  <ws:rendition selector='.media-object.img-thumbnail'/>
  <ws:rendition selector='.media-right,.media>.pull-right'/>
  <ws:rendition selector='.media:first-child'/>
  <ws:rendition selector='.menu '/>
  <ws:rendition selector='.menu .menu-item '/>
  <ws:rendition selector='.menu .menu-item.button-toggle '/>
  <ws:rendition selector='.menu .menu-item.button-toggle .button '/>
  <ws:rendition selector='.menu .menu-item.button-toggle .button.active '/>
  <ws:rendition selector='.menu .menu-item.button-toggle .button:hover '/>
  <ws:rendition selector='.menu .menu-item.button-toggle .button:hover.active '/>
  <ws:rendition selector='.menu .menu-item.button-toggle-label '/>
  <ws:rendition selector='.menu .menu-item:first-child '/>
  <ws:rendition selector='.menu .menu-item:last-child '/>
  <ws:rendition selector='.modal'/>
  <ws:rendition selector='.modal-backdrop'/>
  <ws:rendition selector='.modal-backdrop.fade'/>
  <ws:rendition selector='.modal-backdrop.in'/>
  <ws:rendition selector='.modal-body'/>
  <ws:rendition selector='.modal-content'/>
  <ws:rendition selector='.modal-dialog'/>
  <ws:rendition selector='.modal-footer'/>
  <ws:rendition selector='.modal-footer .btn+.btn'/>
  <ws:rendition selector='.modal-footer .btn-block+.btn-block'/>
  <ws:rendition selector='.modal-footer .btn-group .btn+.btn'/>
  <ws:rendition selector='.modal-header'/>
  <ws:rendition selector='.modal-header .close'/>
  <ws:rendition selector='.modal-open'/>
  <ws:rendition selector='.modal-open .modal'/>
  <ws:rendition selector='.modal-scrollbar-measure'/>
  <ws:rendition selector='.modal-sm'/>
  <ws:rendition selector='.modal-title'/>
  <ws:rendition selector='.modal.fade .modal-dialog'/>
  <ws:rendition selector='.modal.in .modal-dialog'/>
  <ws:rendition selector='.myAccordion'/>
  <ws:rendition selector='.myAccordion dd'/>
  <ws:rendition selector='.myAccordion dt'/>
  <ws:rendition selector='.myAccordion dt.myAccordionActive'/>
  <ws:rendition selector='.myAccordion dt.myAccordionHover'/>
  <ws:rendition selector='.myAccordion p'/>
  <ws:rendition selector='.nav'/>
  <ws:rendition selector='.nav .nav-divider'/>
  <ws:rendition selector='.nav .open>a,.nav .open>a:focus,.nav .open>a:hover'/>
  <ws:rendition selector='.nav-justified'/>
  <ws:rendition selector='.nav-justified>.dropdown .dropdown-menu'/>
  <ws:rendition selector='.nav-justified>li'/>
  <ws:rendition selector='.nav-justified>li>a'/>
  <ws:rendition selector='.nav-pills>li'/>
  <ws:rendition selector='.nav-pills>li+li'/>
  <ws:rendition selector='.nav-pills>li.active>a,.nav-pills>li.active>a:focus,.nav-pills>li.active>a:hover'/>
  <ws:rendition selector='.nav-pills>li>a'/>
  <ws:rendition selector='.nav-pills>li>a>.badge'/>
  <ws:rendition selector='.nav-stacked>li'/>
  <ws:rendition selector='.nav-stacked>li+li'/>
  <ws:rendition selector='.nav-tabs'/>
  <ws:rendition selector='.nav-tabs .dropdown-menu'/>
  <ws:rendition selector='.nav-tabs-justified'/>
  <ws:rendition selector='.nav-tabs-justified>.active>a,.nav-tabs-justified>.active>a:focus,.nav-tabs-justified>.active>a:hover'/>
  <ws:rendition selector='.nav-tabs-justified>li>a'/>
  <ws:rendition selector='.nav-tabs.nav-justified'/>
  <ws:rendition selector='.nav-tabs.nav-justified>.active>a,.nav-tabs.nav-justified>.active>a:focus,.nav-tabs.nav-justified>.active>a:hover'/>
  <ws:rendition selector='.nav-tabs.nav-justified>.dropdown .dropdown-menu'/>
  <ws:rendition selector='.nav-tabs.nav-justified>li'/>
  <ws:rendition selector='.nav-tabs.nav-justified>li>a'/>
  <ws:rendition selector='.nav-tabs>li'/>
  <ws:rendition selector='.nav-tabs>li.active>a,.nav-tabs>li.active>a:focus,.nav-tabs>li.active>a:hover'/>
  <ws:rendition selector='.nav-tabs>li>a'/>
  <ws:rendition selector='.nav-tabs>li>a:hover'/>
  <ws:rendition selector='.nav:hover '/>
  <ws:rendition selector='.nav:link '/>
  <ws:rendition selector='.nav:visited '/>
  <ws:rendition selector='.nav>li'/>
  <ws:rendition selector='.nav>li.disabled>a'/>
  <ws:rendition selector='.nav>li.disabled>a:focus,.nav>li.disabled>a:hover'/>
  <ws:rendition selector='.nav>li>a'/>
  <ws:rendition selector='.nav>li>a:focus,.nav>li>a:hover'/>
  <ws:rendition selector='.nav>li>a>img'/>
  <ws:rendition selector='.navbar'/>
  <ws:rendition selector='.navbar-brand'/>
  <ws:rendition selector='.navbar-brand:focus,.navbar-brand:hover'/>
  <ws:rendition selector='.navbar-brand>img'/>
  <ws:rendition selector='.navbar-btn'/>
  <ws:rendition selector='.navbar-btn.btn-sm'/>
  <ws:rendition selector='.navbar-btn.btn-xs'/>
  <ws:rendition selector='.navbar-collapse'/>
  <ws:rendition selector='.navbar-collapse.collapse'/>
  <ws:rendition selector='.navbar-collapse.in'/>
  <ws:rendition selector='.navbar-default'/>
  <ws:rendition selector='.navbar-default .btn-link'/>
  <ws:rendition selector='.navbar-default .btn-link:focus,.navbar-default .btn-link:hover'/>
  <ws:rendition selector='.navbar-default .btn-link[disabled]:focus,.navbar-default .btn-link[disabled]:hover,fieldset[disabled] .navbar-default .btn-link:focus,fieldset[disabled] .navbar-default .btn-link:hover'/>
  <ws:rendition selector='.navbar-default .navbar-brand'/>
  <ws:rendition selector='.navbar-default .navbar-brand:focus,.navbar-default .navbar-brand:hover'/>
  <ws:rendition selector='.navbar-default .navbar-collapse,.navbar-default .navbar-form'/>
  <ws:rendition selector='.navbar-default .navbar-link'/>
  <ws:rendition selector='.navbar-default .navbar-link:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav .open .dropdown-menu>.active>a,.navbar-default .navbar-nav .open .dropdown-menu>.active>a:focus,.navbar-default .navbar-nav .open .dropdown-menu>.active>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav .open .dropdown-menu>.disabled>a,.navbar-default .navbar-nav .open .dropdown-menu>.disabled>a:focus,.navbar-default .navbar-nav .open .dropdown-menu>.disabled>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav .open .dropdown-menu>li>a:focus,.navbar-default .navbar-nav .open .dropdown-menu>li>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav>.active>a,.navbar-default .navbar-nav>.active>a:focus,.navbar-default .navbar-nav>.active>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav>.disabled>a,.navbar-default .navbar-nav>.disabled>a:focus,.navbar-default .navbar-nav>.disabled>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav>.open>a,.navbar-default .navbar-nav>.open>a:focus,.navbar-default .navbar-nav>.open>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-nav>li>a'/>
  <ws:rendition selector='.navbar-default .navbar-nav>li>a:focus,.navbar-default .navbar-nav>li>a:hover'/>
  <ws:rendition selector='.navbar-default .navbar-text'/>
  <ws:rendition selector='.navbar-default .navbar-toggle'/>
  <ws:rendition selector='.navbar-default .navbar-toggle .icon-bar'/>
  <ws:rendition selector='.navbar-default .navbar-toggle:focus,.navbar-default .navbar-toggle:hover'/>
  <ws:rendition selector='.navbar-fixed-bottom'/>
  <ws:rendition selector='.navbar-fixed-bottom .navbar-collapse,.navbar-fixed-top .navbar-collapse'/>
  <ws:rendition selector='.navbar-fixed-bottom .navbar-collapse,.navbar-fixed-top .navbar-collapse,.navbar-static-top .navbar-collapse'/>
  <ws:rendition selector='.navbar-fixed-bottom .navbar-nav>li>.dropdown-menu'/>
  <ws:rendition selector='.navbar-fixed-bottom,.navbar-fixed-top'/>
  <ws:rendition selector='.navbar-fixed-top'/>
  <ws:rendition selector='.navbar-form'/>
  <ws:rendition selector='.navbar-form .checkbox input[type=checkbox],.navbar-form .radio input[type=radio]'/>
  <ws:rendition selector='.navbar-form .checkbox label,.navbar-form .radio label'/>
  <ws:rendition selector='.navbar-form .checkbox,.navbar-form .radio'/>
  <ws:rendition selector='.navbar-form .control-label'/>
  <ws:rendition selector='.navbar-form .form-control'/>
  <ws:rendition selector='.navbar-form .form-control-static'/>
  <ws:rendition selector='.navbar-form .form-group:last-child'/>
  <ws:rendition selector='.navbar-form .has-feedback .form-control-feedback'/>
  <ws:rendition selector='.navbar-form .input-group'/>
  <ws:rendition selector='.navbar-form .input-group .form-control,.navbar-form .input-group .input-group-addon,.navbar-form .input-group .input-group-btn'/>
  <ws:rendition selector='.navbar-form .input-group>.form-control'/>
  <ws:rendition selector='.navbar-inverse'/>
  <ws:rendition selector='.navbar-inverse .btn-link'/>
  <ws:rendition selector='.navbar-inverse .btn-link:focus,.navbar-inverse .btn-link:hover'/>
  <ws:rendition selector='.navbar-inverse .btn-link[disabled]:focus,.navbar-inverse .btn-link[disabled]:hover,fieldset[disabled] .navbar-inverse .btn-link:focus,fieldset[disabled] .navbar-inverse .btn-link:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-brand'/>
  <ws:rendition selector='.navbar-inverse .navbar-brand:focus,.navbar-inverse .navbar-brand:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-collapse,.navbar-inverse .navbar-form'/>
  <ws:rendition selector='.navbar-inverse .navbar-link'/>
  <ws:rendition selector='.navbar-inverse .navbar-link:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav .open .dropdown-menu .divider'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav .open .dropdown-menu>.active>a,.navbar-inverse .navbar-nav .open .dropdown-menu>.active>a:focus,.navbar-inverse .navbar-nav .open .dropdown-menu>.active>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav .open .dropdown-menu>.disabled>a,.navbar-inverse .navbar-nav .open .dropdown-menu>.disabled>a:focus,.navbar-inverse .navbar-nav .open .dropdown-menu>.disabled>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav .open .dropdown-menu>li>a'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav .open .dropdown-menu>li>a:focus,.navbar-inverse .navbar-nav .open .dropdown-menu>li>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav>.active>a,.navbar-inverse .navbar-nav>.active>a:focus,.navbar-inverse .navbar-nav>.active>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav>.disabled>a,.navbar-inverse .navbar-nav>.disabled>a:focus,.navbar-inverse .navbar-nav>.disabled>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav>.open>a,.navbar-inverse .navbar-nav>.open>a:focus,.navbar-inverse .navbar-nav>.open>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav>li>a'/>
  <ws:rendition selector='.navbar-inverse .navbar-nav>li>a:focus,.navbar-inverse .navbar-nav>li>a:hover'/>
  <ws:rendition selector='.navbar-inverse .navbar-text'/>
  <ws:rendition selector='.navbar-inverse .navbar-toggle'/>
  <ws:rendition selector='.navbar-inverse .navbar-toggle .icon-bar'/>
  <ws:rendition selector='.navbar-inverse .navbar-toggle:focus,.navbar-inverse .navbar-toggle:hover'/>
  <ws:rendition selector='.navbar-nav'/>
  <ws:rendition selector='.navbar-nav .open .dropdown-menu .dropdown-header,.navbar-nav .open .dropdown-menu>li>a'/>
  <ws:rendition selector='.navbar-nav .open .dropdown-menu>li>a'/>
  <ws:rendition selector='.navbar-nav .open .dropdown-menu>li>a:focus,.navbar-nav .open .dropdown-menu>li>a:hover'/>
  <ws:rendition selector='.navbar-nav.navbar-right:last-child '/>
  <ws:rendition selector='.navbar-nav>li'/>
  <ws:rendition selector='.navbar-nav>li>.dropdown-menu'/>
  <ws:rendition selector='.navbar-nav>li>a'/>
  <ws:rendition selector='.navbar-right'/>
  <ws:rendition selector='.navbar-right .dropdown-menu-left'/>
  <ws:rendition selector='.navbar-right~.navbar-right'/>
  <ws:rendition selector='.navbar-static-top'/>
  <ws:rendition selector='.navbar-text'/>
  <ws:rendition selector='.navbar-toggle'/>
  <ws:rendition selector='.navbar-toggle .icon-bar'/>
  <ws:rendition selector='.navbar-toggle .icon-bar+.icon-bar'/>
  <ws:rendition selector='.navbar-toggle:focus'/>
  <ws:rendition selector='.note '/>
  <ws:rendition selector='.note a '/>
  <ws:rendition selector='.note a span '/>
  <ws:rendition selector='.note a:hover '/>
  <ws:rendition selector='.note a:hover span '/>
  <ws:rendition selector='.open>.dropdown-menu'/>
  <ws:rendition selector='.open>a'/>
  <ws:rendition selector='.orange '/>
  <ws:rendition selector='.page-header'/>
  <ws:rendition selector='.pager'/>
  <ws:rendition selector='.pager .disabled>a,.pager .disabled>a:focus,.pager .disabled>a:hover,.pager .disabled>span'/>
  <ws:rendition selector='.pager .next>a,.pager .next>span'/>
  <ws:rendition selector='.pager .previous>a,.pager .previous>span'/>
  <ws:rendition selector='.pager li'/>
  <ws:rendition selector='.pager li>a,.pager li>span'/>
  <ws:rendition selector='.pager li>a:focus,.pager li>a:hover'/>
  <ws:rendition selector='.pagination'/>
  <ws:rendition selector='.pagination-lg>li:first-child>a,.pagination-lg>li:first-child>span'/>
  <ws:rendition selector='.pagination-lg>li:last-child>a,.pagination-lg>li:last-child>span'/>
  <ws:rendition selector='.pagination-lg>li>a,.pagination-lg>li>span'/>
  <ws:rendition selector='.pagination-sm>li:first-child>a,.pagination-sm>li:first-child>span'/>
  <ws:rendition selector='.pagination-sm>li:last-child>a,.pagination-sm>li:last-child>span'/>
  <ws:rendition selector='.pagination-sm>li>a,.pagination-sm>li>span'/>
  <ws:rendition selector='.pagination>.active>a,.pagination>.active>a:focus,.pagination>.active>a:hover,.pagination>.active>span,.pagination>.active>span:focus,.pagination>.active>span:hover'/>
  <ws:rendition selector='.pagination>.disabled>a,.pagination>.disabled>a:focus,.pagination>.disabled>a:hover,.pagination>.disabled>span,.pagination>.disabled>span:focus,.pagination>.disabled>span:hover'/>
  <ws:rendition selector='.pagination>li'/>
  <ws:rendition selector='.pagination>li:first-child>a,.pagination>li:first-child>span'/>
  <ws:rendition selector='.pagination>li:last-child>a,.pagination>li:last-child>span'/>
  <ws:rendition selector='.pagination>li>a,.pagination>li>span'/>
  <ws:rendition selector='.pagination>li>a:focus,.pagination>li>a:hover,.pagination>li>span:focus,.pagination>li>span:hover'/>
  <ws:rendition selector='.panel'/>
  <ws:rendition selector='.panel-body'/>
  <ws:rendition selector='.panel-danger'/>
  <ws:rendition selector='.panel-danger>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-danger>.panel-heading'/>
  <ws:rendition selector='.panel-danger>.panel-heading .badge'/>
  <ws:rendition selector='.panel-danger>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-default'/>
  <ws:rendition selector='.panel-default>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-default>.panel-heading'/>
  <ws:rendition selector='.panel-default>.panel-heading .badge'/>
  <ws:rendition selector='.panel-default>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-footer'/>
  <ws:rendition selector='.panel-group'/>
  <ws:rendition selector='.panel-group .panel'/>
  <ws:rendition selector='.panel-group .panel+.panel'/>
  <ws:rendition selector='.panel-group .panel-footer'/>
  <ws:rendition selector='.panel-group .panel-footer+.panel-collapse .panel-body'/>
  <ws:rendition selector='.panel-group .panel-heading'/>
  <ws:rendition selector='.panel-group .panel-heading+.panel-collapse>.list-group,.panel-group .panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-heading'/>
  <ws:rendition selector='.panel-heading+.list-group .list-group-item:first-child'/>
  <ws:rendition selector='.panel-heading>.dropdown .dropdown-toggle'/>
  <ws:rendition selector='.panel-info'/>
  <ws:rendition selector='.panel-info>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-info>.panel-heading'/>
  <ws:rendition selector='.panel-info>.panel-heading .badge'/>
  <ws:rendition selector='.panel-info>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-primary'/>
  <ws:rendition selector='.panel-primary>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-primary>.panel-heading'/>
  <ws:rendition selector='.panel-primary>.panel-heading .badge'/>
  <ws:rendition selector='.panel-primary>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-success'/>
  <ws:rendition selector='.panel-success>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-success>.panel-heading'/>
  <ws:rendition selector='.panel-success>.panel-heading .badge'/>
  <ws:rendition selector='.panel-success>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-title'/>
  <ws:rendition selector='.panel-title>.small,.panel-title>.small>a,.panel-title>a,.panel-title>small,.panel-title>small>a'/>
  <ws:rendition selector='.panel-warning'/>
  <ws:rendition selector='.panel-warning>.panel-footer+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel-warning>.panel-heading'/>
  <ws:rendition selector='.panel-warning>.panel-heading .badge'/>
  <ws:rendition selector='.panel-warning>.panel-heading+.panel-collapse>.panel-body'/>
  <ws:rendition selector='.panel>.list-group .list-group-item,.panel>.panel-collapse>.list-group .list-group-item'/>
  <ws:rendition selector='.panel>.list-group,.panel>.panel-collapse>.list-group'/>
  <ws:rendition selector='.panel>.list-group:first-child .list-group-item:first-child,.panel>.panel-collapse>.list-group:first-child .list-group-item:first-child'/>
  <ws:rendition selector='.panel>.list-group:last-child .list-group-item:last-child,.panel>.panel-collapse>.list-group:last-child .list-group-item:last-child'/>
  <ws:rendition selector='.panel>.panel-body+.table,.panel>.panel-body+.table-responsive,.panel>.table+.panel-body,.panel>.table-responsive+.panel-body'/>
  <ws:rendition selector='.panel>.panel-collapse>.table caption,.panel>.table caption,.panel>.table-responsive>.table caption'/>
  <ws:rendition selector='.panel>.panel-collapse>.table,.panel>.table,.panel>.table-responsive>.table'/>
  <ws:rendition selector='.panel>.panel-heading+.panel-collapse>.list-group .list-group-item:first-child'/>
  <ws:rendition selector='.panel>.table-bordered,.panel>.table-responsive>.table-bordered'/>
  <ws:rendition selector='.panel>.table-bordered>tbody>tr:first-child>td,.panel>.table-bordered>tbody>tr:first-child>th,.panel>.table-bordered>thead>tr:first-child>td,.panel>.table-bordered>thead>tr:first-child>th,.panel>.table-responsive>.table-bordered>tbody>tr:first-child>td,.panel>.table-responsive>.table-bordered>tbody>tr:first-child>th,.panel>.table-responsive>.table-bordered>thead>tr:first-child>td,.panel>.table-responsive>.table-bordered>thead>tr:first-child>th'/>
  <ws:rendition selector='.panel>.table-bordered>tbody>tr:last-child>td,.panel>.table-bordered>tbody>tr:last-child>th,.panel>.table-bordered>tfoot>tr:last-child>td,.panel>.table-bordered>tfoot>tr:last-child>th,.panel>.table-responsive>.table-bordered>tbody>tr:last-child>td,.panel>.table-responsive>.table-bordered>tbody>tr:last-child>th,.panel>.table-responsive>.table-bordered>tfoot>tr:last-child>td,.panel>.table-responsive>.table-bordered>tfoot>tr:last-child>th'/>
  <ws:rendition selector='.panel>.table-bordered>tbody>tr>td:first-child,.panel>.table-bordered>tbody>tr>th:first-child,.panel>.table-bordered>tfoot>tr>td:first-child,.panel>.table-bordered>tfoot>tr>th:first-child,.panel>.table-bordered>thead>tr>td:first-child,.panel>.table-bordered>thead>tr>th:first-child,.panel>.table-responsive>.table-bordered>tbody>tr>td:first-child,.panel>.table-responsive>.table-bordered>tbody>tr>th:first-child,.panel>.table-responsive>.table-bordered>tfoot>tr>td:first-child,.panel>.table-responsive>.table-bordered>tfoot>tr>th:first-child,.panel>.table-responsive>.table-bordered>thead>tr>td:first-child,.panel>.table-responsive>.table-bordered>thead>tr>th:first-child'/>
  <ws:rendition selector='.panel>.table-bordered>tbody>tr>td:last-child,.panel>.table-bordered>tbody>tr>th:last-child,.panel>.table-bordered>tfoot>tr>td:last-child,.panel>.table-bordered>tfoot>tr>th:last-child,.panel>.table-bordered>thead>tr>td:last-child,.panel>.table-bordered>thead>tr>th:last-child,.panel>.table-responsive>.table-bordered>tbody>tr>td:last-child,.panel>.table-responsive>.table-bordered>tbody>tr>th:last-child,.panel>.table-responsive>.table-bordered>tfoot>tr>td:last-child,.panel>.table-responsive>.table-bordered>tfoot>tr>th:last-child,.panel>.table-responsive>.table-bordered>thead>tr>td:last-child,.panel>.table-responsive>.table-bordered>thead>tr>th:last-child'/>
  <ws:rendition selector='.panel>.table-responsive'/>
  <ws:rendition selector='.panel>.table-responsive:first-child>.table:first-child,.panel>.table:first-child'/>
  <ws:rendition selector='.panel>.table-responsive:first-child>.table:first-child>tbody:first-child>tr:first-child td:first-child,.panel>.table-responsive:first-child>.table:first-child>tbody:first-child>tr:first-child th:first-child,.panel>.table-responsive:first-child>.table:first-child>thead:first-child>tr:first-child td:first-child,.panel>.table-responsive:first-child>.table:first-child>thead:first-child>tr:first-child th:first-child,.panel>.table:first-child>tbody:first-child>tr:first-child td:first-child,.panel>.table:first-child>tbody:first-child>tr:first-child th:first-child,.panel>.table:first-child>thead:first-child>tr:first-child td:first-child,.panel>.table:first-child>thead:first-child>tr:first-child th:first-child'/>
  <ws:rendition selector='.panel>.table-responsive:first-child>.table:first-child>tbody:first-child>tr:first-child td:last-child,.panel>.table-responsive:first-child>.table:first-child>tbody:first-child>tr:first-child th:last-child,.panel>.table-responsive:first-child>.table:first-child>thead:first-child>tr:first-child td:last-child,.panel>.table-responsive:first-child>.table:first-child>thead:first-child>tr:first-child th:last-child,.panel>.table:first-child>tbody:first-child>tr:first-child td:last-child,.panel>.table:first-child>tbody:first-child>tr:first-child th:last-child,.panel>.table:first-child>thead:first-child>tr:first-child td:last-child,.panel>.table:first-child>thead:first-child>tr:first-child th:last-child'/>
  <ws:rendition selector='.panel>.table-responsive:first-child>.table:first-child>tbody:first-child>tr:first-child,.panel>.table-responsive:first-child>.table:first-child>thead:first-child>tr:first-child,.panel>.table:first-child>tbody:first-child>tr:first-child,.panel>.table:first-child>thead:first-child>tr:first-child'/>
  <ws:rendition selector='.panel>.table-responsive:last-child>.table:last-child,.panel>.table:last-child'/>
  <ws:rendition selector='.panel>.table-responsive:last-child>.table:last-child>tbody:last-child>tr:last-child td:first-child,.panel>.table-responsive:last-child>.table:last-child>tbody:last-child>tr:last-child th:first-child,.panel>.table-responsive:last-child>.table:last-child>tfoot:last-child>tr:last-child td:first-child,.panel>.table-responsive:last-child>.table:last-child>tfoot:last-child>tr:last-child th:first-child,.panel>.table:last-child>tbody:last-child>tr:last-child td:first-child,.panel>.table:last-child>tbody:last-child>tr:last-child th:first-child,.panel>.table:last-child>tfoot:last-child>tr:last-child td:first-child,.panel>.table:last-child>tfoot:last-child>tr:last-child th:first-child'/>
  <ws:rendition selector='.panel>.table-responsive:last-child>.table:last-child>tbody:last-child>tr:last-child td:last-child,.panel>.table-responsive:last-child>.table:last-child>tbody:last-child>tr:last-child th:last-child,.panel>.table-responsive:last-child>.table:last-child>tfoot:last-child>tr:last-child td:last-child,.panel>.table-responsive:last-child>.table:last-child>tfoot:last-child>tr:last-child th:last-child,.panel>.table:last-child>tbody:last-child>tr:last-child td:last-child,.panel>.table:last-child>tbody:last-child>tr:last-child th:last-child,.panel>.table:last-child>tfoot:last-child>tr:last-child td:last-child,.panel>.table:last-child>tfoot:last-child>tr:last-child th:last-child'/>
  <ws:rendition selector='.panel>.table-responsive:last-child>.table:last-child>tbody:last-child>tr:last-child,.panel>.table-responsive:last-child>.table:last-child>tfoot:last-child>tr:last-child,.panel>.table:last-child>tbody:last-child>tr:last-child,.panel>.table:last-child>tfoot:last-child>tr:last-child'/>
  <ws:rendition selector='.panel>.table>tbody:first-child>tr:first-child td,.panel>.table>tbody:first-child>tr:first-child th'/>
  <ws:rendition selector='.placeholder_text,'/>
  <ws:rendition selector='.popover'/>
  <ws:rendition selector='.popover-content'/>
  <ws:rendition selector='.popover-title'/>
  <ws:rendition selector='.popover.bottom'/>
  <ws:rendition selector='.popover.bottom>.arrow'/>
  <ws:rendition selector='.popover.bottom>.arrow:after'/>
  <ws:rendition selector='.popover.left'/>
  <ws:rendition selector='.popover.left>.arrow'/>
  <ws:rendition selector='.popover.left>.arrow:after'/>
  <ws:rendition selector='.popover.right'/>
  <ws:rendition selector='.popover.right>.arrow'/>
  <ws:rendition selector='.popover.right>.arrow:after'/>
  <ws:rendition selector='.popover.top'/>
  <ws:rendition selector='.popover.top>.arrow'/>
  <ws:rendition selector='.popover.top>.arrow:after'/>
  <ws:rendition selector='.popover>.arrow'/>
  <ws:rendition selector='.popover>.arrow,.popover>.arrow:after'/>
  <ws:rendition selector='.popover>.arrow:after'/>
  <ws:rendition selector='.pre-scrollable'/>
  <ws:rendition selector='.progress'/>
  <ws:rendition selector='.progress-bar'/>
  <ws:rendition selector='.progress-bar-danger'/>
  <ws:rendition selector='.progress-bar-info'/>
  <ws:rendition selector='.progress-bar-striped,.progress-striped .progress-bar'/>
  <ws:rendition selector='.progress-bar-success'/>
  <ws:rendition selector='.progress-bar-warning'/>
  <ws:rendition selector='.progress-bar.active,.progress.active .progress-bar'/>
  <ws:rendition selector='.progress-striped .progress-bar-danger'/>
  <ws:rendition selector='.progress-striped .progress-bar-info'/>
  <ws:rendition selector='.progress-striped .progress-bar-success'/>
  <ws:rendition selector='.progress-striped .progress-bar-warning'/>
  <ws:rendition selector='.pull-left'/>
  <ws:rendition selector='.pull-right'/>
  <ws:rendition selector='.pull-right>.dropdown-menu'/>
  <ws:rendition selector='.red '/>
  <ws:rendition selector='.resetbutton '/>
  <ws:rendition selector='.result '/>
  <ws:rendition selector='.resultprelims, .resultinstances, .resultfurthersearch '/>
  <ws:rendition selector='.row'/>
  <ws:rendition selector='.searchbibl '/>
  <ws:rendition selector='.searchbutton '/>
  <ws:rendition selector='.searchfieldcat '/>
  <ws:rendition selector='.searchfieldclmn1, .searchfieldclmn2, .searchfieldclmn3 '/>
  <ws:rendition selector='.searchhelp '/>
  <ws:rendition selector='.searchnote '/>
  <ws:rendition selector='.separator '/>
  <ws:rendition selector='.show'/>
  <ws:rendition selector='.small,small'/>
  <ws:rendition selector='.sr-only'/>
  <ws:rendition selector='.sr-only-focusable:active,.sr-only-focusable:focus'/>
  <ws:rendition selector='.static-pg '/>
  <ws:rendition selector='.static-pg#api .h2 '/>
  <ws:rendition selector='.static-pg#api dl '/>
  <ws:rendition selector='.static-pg#api dl dd '/>
  <ws:rendition selector='.static-pg#api dl dt '/>
  <ws:rendition selector='.static-pg#api dl dt p '/>
  <ws:rendition selector='.static-pg#api h2,'/>
  <ws:rendition selector='.static-pg#api table '/>
  <ws:rendition selector='.static-pg#cor-home '/>
  <ws:rendition selector='.storyjs-embed'/>
  <ws:rendition selector='.storyjs-embed.full-embed'/>
  <ws:rendition selector='.storyjs-embed.full-embed .vco-feature'/>
  <ws:rendition selector='.storyjs-embed.sized-embed'/>
  <ws:rendition selector='.tab-content '/>
  <ws:rendition selector='.tab-content>.active'/>
  <ws:rendition selector='.tab-content>.tab-pane'/>
  <ws:rendition selector='.tabRef '/>
  <ws:rendition selector='.table'/>
  <ws:rendition selector='.table .table'/>
  <ws:rendition selector='.table td,.table th'/>
  <ws:rendition selector='.table-bordered'/>
  <ws:rendition selector='.table-bordered td,.table-bordered th'/>
  <ws:rendition selector='.table-bordered>tbody>tr>td,.table-bordered>tbody>tr>th,.table-bordered>tfoot>tr>td,.table-bordered>tfoot>tr>th,.table-bordered>thead>tr>td,.table-bordered>thead>tr>th'/>
  <ws:rendition selector='.table-bordered>thead>tr>td,.table-bordered>thead>tr>th'/>
  <ws:rendition selector='.table-condensed>tbody>tr>td,.table-condensed>tbody>tr>th,.table-condensed>tfoot>tr>td,.table-condensed>tfoot>tr>th,.table-condensed>thead>tr>td,.table-condensed>thead>tr>th'/>
  <ws:rendition selector='.table-hover>tbody>tr.active:hover>td,.table-hover>tbody>tr.active:hover>th,.table-hover>tbody>tr:hover>.active,.table-hover>tbody>tr>td.active:hover,.table-hover>tbody>tr>th.active:hover'/>
  <ws:rendition selector='.table-hover>tbody>tr.danger:hover>td,.table-hover>tbody>tr.danger:hover>th,.table-hover>tbody>tr:hover>.danger,.table-hover>tbody>tr>td.danger:hover,.table-hover>tbody>tr>th.danger:hover'/>
  <ws:rendition selector='.table-hover>tbody>tr.info:hover>td,.table-hover>tbody>tr.info:hover>th,.table-hover>tbody>tr:hover>.info,.table-hover>tbody>tr>td.info:hover,.table-hover>tbody>tr>th.info:hover'/>
  <ws:rendition selector='.table-hover>tbody>tr.success:hover>td,.table-hover>tbody>tr.success:hover>th,.table-hover>tbody>tr:hover>.success,.table-hover>tbody>tr>td.success:hover,.table-hover>tbody>tr>th.success:hover'/>
  <ws:rendition selector='.table-hover>tbody>tr.warning:hover>td,.table-hover>tbody>tr.warning:hover>th,.table-hover>tbody>tr:hover>.warning,.table-hover>tbody>tr>td.warning:hover,.table-hover>tbody>tr>th.warning:hover'/>
  <ws:rendition selector='.table-hover>tbody>tr:hover'/>
  <ws:rendition selector='.table-responsive'/>
  <ws:rendition selector='.table-responsive>.table'/>
  <ws:rendition selector='.table-responsive>.table-bordered'/>
  <ws:rendition selector='.table-responsive>.table-bordered>tbody>tr:last-child>td,.table-responsive>.table-bordered>tbody>tr:last-child>th,.table-responsive>.table-bordered>tfoot>tr:last-child>td,.table-responsive>.table-bordered>tfoot>tr:last-child>th'/>
  <ws:rendition selector='.table-responsive>.table-bordered>tbody>tr>td:first-child,.table-responsive>.table-bordered>tbody>tr>th:first-child,.table-responsive>.table-bordered>tfoot>tr>td:first-child,.table-responsive>.table-bordered>tfoot>tr>th:first-child,.table-responsive>.table-bordered>thead>tr>td:first-child,.table-responsive>.table-bordered>thead>tr>th:first-child'/>
  <ws:rendition selector='.table-responsive>.table-bordered>tbody>tr>td:last-child,.table-responsive>.table-bordered>tbody>tr>th:last-child,.table-responsive>.table-bordered>tfoot>tr>td:last-child,.table-responsive>.table-bordered>tfoot>tr>th:last-child,.table-responsive>.table-bordered>thead>tr>td:last-child,.table-responsive>.table-bordered>thead>tr>th:last-child'/>
  <ws:rendition selector='.table-responsive>.table>tbody>tr>td,.table-responsive>.table>tbody>tr>th,.table-responsive>.table>tfoot>tr>td,.table-responsive>.table>tfoot>tr>th,.table-responsive>.table>thead>tr>td,.table-responsive>.table>thead>tr>th'/>
  <ws:rendition selector='.table-striped>tbody>tr:nth-of-type(odd)'/>
  <ws:rendition selector='.table>caption+thead>tr:first-child>td,.table>caption+thead>tr:first-child>th,.table>colgroup+thead>tr:first-child>td,.table>colgroup+thead>tr:first-child>th,.table>thead:first-child>tr:first-child>td,.table>thead:first-child>tr:first-child>th'/>
  <ws:rendition selector='.table>tbody+tbody'/>
  <ws:rendition selector='.table>tbody>tr.active>td,.table>tbody>tr.active>th,.table>tbody>tr>td.active,.table>tbody>tr>th.active,.table>tfoot>tr.active>td,.table>tfoot>tr.active>th,.table>tfoot>tr>td.active,.table>tfoot>tr>th.active,.table>thead>tr.active>td,.table>thead>tr.active>th,.table>thead>tr>td.active,.table>thead>tr>th.active'/>
  <ws:rendition selector='.table>tbody>tr.danger>td,.table>tbody>tr.danger>th,.table>tbody>tr>td.danger,.table>tbody>tr>th.danger,.table>tfoot>tr.danger>td,.table>tfoot>tr.danger>th,.table>tfoot>tr>td.danger,.table>tfoot>tr>th.danger,.table>thead>tr.danger>td,.table>thead>tr.danger>th,.table>thead>tr>td.danger,.table>thead>tr>th.danger'/>
  <ws:rendition selector='.table>tbody>tr.info>td,.table>tbody>tr.info>th,.table>tbody>tr>td.info,.table>tbody>tr>th.info,.table>tfoot>tr.info>td,.table>tfoot>tr.info>th,.table>tfoot>tr>td.info,.table>tfoot>tr>th.info,.table>thead>tr.info>td,.table>thead>tr.info>th,.table>thead>tr>td.info,.table>thead>tr>th.info'/>
  <ws:rendition selector='.table>tbody>tr.success>td,.table>tbody>tr.success>th,.table>tbody>tr>td.success,.table>tbody>tr>th.success,.table>tfoot>tr.success>td,.table>tfoot>tr.success>th,.table>tfoot>tr>td.success,.table>tfoot>tr>th.success,.table>thead>tr.success>td,.table>thead>tr.success>th,.table>thead>tr>td.success,.table>thead>tr>th.success'/>
  <ws:rendition selector='.table>tbody>tr.warning>td,.table>tbody>tr.warning>th,.table>tbody>tr>td.warning,.table>tbody>tr>th.warning,.table>tfoot>tr.warning>td,.table>tfoot>tr.warning>th,.table>tfoot>tr>td.warning,.table>tfoot>tr>th.warning,.table>thead>tr.warning>td,.table>thead>tr.warning>th,.table>thead>tr>td.warning,.table>thead>tr>th.warning'/>
  <ws:rendition selector='.table>tbody>tr>td,.table>tbody>tr>th,.table>tfoot>tr>td,.table>tfoot>tr>th,.table>thead>tr>td,.table>thead>tr>th'/>
  <ws:rendition selector='.table>thead>tr>th'/>
  <ws:rendition selector='.text-capitalize'/>
  <ws:rendition selector='.text-center'/>
  <ws:rendition selector='.text-danger'/>
  <ws:rendition selector='.text-hide'/>
  <ws:rendition selector='.text-info'/>
  <ws:rendition selector='.text-italic '/>
  <ws:rendition selector='.text-justify'/>
  <ws:rendition selector='.text-left'/>
  <ws:rendition selector='.text-lowercase'/>
  <ws:rendition selector='.text-muted'/>
  <ws:rendition selector='.text-nowrap'/>
  <ws:rendition selector='.text-primary'/>
  <ws:rendition selector='.text-right'/>
  <ws:rendition selector='.text-success'/>
  <ws:rendition selector='.text-uppercase'/>
  <ws:rendition selector='.text-warning'/>
  <ws:rendition selector='.textListTD1 '/>
  <ws:rendition selector='.textListTD1, .textListTD2, .textListTD3, .textListTD4, .textListTD5, .textListTD5Grey, .textListTD5Blank '/>
  <ws:rendition selector='.textListTD2 '/>
  <ws:rendition selector='.textListTD3 '/>
  <ws:rendition selector='.textListTD4 '/>
  <ws:rendition selector='.textListTD5 '/>
  <ws:rendition selector='.textListTD5Blank '/>
  <ws:rendition selector='.textListTD5Grey '/>
  <ws:rendition selector='.thread.context .tooltip-inner '/>
  <ws:rendition selector='.thread.context .tooltip.bottom .tooltip-arrow '/>
  <ws:rendition selector='.thread.context .tooltip.left .tooltip-arrow,'/>
  <ws:rendition selector='.thread.context .tooltip.right .tooltip-arrow,'/>
  <ws:rendition selector='.thread.context .tooltip.top .tooltip-arrow,'/>
  <ws:rendition selector='.thread.note .tooltip-inner '/>
  <ws:rendition selector='.thread.note .tooltip.bottom .tooltip-arrow '/>
  <ws:rendition selector='.thread.note .tooltip.left .tooltip-arrow,'/>
  <ws:rendition selector='.thread.note .tooltip.right .tooltip-arrow,'/>
  <ws:rendition selector='.thread.note .tooltip.top .tooltip-arrow,'/>
  <ws:rendition selector='.thread.person .tooltip-inner '/>
  <ws:rendition selector='.thread.person .tooltip.bottom .tooltip-arrow '/>
  <ws:rendition selector='.thread.person .tooltip.left .tooltip-arrow,'/>
  <ws:rendition selector='.thread.person .tooltip.right .tooltip-arrow,'/>
  <ws:rendition selector='.thread.person .tooltip.top .tooltip-arrow,'/>
  <ws:rendition selector='.thumbnail'/>
  <ws:rendition selector='.thumbnail .caption'/>
  <ws:rendition selector='.thumbnail a>img,.thumbnail>img'/>
  <ws:rendition selector='.title '/>
  <ws:rendition selector='.toggleable '/>
  <ws:rendition selector='.toggleable div.example '/>
  <ws:rendition selector='.tooltip'/>
  <ws:rendition selector='.tooltip '/>
  <ws:rendition selector='.tooltip-arrow'/>
  <ws:rendition selector='.tooltip-arrow '/>
  <ws:rendition selector='.tooltip-inner'/>
  <ws:rendition selector='.tooltip-inner '/>
  <ws:rendition selector='.tooltip.bottom'/>
  <ws:rendition selector='.tooltip.bottom '/>
  <ws:rendition selector='.tooltip.bottom .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.bottom .tooltip-arrow '/>
  <ws:rendition selector='.tooltip.bottom-left .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.bottom-right .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.in'/>
  <ws:rendition selector='.tooltip.in '/>
  <ws:rendition selector='.tooltip.left'/>
  <ws:rendition selector='.tooltip.left '/>
  <ws:rendition selector='.tooltip.left .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.left .tooltip-arrow '/>
  <ws:rendition selector='.tooltip.right'/>
  <ws:rendition selector='.tooltip.right '/>
  <ws:rendition selector='.tooltip.right .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.right .tooltip-arrow '/>
  <ws:rendition selector='.tooltip.top'/>
  <ws:rendition selector='.tooltip.top '/>
  <ws:rendition selector='.tooltip.top .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.top .tooltip-arrow '/>
  <ws:rendition selector='.tooltip.top-left .tooltip-arrow'/>
  <ws:rendition selector='.tooltip.top-right .tooltip-arrow'/>
  <ws:rendition selector='.tooltip:first-letter '/>
  <ws:rendition selector='.ui-dialog '/>
  <ws:rendition selector='.ui-dialog-content '/>
  <ws:rendition selector='.ui-dialog-titlebar '/>
  <ws:rendition selector='.ui-dialog-titlebar-close '/>
  <ws:rendition selector='.ui-slider '/>
  <ws:rendition selector='.ui-slider .ui-slider-handle '/>
  <ws:rendition selector='.ui-slider .ui-slider-handle:focus '/>
  <ws:rendition selector='.ui-slider .ui-slider-range '/>
  <ws:rendition selector='.ui-widget-overlay '/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small.flag-small-last:hover'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small.flag-small-last:hover .flag-content'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small.flag-small-last:hover .flag-content h3'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover .flag-content'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover .flag-content h3'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag:hover'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag:hover .flag-content .thumbnail,.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover .flag-content .thumbnail'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag:hover .flag-content h3,.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover .flag-content h3'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag:hover .flag-content h4,.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover .flag-content h4'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker .flag:hover,.vco-notouch .vco-navigation .timenav .content .marker .flag-small:hover'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker.active:hover'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker.active:hover .flag .flag-content h3,.vco-notouch .vco-navigation .timenav .content .marker.active:hover .flag-small .flag-content h3'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker.active:hover .flag .flag-content h4,.vco-notouch .vco-navigation .timenav .content .marker.active:hover .flag-small .flag-content h4'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .timenav .content .marker:hover .line'/>
  <ws:rendition selector='.vco-notouch .vco-navigation .vco-toolbar .zoom-in:hover,.vco-notouch .vco-navigation .vco-toolbar .zoom-out:hover,.vco-notouch .vco-navigation .vco-toolbar .back-home:hover'/>
  <ws:rendition selector='.vco-notouch .vco-slider .nav-next:hover .icon'/>
  <ws:rendition selector='.vco-notouch .vco-slider .nav-previous:hover .icon'/>
  <ws:rendition selector='.vco-notouch .vco-slider .nav-previous:hover,.vco-notouch .vco-slider .nav-next:hover'/>
  <ws:rendition selector='.vco-notouch .vco-slider .slider-item .content .content-container .created-at:hover'/>
  <ws:rendition selector='.vco-notouch .vco-slider .slider-item .content .content-container .googleplus .googleplus-content .googleplus-attachments a:hover'/>
  <ws:rendition selector='.vco-notouch .vco-slider .slider-item .content .content-container .googleplus .googleplus-content .googleplus-attachments a:hover h5'/>
  <ws:rendition selector='.vco-notouch .vco-slider .slider-item .content .content-container .media .media-container .wikipedia h4 a:hover'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .content-container'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .content-container .media'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .content-container .media .media-wrapper'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .content-container .text'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .content-container .text .container'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .layout-text-media .text .container'/>
  <ws:rendition selector='.vco-skinny .vco-slider .slider-item .content .layout-text-media h2,.vco-skinny .vco-slider .slider-item .content .layout-text-media h3'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-next .icon'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous .icon'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-next .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-previous .nav-container .title,.vco-skinny.vco-notouch .vco-slider .nav-next .nav-container .title'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous .nav-container .icon,.vco-skinny.vco-notouch .vco-slider .nav-next .nav-container .icon'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous,.vco-skinny.vco-notouch .vco-slider .nav-next'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .title,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .title'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .icon,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .icon,.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .date,.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .title,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .title'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous:hover .nav-container .title,.vco-skinny.vco-notouch .vco-slider .nav-next:hover .nav-container .title'/>
  <ws:rendition selector='.vco-skinny.vco-notouch .vco-slider .nav-previous:hover,.vco-skinny.vco-notouch .vco-slider .nav-next:hover'/>
  <ws:rendition selector='.vco-slider'/>
  <ws:rendition selector='.vco-slider .nav-next'/>
  <ws:rendition selector='.vco-slider .nav-next .date,.vco-slider .nav-next .title'/>
  <ws:rendition selector='.vco-slider .nav-next .icon'/>
  <ws:rendition selector='.vco-slider .nav-previous'/>
  <ws:rendition selector='.vco-slider .nav-previous .date a,.vco-slider .nav-next .date a,.vco-slider .nav-previous .title a,.vco-slider .nav-next .title a'/>
  <ws:rendition selector='.vco-slider .nav-previous .date small,.vco-slider .nav-next .date small,.vco-slider .nav-previous .title small,.vco-slider .nav-next .title small'/>
  <ws:rendition selector='.vco-slider .nav-previous .date,.vco-slider .nav-next .date'/>
  <ws:rendition selector='.vco-slider .nav-previous .date,.vco-slider .nav-next .date,.vco-slider .nav-previous .title,.vco-slider .nav-next .title'/>
  <ws:rendition selector='.vco-slider .nav-previous .date,.vco-slider .nav-previous .title'/>
  <ws:rendition selector='.vco-slider .nav-previous .icon'/>
  <ws:rendition selector='.vco-slider .nav-previous .icon,.vco-slider .nav-next .icon'/>
  <ws:rendition selector='.vco-slider .nav-previous .nav-container,.vco-slider .nav-next .nav-container'/>
  <ws:rendition selector='.vco-slider .nav-previous .title,.vco-slider .nav-next .title'/>
  <ws:rendition selector='.vco-slider .nav-previous,.vco-slider .nav-next'/>
  <ws:rendition selector='.vco-slider .slider-container-mask'/>
  <ws:rendition selector='.vco-slider .slider-container-mask .slider-container'/>
  <ws:rendition selector='.vco-slider .slider-container-mask .slider-container .slider-item-container'/>
  <ws:rendition selector='.vco-slider .slider-item'/>
  <ws:rendition selector='.vco-slider .slider-item .content'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .caption'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .credit'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map .google-map'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map .map-attribution'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map .map-attribution .attribution-text'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map .map-attribution .attribution-text a'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .map img'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-frame iframe'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-frame,.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-image img'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-image'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-shadow'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-shadow::after'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-shadow:before,.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .media-shadow:after'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .plain-text'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .plain-text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .plain-text .container p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .soundcloud'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .wikipedia'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .wikipedia .wiki-source'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .wikipedia h4'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .wikipedia h4 a'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .media .media-wrapper .media-container .wikipedia p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .text'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .text .container .slide-tag'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .text .container h2.date'/>
  <ws:rendition selector='.vco-slider .slider-item .content .content-container .text .container p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .created-at'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .created-at'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-annotation'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments div'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments h5'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments img'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments:after'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments:before,.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-attachments:after'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content .googleplus-title'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .googleplus-content p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .googleplus .proflinkPrefix'/>
  <ws:rendition selector='.vco-slider .slider-item .content .media.text-media .media-wrapper .media-container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .pad-left .media.text-media .media-wrapper .media-container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .pad-left .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .pad-right .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .pad-top .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content .storify .created-at'/>
  <ws:rendition selector='.vco-slider .slider-item .content .twitter .created-at'/>
  <ws:rendition selector='.vco-slider .slider-item .content .twitter blockquote .quote-mark,.vco-slider .slider-item .content .plain-text-quote blockquote .quote-mark,.vco-slider .slider-item .content .storify blockquote .quote-mark,.vco-slider .slider-item .content .googleplus blockquote .quote-mark'/>
  <ws:rendition selector='.vco-slider .slider-item .content .twitter blockquote p,.vco-slider .slider-item .content .plain-text-quote blockquote p,.vco-slider .slider-item .content .storify blockquote p,.vco-slider .slider-item .content .googleplus blockquote p'/>
  <ws:rendition selector='.vco-slider .slider-item .content .twitter blockquote,.vco-slider .slider-item .content .plain-text-quote blockquote,.vco-slider .slider-item .content .storify blockquote,.vco-slider .slider-item .content .googleplus blockquote'/>
  <ws:rendition selector='.vco-slider .slider-item .content .twitter,.vco-slider .slider-item .content .plain-text-quote,.vco-slider .slider-item .content .storify,.vco-slider .slider-item .content .googleplus'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media .media'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media .media .media-wrapper .media-container'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media .text'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-media .twitter,.vco-slider .slider-item .content-container.layout-media .wikipedia,.vco-slider .slider-item .content-container.layout-media .googleplus'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-text'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-text .text'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-text .text .container'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-text-media .text-media'/>
  <ws:rendition selector='.vco-slider .slider-item .content-container.layout-text-media.pad-left .text-media'/>
  <ws:rendition selector='.vco-slider img,.vco-slider embed,.vco-slider object,.vco-slider video,.vco-slider iframe'/>
  <ws:rendition selector='.vco-storyjs'/>
  <ws:rendition selector='.vco-storyjs .caption'/>
  <ws:rendition selector='.vco-storyjs .credit'/>
  <ws:rendition selector='.vco-storyjs .date a,.vco-storyjs .title a'/>
  <ws:rendition selector='.vco-storyjs .googleplus .thumbnail-inline'/>
  <ws:rendition selector='.vco-storyjs .hyphenate'/>
  <ws:rendition selector='.vco-storyjs .storify .thumbnail-inline'/>
  <ws:rendition selector='.vco-storyjs .thumb-storify-full'/>
  <ws:rendition selector='.vco-storyjs .thumbnail'/>
  <ws:rendition selector='.vco-storyjs .thumbnail-inline'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-audio'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-document'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-googleplus'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-link'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-map'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-photo'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-photo img'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-plaintext'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-quote'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-storify'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-twitter'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-video'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-vimeo'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-website'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-wikipedia'/>
  <ws:rendition selector='.vco-storyjs .thumbnail.thumb-youtube'/>
  <ws:rendition selector='.vco-storyjs .timenav h1,.vco-storyjs .flag-content h1,.vco-storyjs .era h1,.vco-storyjs .timenav h2,.vco-storyjs .flag-content h2,.vco-storyjs .era h2,.vco-storyjs .timenav h3,.vco-storyjs .flag-content h3,.vco-storyjs .era h3,.vco-storyjs .timenav h4,.vco-storyjs .flag-content h4,.vco-storyjs .era h4,.vco-storyjs .timenav h5,.vco-storyjs .flag-content h5,.vco-storyjs .era h5,.vco-storyjs .timenav h6,.vco-storyjs .flag-content h6,.vco-storyjs .era h6'/>
  <ws:rendition selector='.vco-storyjs .twitter .thumbnail-inline'/>
  <ws:rendition selector='.vco-storyjs .twitter,.vco-storyjs .vcard,.vco-storyjs .messege,.vco-storyjs .credit,.vco-storyjs .caption,.vco-storyjs .zoom-in,.vco-storyjs .zoom-out,.vco-storyjs .back-home,.vco-storyjs .time-interval div,.vco-storyjs .time-interval-major div,.vco-storyjs .nav-container'/>
  <ws:rendition selector='.vco-storyjs .vcard'/>
  <ws:rendition selector='.vco-storyjs .vcard .avatar'/>
  <ws:rendition selector='.vco-storyjs .vcard .avatar img'/>
  <ws:rendition selector='.vco-storyjs .vcard .fn'/>
  <ws:rendition selector='.vco-storyjs .vcard .fn,.vco-storyjs .vcard .nickname'/>
  <ws:rendition selector='.vco-storyjs .vcard .nickname'/>
  <ws:rendition selector='.vco-storyjs .vcard a'/>
  <ws:rendition selector='.vco-storyjs .vcard a:hover'/>
  <ws:rendition selector='.vco-storyjs .vcard a:hover .fn'/>
  <ws:rendition selector='.vco-storyjs .vco-bezel'/>
  <ws:rendition selector='.vco-storyjs .vco-bezel .vco-message,.vco-storyjs .vco-bezel .vco-message p'/>
  <ws:rendition selector='.vco-storyjs .vco-container.vco-main'/>
  <ws:rendition selector='.vco-storyjs .vco-feature'/>
  <ws:rendition selector='.vco-storyjs .vco-feature .slider,.vco-storyjs .vco-feature .vco-slider'/>
  <ws:rendition selector='.vco-storyjs .vco-feature blockquote,.vco-storyjs .vco-feature blockquote p'/>
  <ws:rendition selector='.vco-storyjs .vco-feature h1,.vco-storyjs .vco-feature h2,.vco-storyjs .vco-feature h3,.vco-storyjs .vco-feature h4,.vco-storyjs .vco-feature h5,.vco-storyjs .vco-feature h6'/>
  <ws:rendition selector='.vco-storyjs .vco-feature h3,.vco-storyjs .vco-feature h4,.vco-storyjs .vco-feature h5,.vco-storyjs .vco-feature h6'/>
  <ws:rendition selector='.vco-storyjs .vco-feature p'/>
  <ws:rendition selector='.vco-storyjs .vco-feedback'/>
  <ws:rendition selector='.vco-storyjs .vco-navigation p'/>
  <ws:rendition selector='.vco-storyjs .vmm-clear'/>
  <ws:rendition selector='.vco-storyjs .vmm-clear:after'/>
  <ws:rendition selector='.vco-storyjs .vmm-clear:before,.vco-storyjs .vmm-clear:after'/>
  <ws:rendition selector='.vco-storyjs .zFront'/>
  <ws:rendition selector='.vco-storyjs Q'/>
  <ws:rendition selector='.vco-storyjs a'/>
  <ws:rendition selector='.vco-storyjs a.thumbnail:hover'/>
  <ws:rendition selector='.vco-storyjs a:focus'/>
  <ws:rendition selector='.vco-storyjs a:hover'/>
  <ws:rendition selector='.vco-storyjs a:hover,.vco-storyjs a:active'/>
  <ws:rendition selector='.vco-storyjs article,.vco-storyjs aside,.vco-storyjs details,.vco-storyjs figcaption,.vco-storyjs figure,.vco-storyjs footer,.vco-storyjs header,.vco-storyjs hgroup,.vco-storyjs nav,.vco-storyjs section'/>
  <ws:rendition selector='.vco-storyjs audio,.vco-storyjs canvas,.vco-storyjs video'/>
  <ws:rendition selector='.vco-storyjs audio:not([controls])'/>
  <ws:rendition selector='.vco-storyjs blockquote,.vco-storyjs blockquote p'/>
  <ws:rendition selector='.vco-storyjs button,.vco-storyjs input'/>
  <ws:rendition selector='.vco-storyjs button,.vco-storyjs input,.vco-storyjs select,.vco-storyjs textarea'/>
  <ws:rendition selector='.vco-storyjs button,.vco-storyjs input[type="button"],.vco-storyjs input[type="reset"],.vco-storyjs input[type="submit"]'/>
  <ws:rendition selector='.vco-storyjs button::-moz-focus-inner,.vco-storyjs input::-moz-focus-inner'/>
  <ws:rendition selector='.vco-storyjs div'/>
  <ws:rendition selector='.vco-storyjs div *'/>
  <ws:rendition selector='.vco-storyjs div.vco-explainer'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading .vco-loading-container .vco-gesture-icon,.vco-storyjs div.vco-explainer .vco-loading-container .vco-gesture-icon,.vco-storyjs div.vco-loading .vco-explainer-container .vco-gesture-icon,.vco-storyjs div.vco-explainer .vco-explainer-container .vco-gesture-icon'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading .vco-loading-container .vco-loading-icon,.vco-storyjs div.vco-explainer .vco-loading-container .vco-loading-icon,.vco-storyjs div.vco-loading .vco-explainer-container .vco-loading-icon,.vco-storyjs div.vco-explainer .vco-explainer-container .vco-loading-icon'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading .vco-loading-container .vco-message,.vco-storyjs div.vco-explainer .vco-loading-container .vco-message,.vco-storyjs div.vco-loading .vco-explainer-container .vco-message,.vco-storyjs div.vco-explainer .vco-explainer-container .vco-message'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading .vco-loading-container .vco-message,.vco-storyjs div.vco-explainer .vco-loading-container .vco-message,.vco-storyjs div.vco-loading .vco-explainer-container .vco-message,.vco-storyjs div.vco-explainer .vco-explainer-container .vco-message,.vco-storyjs div.vco-loading .vco-loading-container .vco-message p,.vco-storyjs div.vco-explainer .vco-loading-container .vco-message p,.vco-storyjs div.vco-loading .vco-explainer-container .vco-message p,.vco-storyjs div.vco-explainer .vco-explainer-container .vco-message p'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading .vco-loading-container,.vco-storyjs div.vco-explainer .vco-loading-container,.vco-storyjs div.vco-loading .vco-explainer-container,.vco-storyjs div.vco-explainer .vco-explainer-container'/>
  <ws:rendition selector='.vco-storyjs div.vco-loading,.vco-storyjs div.vco-explainer'/>
  <ws:rendition selector='.vco-storyjs em'/>
  <ws:rendition selector='.vco-storyjs h1'/>
  <ws:rendition selector='.vco-storyjs h1 a,.vco-storyjs h2 a,.vco-storyjs h3 a,.vco-storyjs h4 a,.vco-storyjs h5 a,.vco-storyjs h6 a'/>
  <ws:rendition selector='.vco-storyjs h1 small'/>
  <ws:rendition selector='.vco-storyjs h1 small,.vco-storyjs h2 small,.vco-storyjs h3 small,.vco-storyjs h4 small,.vco-storyjs h5 small,.vco-storyjs h6 small'/>
  <ws:rendition selector='.vco-storyjs h1,.vco-storyjs h2,.vco-storyjs h3,.vco-storyjs h4,.vco-storyjs h5,.vco-storyjs h6'/>
  <ws:rendition selector='.vco-storyjs h1,.vco-storyjs h2,.vco-storyjs h3,.vco-storyjs h4,.vco-storyjs h5,.vco-storyjs h6,.vco-storyjs p,.vco-storyjs blockquote,.vco-storyjs pre,.vco-storyjs a,.vco-storyjs abbr,.vco-storyjs acronym,.vco-storyjs address,.vco-storyjs cite,.vco-storyjs code,.vco-storyjs del,.vco-storyjs dfn,.vco-storyjs em,.vco-storyjs img,.vco-storyjs q,.vco-storyjs s,.vco-storyjs samp,.vco-storyjs small,.vco-storyjs strike,.vco-storyjs strong,.vco-storyjs sub,.vco-storyjs sup,.vco-storyjs tt,.vco-storyjs var,.vco-storyjs dd,.vco-storyjs dl,.vco-storyjs dt,.vco-storyjs li,.vco-storyjs ol,.vco-storyjs ul,.vco-storyjs fieldset,.vco-storyjs form,.vco-storyjs label,.vco-storyjs legend,.vco-storyjs button,.vco-storyjs table,.vco-storyjs caption,.vco-storyjs tbody,.vco-storyjs tfoot,.vco-storyjs thead,.vco-storyjs tr,.vco-storyjs th,.vco-storyjs td,.vco-storyjs .vco-container,.vco-storyjs .content-container,.vco-storyjs .media,.vco-storyjs .text,.vco-storyjs .vco-slider,.vco-storyjs .slider,.vco-storyjs .date,.vco-storyjs .title,.vco-storyjs .messege,.vco-storyjs .map,.vco-storyjs .credit,.vco-storyjs .caption,.vco-storyjs .vco-feedback,.vco-storyjs .vco-feature,.vco-storyjs .toolbar,.vco-storyjs .marker,.vco-storyjs .dot,.vco-storyjs .line,.vco-storyjs .flag,.vco-storyjs .time,.vco-storyjs .era,.vco-storyjs .major,.vco-storyjs .minor,.vco-storyjs .vco-navigation,.vco-storyjs .start,.vco-storyjs .active'/>
  <ws:rendition selector='.vco-storyjs h1.date,.vco-storyjs h2.date,.vco-storyjs h3.date,.vco-storyjs h4.date,.vco-storyjs h5.date,.vco-storyjs h6.date'/>
  <ws:rendition selector='.vco-storyjs h2'/>
  <ws:rendition selector='.vco-storyjs h2 small'/>
  <ws:rendition selector='.vco-storyjs h2.date'/>
  <ws:rendition selector='.vco-storyjs h2.start'/>
  <ws:rendition selector='.vco-storyjs h3'/>
  <ws:rendition selector='.vco-storyjs h3 .active,.vco-storyjs h4 .active,.vco-storyjs h5 .active,.vco-storyjs h6 .active'/>
  <ws:rendition selector='.vco-storyjs h3 small'/>
  <ws:rendition selector='.vco-storyjs h3,.vco-storyjs h4,.vco-storyjs h5,.vco-storyjs h6'/>
  <ws:rendition selector='.vco-storyjs h4'/>
  <ws:rendition selector='.vco-storyjs h4 small'/>
  <ws:rendition selector='.vco-storyjs h5'/>
  <ws:rendition selector='.vco-storyjs h6'/>
  <ws:rendition selector='.vco-storyjs img'/>
  <ws:rendition selector='.vco-storyjs img,.vco-storyjs embed,.vco-storyjs object,.vco-storyjs video,.vco-storyjs iframe'/>
  <ws:rendition selector='.vco-storyjs input[type="search"]'/>
  <ws:rendition selector='.vco-storyjs input[type="search"]::-webkit-search-decoration'/>
  <ws:rendition selector='.vco-storyjs ol,.vco-storyjs ul'/>
  <ws:rendition selector='.vco-storyjs p'/>
  <ws:rendition selector='.vco-storyjs p small'/>
  <ws:rendition selector='.vco-storyjs p,.vco-storyjs blockquote,.vco-storyjs blockquote p,.vco-storyjs .twitter blockquote p'/>
  <ws:rendition selector='.vco-storyjs p:first-child'/>
  <ws:rendition selector='.vco-storyjs q:before,.vco-storyjs q:after,.vco-storyjs blockquote:before,.vco-storyjs blockquote:after'/>
  <ws:rendition selector='.vco-storyjs strong'/>
  <ws:rendition selector='.vco-storyjs sub'/>
  <ws:rendition selector='.vco-storyjs sub,.vco-storyjs sup'/>
  <ws:rendition selector='.vco-storyjs sup'/>
  <ws:rendition selector='.vco-storyjs table'/>
  <ws:rendition selector='.vco-storyjs textarea'/>
  <ws:rendition selector='.vco-storyjs thumbnail.thumb-instagram'/>
  <ws:rendition selector='.vco-storyjs thumbnail.thumb-instagram-full'/>
  <ws:rendition selector='.vco-storyjs.vco-right-to-left h1,.vco-storyjs.vco-right-to-left h2,.vco-storyjs.vco-right-to-left h3,.vco-storyjs.vco-right-to-left h4,.vco-storyjs.vco-right-to-left h5,.vco-storyjs.vco-right-to-left h6,.vco-storyjs.vco-right-to-left p,.vco-storyjs.vco-right-to-left blockquote,.vco-storyjs.vco-right-to-left pre,.vco-storyjs.vco-right-to-left a,.vco-storyjs.vco-right-to-left abbr,.vco-storyjs.vco-right-to-left acronym,.vco-storyjs.vco-right-to-left address,.vco-storyjs.vco-right-to-left cite,.vco-storyjs.vco-right-to-left code,.vco-storyjs.vco-right-to-left del,.vco-storyjs.vco-right-to-left dfn,.vco-storyjs.vco-right-to-left em,.vco-storyjs.vco-right-to-left img,.vco-storyjs.vco-right-to-left q,.vco-storyjs.vco-right-to-left s,.vco-storyjs.vco-right-to-left samp,.vco-storyjs.vco-right-to-left small,.vco-storyjs.vco-right-to-left strike,.vco-storyjs.vco-right-to-left strong,.vco-storyjs.vco-right-to-left sub,.vco-storyjs.vco-right-to-left sup,.vco-storyjs.vco-right-to-left tt,.vco-storyjs.vco-right-to-left var,.vco-storyjs.vco-right-to-left dd,.vco-storyjs.vco-right-to-left dl,.vco-storyjs.vco-right-to-left dt,.vco-storyjs.vco-right-to-left li,.vco-storyjs.vco-right-to-left ol,.vco-storyjs.vco-right-to-left ul,.vco-storyjs.vco-right-to-left fieldset,.vco-storyjs.vco-right-to-left form,.vco-storyjs.vco-right-to-left label,.vco-storyjs.vco-right-to-left legend,.vco-storyjs.vco-right-to-left button,.vco-storyjs.vco-right-to-left table,.vco-storyjs.vco-right-to-left caption,.vco-storyjs.vco-right-to-left tbody,.vco-storyjs.vco-right-to-left tfoot,.vco-storyjs.vco-right-to-left thead,.vco-storyjs.vco-right-to-left tr,.vco-storyjs.vco-right-to-left th,.vco-storyjs.vco-right-to-left td'/>
  <ws:rendition selector='.vco-timeline .vco-navigation'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era div h3,.vco-timeline .vco-navigation .timenav .content .era div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era1 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era1 div h3,.vco-timeline .vco-navigation .timenav .content .era1 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era2 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era2 div h3,.vco-timeline .vco-navigation .timenav .content .era2 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era3 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era3 div h3,.vco-timeline .vco-navigation .timenav .content .era3 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era4 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era4 div h3,.vco-timeline .vco-navigation .timenav .content .era4 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era5 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era5 div h3,.vco-timeline .vco-navigation .timenav .content .era5 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era6 div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .era6 div h3,.vco-timeline .vco-navigation .timenav .content .era6 div h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .dot'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content .thumbnail img,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail img'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content .thumbnail,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content h3 small,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content h3 small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content h3,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content h4 small,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content h4 small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content h4,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content h4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag .flag-content,.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag,.vco-timeline .vco-navigation .timenav .content .marker .flag-small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-audio'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-document'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-googleplus'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-link'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-map'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-photo'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-plaintext'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-quote'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-storify'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-twitter'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-video'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-vimeo'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-website'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-wikipedia'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content .thumbnail.thumb-youtube'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small .flag-content thumbnail.thumb-instagram'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row1'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row2'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row5'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag-small.row6'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag.row1'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag.row2'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag.row3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .flag.zFront,.vco-timeline .vco-navigation .timenav .content .marker .flag-small.zFront'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .line'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker .line .event-line'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .dot'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag .flag-content .thumbnail,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small .flag-content .thumbnail'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag .flag-content h3,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small .flag-content h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag .flag-content,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small .flag-content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small .flag-content'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small .flag-content h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .flag.row1,.vco-timeline .vco-navigation .timenav .content .marker.active .flag.row2,.vco-timeline .vco-navigation .timenav .content .marker.active .flag.row3,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small.row1,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small.row2,.vco-timeline .vco-navigation .timenav .content .marker.active .flag-small.row3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .line'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.active .line .event-line'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .content .marker.start'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era1'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era2'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era4'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era5'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval .era6'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval div strong'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval div.era'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval-major'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval-major div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval-major div strong'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval-minor'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav .time .time-interval-minor .minor'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-indicator'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-interval-background'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-interval-background .top-highlight'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-line'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag div h3'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-1,.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-3,.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-5'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-2,.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-4,.vco-timeline .vco-navigation .timenav-background .timenav-tag-row-6'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-size-full'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-size-full div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-size-half'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .timenav-background .timenav-tag-size-half div'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar .back-home .icon'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar .zoom-in .icon'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar .zoom-in,.vco-timeline .vco-navigation .vco-toolbar .zoom-out,.vco-timeline .vco-navigation .vco-toolbar .back-home'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar .zoom-out .icon'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar.touch'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar.touch .back-home .icon'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar.touch .zoom-in .icon'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar.touch .zoom-in,.vco-timeline .vco-navigation .vco-toolbar.touch .zoom-out,.vco-timeline .vco-navigation .vco-toolbar.touch .back-home'/>
  <ws:rendition selector='.vco-timeline .vco-navigation .vco-toolbar.touch .zoom-out .icon'/>
  <ws:rendition selector='.view-text '/>
  <ws:rendition selector='.view-text,'/>
  <ws:rendition selector='.visible-lg,.visible-md,.visible-sm,.visible-xs'/>
  <ws:rendition selector='.visible-lg-block,.visible-lg-inline,.visible-lg-inline-block,.visible-md-block,.visible-md-inline,.visible-md-inline-block,.visible-sm-block,.visible-sm-inline,.visible-sm-inline-block,.visible-xs-block,.visible-xs-inline,.visible-xs-inline-block'/>
  <ws:rendition selector='.visible-print'/>
  <ws:rendition selector='.visible-print-block'/>
  <ws:rendition selector='.visible-print-inline'/>
  <ws:rendition selector='.visible-print-inline-block'/>
  <ws:rendition selector='.well'/>
  <ws:rendition selector='.well blockquote'/>
  <ws:rendition selector='.well-lg'/>
  <ws:rendition selector='.well-sm'/>
  <ws:rendition selector='::-moz-focus-inner '/>
  <ws:rendition selector='::-webkit-input-placeholder '/>
  <ws:rendition selector=':after,:before'/>
  <ws:rendition selector=':invalid '/>
  <ws:rendition selector=':lang(de) > span.mentioned '/>
  <ws:rendition selector=':lang(de) > span.q '/>
  <ws:rendition selector=':lang(de) > span.quote '/>
  <ws:rendition selector=':lang(de) > span.soCalled '/>
  <ws:rendition selector=':lang(en) > span.mentioned '/>
  <ws:rendition selector=':lang(en) > span.q '/>
  <ws:rendition selector=':lang(en) > span.quote '/>
  <ws:rendition selector=':lang(en) > span.soCalled '/>
  <ws:rendition selector=':lang(fr) > span.mentioned '/>
  <ws:rendition selector=':lang(fr) > span.q '/>
  <ws:rendition selector=':lang(fr) > span.quote '/>
  <ws:rendition selector=':lang(fr) > span.soCalled '/>
  <ws:rendition selector='A '/>
  <ws:rendition selector='A         '/>
  <ws:rendition selector='A IMG '/>
  <ws:rendition selector='A:active '/>
  <ws:rendition selector='A:link	  '/>
  <ws:rendition selector='A:link '/>
  <ws:rendition selector='A:visited '/>
  <ws:rendition selector='BODY '/>
  <ws:rendition selector='CITE '/>
  <ws:rendition selector='CODE '/>
  <ws:rendition selector='DD '/>
  <ws:rendition selector='EG '/>
  <ws:rendition selector='H1 '/>
  <ws:rendition selector='H2 '/>
  <ws:rendition selector='H3 '/>
  <ws:rendition selector='H4 '/>
  <ws:rendition selector='KBD '/>
  <ws:rendition selector='P '/>
  <ws:rendition selector='PRE '/>
  <ws:rendition selector='SPAN A:hover   '/>
  <ws:rendition selector='SPAN A:link    '/>
  <ws:rendition selector='SPAN A:visited '/>
  <ws:rendition selector='TEI '/>
  <ws:rendition selector='TEI > teiHeader > encodingDesc '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > address,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > authoritey,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > authority,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > availability,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > date '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > date:after '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > distributor,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > idno,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > p,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > pubPlace,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > publicationStmt > publisher '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > sourceDesc '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > author '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > editor,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > funder,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > principal,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > respStmt,'/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > sponsor '/>
  <ws:rendition selector='TEI > teiHeader > fileDesc > titleStmt > title '/>
  <ws:rendition selector='TEI > teiHeader > profileDesc '/>
  <ws:rendition selector='TEI > teiHeader > revisionDesc '/>
  <ws:rendition selector='THEAD '/>
  <ws:rendition selector='VAR '/>
  <ws:rendition selector='[data-toggle=buttons]>.btn input[type=checkbox],[data-toggle=buttons]>.btn input[type=radio],[data-toggle=buttons]>.btn-group>.btn input[type=checkbox],[data-toggle=buttons]>.btn-group>.btn input[type=radio]'/>
  <ws:rendition selector='[hidden],template'/>
  <ws:rendition selector='[role=button]'/>
  <ws:rendition selector='a'/>
  <ws:rendition selector='a,'/>
  <ws:rendition selector='a, a:link, a:visited, a:hover '/>
  <ws:rendition selector='a, abbr, acronym, address, big, cite, code,'/>
  <ws:rendition selector='a,a:visited'/>
  <ws:rendition selector='a.badge:focus,a.badge:hover'/>
  <ws:rendition selector='a.bg-danger:focus,a.bg-danger:hover'/>
  <ws:rendition selector='a.bg-info:focus,a.bg-info:hover'/>
  <ws:rendition selector='a.bg-primary:focus,a.bg-primary:hover'/>
  <ws:rendition selector='a.bg-success:focus,a.bg-success:hover'/>
  <ws:rendition selector='a.bg-warning:focus,a.bg-warning:hover'/>
  <ws:rendition selector='a.btn.disabled,fieldset[disabled] a.btn'/>
  <ws:rendition selector='a.label:focus,a.label:hover'/>
  <ws:rendition selector='a.link-more '/>
  <ws:rendition selector='a.link-more-inline '/>
  <ws:rendition selector='a.link-more:after, a.link-more-inline:after '/>
  <ws:rendition selector='a.list-group-item .list-group-item-heading,button.list-group-item .list-group-item-heading'/>
  <ws:rendition selector='a.list-group-item,button.list-group-item'/>
  <ws:rendition selector='a.list-group-item-danger .list-group-item-heading,button.list-group-item-danger .list-group-item-heading'/>
  <ws:rendition selector='a.list-group-item-danger,button.list-group-item-danger'/>
  <ws:rendition selector='a.list-group-item-danger.active,a.list-group-item-danger.active:focus,a.list-group-item-danger.active:hover,button.list-group-item-danger.active,button.list-group-item-danger.active:focus,button.list-group-item-danger.active:hover'/>
  <ws:rendition selector='a.list-group-item-danger:focus,a.list-group-item-danger:hover,button.list-group-item-danger:focus,button.list-group-item-danger:hover'/>
  <ws:rendition selector='a.list-group-item-info .list-group-item-heading,button.list-group-item-info .list-group-item-heading'/>
  <ws:rendition selector='a.list-group-item-info,button.list-group-item-info'/>
  <ws:rendition selector='a.list-group-item-info.active,a.list-group-item-info.active:focus,a.list-group-item-info.active:hover,button.list-group-item-info.active,button.list-group-item-info.active:focus,button.list-group-item-info.active:hover'/>
  <ws:rendition selector='a.list-group-item-info:focus,a.list-group-item-info:hover,button.list-group-item-info:focus,button.list-group-item-info:hover'/>
  <ws:rendition selector='a.list-group-item-success .list-group-item-heading,button.list-group-item-success .list-group-item-heading'/>
  <ws:rendition selector='a.list-group-item-success,button.list-group-item-success'/>
  <ws:rendition selector='a.list-group-item-success.active,a.list-group-item-success.active:focus,a.list-group-item-success.active:hover,button.list-group-item-success.active,button.list-group-item-success.active:focus,button.list-group-item-success.active:hover'/>
  <ws:rendition selector='a.list-group-item-success:focus,a.list-group-item-success:hover,button.list-group-item-success:focus,button.list-group-item-success:hover'/>
  <ws:rendition selector='a.list-group-item-warning .list-group-item-heading,button.list-group-item-warning .list-group-item-heading'/>
  <ws:rendition selector='a.list-group-item-warning,button.list-group-item-warning'/>
  <ws:rendition selector='a.list-group-item-warning.active,a.list-group-item-warning.active:focus,a.list-group-item-warning.active:hover,button.list-group-item-warning.active,button.list-group-item-warning.active:focus,button.list-group-item-warning.active:hover'/>
  <ws:rendition selector='a.list-group-item-warning:focus,a.list-group-item-warning:hover,button.list-group-item-warning:focus,button.list-group-item-warning:hover'/>
  <ws:rendition selector='a.list-group-item:focus,a.list-group-item:hover,button.list-group-item:focus,button.list-group-item:hover'/>
  <ws:rendition selector='a.text-danger:focus,a.text-danger:hover'/>
  <ws:rendition selector='a.text-info:focus,a.text-info:hover'/>
  <ws:rendition selector='a.text-primary:focus,a.text-primary:hover'/>
  <ws:rendition selector='a.text-success:focus,a.text-success:hover'/>
  <ws:rendition selector='a.text-warning:focus,a.text-warning:hover'/>
  <ws:rendition selector='a.thumbnail.active,a.thumbnail:focus,a.thumbnail:hover'/>
  <ws:rendition selector='a:active '/>
  <ws:rendition selector='a:active  '/>
  <ws:rendition selector='a:active,a:hover'/>
  <ws:rendition selector='a:focus'/>
  <ws:rendition selector='a:focus '/>
  <ws:rendition selector='a:focus,a:hover'/>
  <ws:rendition selector='a:hover '/>
  <ws:rendition selector='a:hover  '/>
  <ws:rendition selector='a:link '/>
  <ws:rendition selector='a:link  '/>
  <ws:rendition selector='a:link,'/>
  <ws:rendition selector='a:link, a:visited '/>
  <ws:rendition selector='a:link, a:visited, a:active '/>
  <ws:rendition selector='a:visited '/>
  <ws:rendition selector='a:visited  '/>
  <ws:rendition selector='a:visited,'/>
  <ws:rendition selector='a[href]:after'/>
  <ws:rendition selector='a[href^="javascript:"]:after,a[href^="#"]:after'/>
  <ws:rendition selector='abbr[data-original-title],abbr[title]'/>
  <ws:rendition selector='abbr[title]'/>
  <ws:rendition selector='abbr[title]:after'/>
  <ws:rendition selector='address'/>
  <ws:rendition selector='address '/>
  <ws:rendition selector='article, aside, canvas, details, embed, '/>
  <ws:rendition selector='article, aside, details, figcaption, figure, '/>
  <ws:rendition selector='article,aside,details,figcaption,figure,footer,header,hgroup,main,menu,nav,section,summary'/>
  <ws:rendition selector='att '/>
  <ws:rendition selector='att:after '/>
  <ws:rendition selector='audio,canvas,progress,video'/>
  <ws:rendition selector='audio:not([controls])'/>
  <ws:rendition selector='b '/>
  <ws:rendition selector='b, u, i, center,'/>
  <ws:rendition selector='b,strong'/>
  <ws:rendition selector='blockquote'/>
  <ws:rendition selector='blockquote '/>
  <ws:rendition selector='blockquote .small,blockquote footer,blockquote small'/>
  <ws:rendition selector='blockquote .small:before,blockquote footer:before,blockquote small:before'/>
  <ws:rendition selector='blockquote ol:last-child,blockquote p:last-child,blockquote ul:last-child'/>
  <ws:rendition selector='blockquote, q '/>
  <ws:rendition selector='blockquote,pre'/>
  <ws:rendition selector='blockquote:before, blockquote:after,'/>
  <ws:rendition selector='blockquote:before, blockquote:after, q:before, q:after '/>
  <ws:rendition selector='blue '/>
  <ws:rendition selector='body'/>
  <ws:rendition selector='body '/>
  <ws:rendition selector='body .btn-link '/>
  <ws:rendition selector='body a,'/>
  <ws:rendition selector='button'/>
  <ws:rendition selector='button '/>
  <ws:rendition selector='button,'/>
  <ws:rendition selector='button,html input[type=button],input[type=reset],input[type=submit]'/>
  <ws:rendition selector='button,input,optgroup,select,textarea'/>
  <ws:rendition selector='button,input,select,textarea'/>
  <ws:rendition selector='button,select'/>
  <ws:rendition selector='button.close'/>
  <ws:rendition selector='button.list-group-item'/>
  <ws:rendition selector='button::-moz-focus-inner,input::-moz-focus-inner'/>
  <ws:rendition selector='button:active,'/>
  <ws:rendition selector='button:focus,'/>
  <ws:rendition selector='button[disabled],'/>
  <ws:rendition selector='button[disabled],html input[disabled]'/>
  <ws:rendition selector='caption'/>
  <ws:rendition selector='cell '/>
  <ws:rendition selector='cite, address '/>
  <ws:rendition selector='code'/>
  <ws:rendition selector='code '/>
  <ws:rendition selector='code,kbd,pre,samp'/>
  <ws:rendition selector='code.tag:after '/>
  <ws:rendition selector='code.tag:before '/>
  <ws:rendition selector='date '/>
  <ws:rendition selector='dd'/>
  <ws:rendition selector='dd '/>
  <ws:rendition selector='dd,dt'/>
  <ws:rendition selector='del, dfn, em, img, ins, kbd, q, s, samp,'/>
  <ws:rendition selector='dfn'/>
  <ws:rendition selector='div '/>
  <ws:rendition selector='div#front '/>
  <ws:rendition selector='div#front h1 '/>
  <ws:rendition selector='div#pager '/>
  <ws:rendition selector='div#pager form '/>
  <ws:rendition selector='div#pager form a '/>
  <ws:rendition selector='div#pager span.left '/>
  <ws:rendition selector='div#pager span.right '/>
  <ws:rendition selector='div#qotd-container div.qotd '/>
  <ws:rendition selector='div#qotd-container p '/>
  <ws:rendition selector='div#qotd-container p.qotd '/>
  <ws:rendition selector='div#qotd-container p.qotd-author '/>
  <ws:rendition selector='div#qotd-container p.qotd-title '/>
  <ws:rendition selector='div#upcoming a '/>
  <ws:rendition selector='div#upcoming a:after '/>
  <ws:rendition selector='div#upcoming div.dateBox '/>
  <ws:rendition selector='div#upcoming div.dateBox div.dayBox '/>
  <ws:rendition selector='div#upcoming div.dateBox div.monthBox '/>
  <ws:rendition selector='div#upcoming div.event '/>
  <ws:rendition selector='div#upcoming span.eventDates '/>
  <ws:rendition selector='div.about '/>
  <ws:rendition selector='div.about b '/>
  <ws:rendition selector='div.area-navigation '/>
  <ws:rendition selector='div.area-navigation > ul > li.file > a '/>
  <ws:rendition selector='div.area-navigation a '/>
  <ws:rendition selector='div.area-navigation a:hover '/>
  <ws:rendition selector='div.area-navigation h1, div.related h1 '/>
  <ws:rendition selector='div.area-navigation li '/>
  <ws:rendition selector='div.area-navigation li ul li '/>
  <ws:rendition selector='div.area-navigation li ul li a '/>
  <ws:rendition selector='div.area-navigation li ul li ul li '/>
  <ws:rendition selector='div.area-navigation li ul li ul li a '/>
  <ws:rendition selector='div.area-navigation li.active li.collapsed a '/>
  <ws:rendition selector='div.area-navigation li.active, div.area-navigation li.active li, div.area-navigation li.active li li '/>
  <ws:rendition selector='div.area-navigation li.collapsed a '/>
  <ws:rendition selector='div.area-navigation li.expanded '/>
  <ws:rendition selector='div.area-navigation li.expanded a '/>
  <ws:rendition selector='div.area-navigation li.expanded.active a, div.area-navigation li.active li.expanded a '/>
  <ws:rendition selector='div.area-navigation li.file a, div.area-navigation li.active li.file a '/>
  <ws:rendition selector='div.area-navigation ul, div.related ul '/>
  <ws:rendition selector='div.area-navigation, div.related '/>
  <ws:rendition selector='div.banner '/>
  <ws:rendition selector='div.banner div.banner-title '/>
  <ws:rendition selector='div.banner img '/>
  <ws:rendition selector='div.banner img.banner-log '/>
  <ws:rendition selector='div.banner-title '/>
  <ws:rendition selector='div.banner-title, div.nav-menu ul.nav-menu-outer, div.main, div.footer '/>
  <ws:rendition selector='div.bottom '/>
  <ws:rendition selector='div.c2 '/>
  <ws:rendition selector='div.c4 '/>
  <ws:rendition selector='div.callout '/>
  <ws:rendition selector='div.callout > head, div.callout > p '/>
  <ws:rendition selector='div.chunk '/>
  <ws:rendition selector='div.chunk div.chunk-inner '/>
  <ws:rendition selector='div.chunk h2 '/>
  <ws:rendition selector='div.chunk h2 a:hover '/>
  <ws:rendition selector='div.chunk h2 a:link, div.chunk h2 a:visited '/>
  <ws:rendition selector='div.chunk p '/>
  <ws:rendition selector='div.chunks '/>
  <ws:rendition selector='div.chunks div.first '/>
  <ws:rendition selector='div.chunks div.last, div.footer div.last '/>
  <ws:rendition selector='div.content '/>
  <ws:rendition selector='div.content .status '/>
  <ws:rendition selector='div.content .status .status-bar '/>
  <ws:rendition selector='div.content .status .status-label '/>
  <ws:rendition selector='div.content .status, '/>
  <ws:rendition selector='div.content address '/>
  <ws:rendition selector='div.content blockquote '/>
  <ws:rendition selector='div.content blockquote p '/>
  <ws:rendition selector='div.content blockquote p:last-child:after '/>
  <ws:rendition selector='div.content caption '/>
  <ws:rendition selector='div.content div.progress-bar '/>
  <ws:rendition selector='div.content dl '/>
  <ws:rendition selector='div.content h2 '/>
  <ws:rendition selector='div.content img '/>
  <ws:rendition selector='div.content ol li '/>
  <ws:rendition selector='div.content p '/>
  <ws:rendition selector='div.content p samp, div.content li samp, div.content dd samp '/>
  <ws:rendition selector='div.content p.byline span.author, div.content span.byline span.author '/>
  <ws:rendition selector='div.content p.byline, div.content span.byline '/>
  <ws:rendition selector='div.content p.dateline '/>
  <ws:rendition selector='div.content p.event span.eventhead '/>
  <ws:rendition selector='div.content p.license '/>
  <ws:rendition selector='div.content p.license a[rel="license"] img '/>
  <ws:rendition selector='div.content samp '/>
  <ws:rendition selector='div.content table '/>
  <ws:rendition selector='div.content table#sort-table tbody td '/>
  <ws:rendition selector='div.content table#sort-table td '/>
  <ws:rendition selector='div.content table#sort-table th '/>
  <ws:rendition selector='div.content table#sort-table thead '/>
  <ws:rendition selector='div.content table#sort-table thead th,'/>
  <ws:rendition selector='div.content table.wwp_students td '/>
  <ws:rendition selector='div.content td '/>
  <ws:rendition selector='div.content td.author '/>
  <ws:rendition selector='div.content td.content '/>
  <ws:rendition selector='div.content td.time '/>
  <ws:rendition selector='div.content th '/>
  <ws:rendition selector='div.content tr.divide-after '/>
  <ws:rendition selector='div.content tr.seminar_item '/>
  <ws:rendition selector='div.content ul '/>
  <ws:rendition selector='div.content ul li '/>
  <ws:rendition selector='div.content ul ul, div.content ol ul '/>
  <ws:rendition selector='div.event p:last-child:after '/>
  <ws:rendition selector='div.featured '/>
  <ws:rendition selector='div.featured div.scrollable '/>
  <ws:rendition selector='div.featured div.scrollable div.items '/>
  <ws:rendition selector='div.featured div.scrollable div.items div.item-content '/>
  <ws:rendition selector='div.featured div.scrollable div.items div.item-content p.caption '/>
  <ws:rendition selector='div.featured div.scrollbox '/>
  <ws:rendition selector='div.featured div.scrollnav '/>
  <ws:rendition selector='div.featured div.scrollnav div.active a '/>
  <ws:rendition selector='div.featured div.scrollnav div.active a:hover '/>
  <ws:rendition selector='div.featured div.scrollnav div.scrollnav-item '/>
  <ws:rendition selector='div.featured div.scrollnav div.scrollnav-item a '/>
  <ws:rendition selector='div.featured div.scrollnav div.scrollnav-item a.disabled:hover '/>
  <ws:rendition selector='div.featured div.scrollnav div.scrollnav-item a:hover '/>
  <ws:rendition selector='div.featured h1 '/>
  <ws:rendition selector='div.footer '/>
  <ws:rendition selector='div.footer a.brownlogo '/>
  <ws:rendition selector='div.footer a.brownlogo img '/>
  <ws:rendition selector='div.footer a:link, div.footer a:visited '/>
  <ws:rendition selector='div.footer div '/>
  <ws:rendition selector='div.footer h1 '/>
  <ws:rendition selector='div.frame '/>
  <ws:rendition selector='div.header '/>
  <ws:rendition selector='div.header div.banner-title '/>
  <ws:rendition selector='div.header img.banner-logo '/>
  <ws:rendition selector='div.main '/>
  <ws:rendition selector='div.main h1 '/>
  <ws:rendition selector='div.main h2 '/>
  <ws:rendition selector='div.main h3 '/>
  <ws:rendition selector='div.main h3 + h4 '/>
  <ws:rendition selector='div.main h4 '/>
  <ws:rendition selector='div.main h4 > i '/>
  <ws:rendition selector='div.nav-menu '/>
  <ws:rendition selector='div.nav-menu > ul > li > ul '/>
  <ws:rendition selector='div.nav-menu > ul > li.first:hover '/>
  <ws:rendition selector='div.nav-menu > ul > li:hover, div.nav-menu > ul > li.active '/>
  <ws:rendition selector='div.nav-menu a, div.nav-menu a:visited '/>
  <ws:rendition selector='div.nav-menu li '/>
  <ws:rendition selector='div.nav-menu li a:hover, div.nav-menu li a:focus '/>
  <ws:rendition selector='div.nav-menu li ul '/>
  <ws:rendition selector='div.nav-menu li ul li '/>
  <ws:rendition selector='div.nav-menu li ul li a, div.nav-menu li ul li a:visited '/>
  <ws:rendition selector='div.nav-menu li.first '/>
  <ws:rendition selector='div.nav-menu li.first a, div.nav-menu li.first a:visited '/>
  <ws:rendition selector='div.nav-menu li.first a:hover '/>
  <ws:rendition selector='div.nav-menu li.last '/>
  <ws:rendition selector='div.nav-menu li:hover a, div.nav-menu li.active a '/>
  <ws:rendition selector='div.nav-menu ul li ul '/>
  <ws:rendition selector='div.nav-menu ul li:hover ul, div.nav-menu ul a:hover ul, div.nav-menu ul li.active ul '/>
  <ws:rendition selector='div.nav-menu ul ul '/>
  <ws:rendition selector='div.nav-menu ul ul a, div.nav-menu ul ul a:visited '/>
  <ws:rendition selector='div.nav-menu ul.nav-menu-outer '/>
  <ws:rendition selector='div.news-item '/>
  <ws:rendition selector='div.news-item p '/>
  <ws:rendition selector='div.news-item p a '/>
  <ws:rendition selector='div.news-item p a:after '/>
  <ws:rendition selector='div.news-item-date '/>
  <ws:rendition selector='div.overlay '/>
  <ws:rendition selector='div.overlay .close '/>
  <ws:rendition selector='div.overlay div.dateBox '/>
  <ws:rendition selector='div.overlay div.dayBox, div.overlay div.yearBox '/>
  <ws:rendition selector='div.overlay div.dayBox:after '/>
  <ws:rendition selector='div.overlay div.image '/>
  <ws:rendition selector='div.overlay div.monthBox '/>
  <ws:rendition selector='div.overlay div.monthBox:after '/>
  <ws:rendition selector='div.overlay p '/>
  <ws:rendition selector='div.overlay p.eventDesc '/>
  <ws:rendition selector='div.overlay p.eventHead '/>
  <ws:rendition selector='div.overlay p.eventHead span.eventDates '/>
  <ws:rendition selector='div.overlay p.eventHead span.eventLoc '/>
  <ws:rendition selector='div.quote '/>
  <ws:rendition selector='div.related '/>
  <ws:rendition selector='div.related div.gallery '/>
  <ws:rendition selector='div.related div.gallery-item '/>
  <ws:rendition selector='div.related div.gallery-item a '/>
  <ws:rendition selector='div.related div.gallery-item img '/>
  <ws:rendition selector='div.related div.gallery-item span.tip '/>
  <ws:rendition selector='div.related div.tools '/>
  <ws:rendition selector='div.related div.tools-only '/>
  <ws:rendition selector='div.related li '/>
  <ws:rendition selector='div.related li a:hover '/>
  <ws:rendition selector='div.related ul '/>
  <ws:rendition selector='div.rich-top b '/>
  <ws:rendition selector='div.rich-top h1 '/>
  <ws:rendition selector='div.rich-top h2, div.rich-bot h2 '/>
  <ws:rendition selector='div.seminar li '/>
  <ws:rendition selector='div.seminar p '/>
  <ws:rendition selector='div.seminar ul '/>
  <ws:rendition selector='div.slideBot table '/>
  <ws:rendition selector='div.slideBot td '/>
  <ws:rendition selector='div.slideBot td.copyright '/>
  <ws:rendition selector='div.slideBot td.logo '/>
  <ws:rendition selector='div.slideBot td.title '/>
  <ws:rendition selector='div.slideTop '/>
  <ws:rendition selector='div.slideTop > p.navigation '/>
  <ws:rendition selector='div.slideTop > p.navigation > a.navigationButton '/>
  <ws:rendition selector='div.syllabus '/>
  <ws:rendition selector='div.syllabus div p:last-child:after, div.syllabus div li:last-child:after, div.syllabus div.assignments li:last-child:after '/>
  <ws:rendition selector='div.syllabus div.assignments div, div.syllabus div.readings ul '/>
  <ws:rendition selector='div.syllabus div.readings li '/>
  <ws:rendition selector='div.syllabus div.readings p:last-child:after, div.syllabus div.readings li:last-child:after '/>
  <ws:rendition selector='div.syllabus h3.collapsed '/>
  <ws:rendition selector='div.syllabus h3.expanded '/>
  <ws:rendition selector='div.text p '/>
  <ws:rendition selector='div.text p img.inline-right '/>
  <ws:rendition selector='div.text p:last-child:after '/>
  <ws:rendition selector='div.tools div.tool-item, div.tools-only div.tool-item '/>
  <ws:rendition selector='div.top '/>
  <ws:rendition selector='dl'/>
  <ws:rendition selector='dl, dt, dd, ol, ul, li,'/>
  <ws:rendition selector='dt'/>
  <ws:rendition selector='dt '/>
  <ws:rendition selector='eg '/>
  <ws:rendition selector='emph '/>
  <ws:rendition selector='emph,'/>
  <ws:rendition selector='fieldset'/>
  <ws:rendition selector='fieldset '/>
  <ws:rendition selector='fieldset, form, label, legend,'/>
  <ws:rendition selector='fieldset[disabled] input[type=checkbox],fieldset[disabled] input[type=radio],input[type=checkbox].disabled,input[type=checkbox][disabled],input[type=radio].disabled,input[type=radio][disabled]'/>
  <ws:rendition selector='figure'/>
  <ws:rendition selector='figure, figcaption, footer, header, hgroup, '/>
  <ws:rendition selector='footer '/>
  <ws:rendition selector='footer .poweredby '/>
  <ws:rendition selector='footer .poweredby img '/>
  <ws:rendition selector='footer, header, hgroup, menu, nav, section '/>
  <ws:rendition selector='foreign '/>
  <ws:rendition selector='form '/>
  <ws:rendition selector='formula '/>
  <ws:rendition selector='gi '/>
  <ws:rendition selector='gi:after '/>
  <ws:rendition selector='gi:before '/>
  <ws:rendition selector='gloss '/>
  <ws:rendition selector='h1'/>
  <ws:rendition selector='h1 '/>
  <ws:rendition selector='h1, h2, h3, h4, h5, h6, p, blockquote, pre,'/>
  <ws:rendition selector='h1.slideTitle '/>
  <ws:rendition selector='h2 '/>
  <ws:rendition selector='h2,h3'/>
  <ws:rendition selector='h2,h3,p'/>
  <ws:rendition selector='h2.slideTitle '/>
  <ws:rendition selector='h3 '/>
  <ws:rendition selector='header '/>
  <ws:rendition selector='header h1 '/>
  <ws:rendition selector='header hgroup '/>
  <ws:rendition selector='header nav '/>
  <ws:rendition selector='header nav li '/>
  <ws:rendition selector='header nav li a '/>
  <ws:rendition selector='header nav li a:hover '/>
  <ws:rendition selector='hi '/>
  <ws:rendition selector='hi[rend="class(current)"] '/>
  <ws:rendition selector='hr'/>
  <ws:rendition selector='html'/>
  <ws:rendition selector='html '/>
  <ws:rendition selector='html, body '/>
  <ws:rendition selector='html, body, div, span, applet, object, iframe,'/>
  <ws:rendition selector='html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td '/>
  <ws:rendition selector='i '/>
  <ws:rendition selector='img'/>
  <ws:rendition selector='img '/>
  <ws:rendition selector='img,tr'/>
  <ws:rendition selector='img.c1 '/>
  <ws:rendition selector='img.c3 '/>
  <ws:rendition selector='input'/>
  <ws:rendition selector='input '/>
  <ws:rendition selector='input,'/>
  <ws:rendition selector='input.placeholder_text,'/>
  <ws:rendition selector='input:-moz-placeholder,'/>
  <ws:rendition selector='input:active,'/>
  <ws:rendition selector='input:focus,'/>
  <ws:rendition selector='input[disabled],'/>
  <ws:rendition selector='input[type="button"] '/>
  <ws:rendition selector='input[type="checkbox"] '/>
  <ws:rendition selector='input[type="checkbox"]:active '/>
  <ws:rendition selector='input[type="checkbox"]:focus,'/>
  <ws:rendition selector='input[type="date"],'/>
  <ws:rendition selector='input[type="date"][disabled],'/>
  <ws:rendition selector='input[type="datetime"],'/>
  <ws:rendition selector='input[type="datetime"][disabled],'/>
  <ws:rendition selector='input[type="datetime-local"],'/>
  <ws:rendition selector='input[type="datetime-local"][disabled],'/>
  <ws:rendition selector='input[type="email"],'/>
  <ws:rendition selector='input[type="email"][disabled],'/>
  <ws:rendition selector='input[type="file"]:active,'/>
  <ws:rendition selector='input[type="file"]:focus,'/>
  <ws:rendition selector='input[type="month"],'/>
  <ws:rendition selector='input[type="month"][disabled],'/>
  <ws:rendition selector='input[type="number"],'/>
  <ws:rendition selector='input[type="number"][disabled],'/>
  <ws:rendition selector='input[type="password"],'/>
  <ws:rendition selector='input[type="password"][disabled],'/>
  <ws:rendition selector='input[type="radio"],'/>
  <ws:rendition selector='input[type="radio"]:active,'/>
  <ws:rendition selector='input[type="radio"]:focus,'/>
  <ws:rendition selector='input[type="reset"],'/>
  <ws:rendition selector='input[type="search"],'/>
  <ws:rendition selector='input[type="search"]::-webkit-search-decoration '/>
  <ws:rendition selector='input[type="search"][disabled],'/>
  <ws:rendition selector='input[type="submit"],'/>
  <ws:rendition selector='input[type="tel"],'/>
  <ws:rendition selector='input[type="tel"][disabled],'/>
  <ws:rendition selector='input[type="text"],'/>
  <ws:rendition selector='input[type="text"][disabled],'/>
  <ws:rendition selector='input[type="time"],'/>
  <ws:rendition selector='input[type="time"][disabled],'/>
  <ws:rendition selector='input[type="url"],'/>
  <ws:rendition selector='input[type="url"][disabled],'/>
  <ws:rendition selector='input[type="week"] '/>
  <ws:rendition selector='input[type="week"][disabled] '/>
  <ws:rendition selector='input[type=button].btn-block,input[type=reset].btn-block,input[type=submit].btn-block'/>
  <ws:rendition selector='input[type=checkbox],input[type=radio]'/>
  <ws:rendition selector='input[type=file]'/>
  <ws:rendition selector='input[type=file]:focus,input[type=checkbox]:focus,input[type=radio]:focus'/>
  <ws:rendition selector='input[type=number]::-webkit-inner-spin-button,input[type=number]::-webkit-outer-spin-button'/>
  <ws:rendition selector='input[type=range]'/>
  <ws:rendition selector='input[type=search]'/>
  <ws:rendition selector='input[type=search]::-webkit-search-cancel-button,input[type=search]::-webkit-search-decoration'/>
  <ws:rendition selector='item '/>
  <ws:rendition selector='item[n]:before '/>
  <ws:rendition selector='kbd'/>
  <ws:rendition selector='kbd kbd'/>
  <ws:rendition selector='kw '/>
  <ws:rendition selector='label'/>
  <ws:rendition selector='label '/>
  <ws:rendition selector='label.textfield '/>
  <ws:rendition selector='lb '/>
  <ws:rendition selector='legend'/>
  <ws:rendition selector='legend '/>
  <ws:rendition selector='li '/>
  <ws:rendition selector='li.badged '/>
  <ws:rendition selector='li.badged .item-context '/>
  <ws:rendition selector='li.badged .item-main '/>
  <ws:rendition selector='li.c3 '/>
  <ws:rendition selector='li:first-child '/>
  <ws:rendition selector='list '/>
  <ws:rendition selector='list[rend="inline"] '/>
  <ws:rendition selector='list[rend~="bullets"] '/>
  <ws:rendition selector='list[type="gloss"] > item '/>
  <ws:rendition selector='list[type="glosstable"] '/>
  <ws:rendition selector='list[type="glosstable"] > item '/>
  <ws:rendition selector='list[type="glosstable"] > label '/>
  <ws:rendition selector='list[type="ordered"] '/>
  <ws:rendition selector='mark'/>
  <ws:rendition selector='mentioned '/>
  <ws:rendition selector='menu, nav, output, ruby, section, summary,'/>
  <ws:rendition selector='name '/>
  <ws:rendition selector='nice '/>
  <ws:rendition selector='note '/>
  <ws:rendition selector='note[n]:before '/>
  <ws:rendition selector='note[place="inline"], note[place="unspecified"] '/>
  <ws:rendition selector='note[place="left"] '/>
  <ws:rendition selector='note[place="right"] '/>
  <ws:rendition selector='num '/>
  <ws:rendition selector='ol '/>
  <ws:rendition selector='ol ol,ol ul,ul ol,ul ul'/>
  <ws:rendition selector='ol, ul '/>
  <ws:rendition selector='ol,ul'/>
  <ws:rendition selector='optgroup'/>
  <ws:rendition selector='optgroup '/>
  <ws:rendition selector='output'/>
  <ws:rendition selector='p'/>
  <ws:rendition selector='p '/>
  <ws:rendition selector='p.byline '/>
  <ws:rendition selector='p.dateLine '/>
  <ws:rendition selector='p.list-head '/>
  <ws:rendition selector='pre'/>
  <ws:rendition selector='pre > span.hi '/>
  <ws:rendition selector='pre code'/>
  <ws:rendition selector='pre, tt '/>
  <ws:rendition selector='pre.eg, pre.eg_valid, pre.eg_well-formed '/>
  <ws:rendition selector='pre.eg_invalid, pre.eg_ill-formed '/>
  <ws:rendition selector='presentation '/>
  <ws:rendition selector='presentation > head '/>
  <ws:rendition selector='presentation > unit > head, presentation > head '/>
  <ws:rendition selector='presentation section '/>
  <ws:rendition selector='presentation section > head '/>
  <ws:rendition selector='presentation section > head:before '/>
  <ws:rendition selector='presentation section > lectureNote '/>
  <ws:rendition selector='presentation section > lectureNote > head '/>
  <ws:rendition selector='presentation section > lectureNote > head:before '/>
  <ws:rendition selector='presentation section > lectureNote:before '/>
  <ws:rendition selector='presentation section > slide '/>
  <ws:rendition selector='presentation section > slide > div '/>
  <ws:rendition selector='presentation section > slide > div > div '/>
  <ws:rendition selector='presentation section > slide > div > head '/>
  <ws:rendition selector='presentation section > slide > head '/>
  <ws:rendition selector='presentation section > slide > head:before '/>
  <ws:rendition selector='q, said '/>
  <ws:rendition selector='q:after, said:after '/>
  <ws:rendition selector='q:before, q:after '/>
  <ws:rendition selector='q:before, said:before '/>
  <ws:rendition selector='q[rend="display"] '/>
  <ws:rendition selector='row '/>
  <ws:rendition selector='select '/>
  <ws:rendition selector='select,'/>
  <ws:rendition selector='select.input-group-lg>.form-control,select.input-group-lg>.input-group-addon,select.input-group-lg>.input-group-btn>.btn'/>
  <ws:rendition selector='select.input-group-sm>.form-control,select.input-group-sm>.input-group-addon,select.input-group-sm>.input-group-btn>.btn'/>
  <ws:rendition selector='select.input-lg'/>
  <ws:rendition selector='select.input-sm'/>
  <ws:rendition selector='select:active,'/>
  <ws:rendition selector='select:focus,'/>
  <ws:rendition selector='select[disabled] optgroup,'/>
  <ws:rendition selector='select[disabled] option,'/>
  <ws:rendition selector='select[disabled],'/>
  <ws:rendition selector='select[multiple] '/>
  <ws:rendition selector='select[multiple],select[size]'/>
  <ws:rendition selector='select[multiple].input-group-lg>.form-control,select[multiple].input-group-lg>.input-group-addon,select[multiple].input-group-lg>.input-group-btn>.btn,textarea.input-group-lg>.form-control,textarea.input-group-lg>.input-group-addon,textarea.input-group-lg>.input-group-btn>.btn'/>
  <ws:rendition selector='select[multiple].input-group-sm>.form-control,select[multiple].input-group-sm>.input-group-addon,select[multiple].input-group-sm>.input-group-btn>.btn,textarea.input-group-sm>.form-control,textarea.input-group-sm>.input-group-addon,textarea.input-group-sm>.input-group-btn>.btn'/>
  <ws:rendition selector='select[multiple].input-lg,textarea.input-lg'/>
  <ws:rendition selector='select[multiple].input-sm,textarea.input-sm'/>
  <ws:rendition selector='select[size],'/>
  <ws:rendition selector='small'/>
  <ws:rendition selector='small, strike, strong, sub, sup, tt, var,'/>
  <ws:rendition selector='soCalled '/>
  <ws:rendition selector='soCalled:after '/>
  <ws:rendition selector='soCalled:before '/>
  <ws:rendition selector='span.att '/>
  <ws:rendition selector='span.att:after '/>
  <ws:rendition selector='span.code '/>
  <ws:rendition selector='span.emph '/>
  <ws:rendition selector='span.ent '/>
  <ws:rendition selector='span.ent:after '/>
  <ws:rendition selector='span.ent:before '/>
  <ws:rendition selector='span.foriegn '/>
  <ws:rendition selector='span.gi '/>
  <ws:rendition selector='span.gi:after '/>
  <ws:rendition selector='span.gi:before '/>
  <ws:rendition selector='span.ident_cmd, span.name_cmd '/>
  <ws:rendition selector='span.ident_pe '/>
  <ws:rendition selector='span.ident_pe:after '/>
  <ws:rendition selector='span.ident_pe:before '/>
  <ws:rendition selector='span.mentioned '/>
  <ws:rendition selector='span.mentioned:after '/>
  <ws:rendition selector='span.mentioned:before '/>
  <ws:rendition selector='span.q '/>
  <ws:rendition selector='span.q:after '/>
  <ws:rendition selector='span.q:before '/>
  <ws:rendition selector='span.quote '/>
  <ws:rendition selector='span.quote:after '/>
  <ws:rendition selector='span.quote:before '/>
  <ws:rendition selector='span.rich-caption '/>
  <ws:rendition selector='span.soCalled '/>
  <ws:rendition selector='span.soCalled:after '/>
  <ws:rendition selector='span.soCalled:before '/>
  <ws:rendition selector='span.tag '/>
  <ws:rendition selector='span.tag:after '/>
  <ws:rendition selector='span.tag:before '/>
  <ws:rendition selector='span.term '/>
  <ws:rendition selector='span.val '/>
  <ws:rendition selector='span.val:after '/>
  <ws:rendition selector='span.val:before '/>
  <ws:rendition selector='span[style] '/>
  <ws:rendition selector='sub'/>
  <ws:rendition selector='sub,sup'/>
  <ws:rendition selector='sup'/>
  <ws:rendition selector='svg:not(:root)'/>
  <ws:rendition selector='table'/>
  <ws:rendition selector='table '/>
  <ws:rendition selector='table col[class*=col-]'/>
  <ws:rendition selector='table td[class*=col-],table th[class*=col-]'/>
  <ws:rendition selector='table, caption, tbody, tfoot, thead, tr, th, td,'/>
  <ws:rendition selector='table.c2 '/>
  <ws:rendition selector='table.visible-lg'/>
  <ws:rendition selector='table.visible-md'/>
  <ws:rendition selector='table.visible-print'/>
  <ws:rendition selector='table.visible-sm'/>
  <ws:rendition selector='table.visible-xs'/>
  <ws:rendition selector='tag '/>
  <ws:rendition selector='tag:after '/>
  <ws:rendition selector='tag:before '/>
  <ws:rendition selector='tbody.collapse.in'/>
  <ws:rendition selector='td '/>
  <ws:rendition selector='td,th'/>
  <ws:rendition selector='td.c1 '/>
  <ws:rendition selector='td.head '/>
  <ws:rendition selector='td.visible-lg,th.visible-lg'/>
  <ws:rendition selector='td.visible-md,th.visible-md'/>
  <ws:rendition selector='td.visible-print,th.visible-print'/>
  <ws:rendition selector='td.visible-sm,th.visible-sm'/>
  <ws:rendition selector='td.visible-xs,th.visible-xs'/>
  <ws:rendition selector='term '/>
  <ws:rendition selector='term:after '/>
  <ws:rendition selector='term:before '/>
  <ws:rendition selector='textarea'/>
  <ws:rendition selector='textarea '/>
  <ws:rendition selector='textarea,'/>
  <ws:rendition selector='textarea.form-control'/>
  <ws:rendition selector='textarea.placeholder_text '/>
  <ws:rendition selector='textarea:-moz-placeholder '/>
  <ws:rendition selector='textarea:active '/>
  <ws:rendition selector='textarea:focus,'/>
  <ws:rendition selector='textarea[disabled] '/>
  <ws:rendition selector='textarea[disabled],'/>
  <ws:rendition selector='th'/>
  <ws:rendition selector='th.table-col-small '/>
  <ws:rendition selector='thead'/>
  <ws:rendition selector='time, mark, audio, video '/>
  <ws:rendition selector='title '/>
  <ws:rendition selector='to'/>
  <ws:rendition selector='tr '/>
  <ws:rendition selector='tr,p,ul,ol '/>
  <ws:rendition selector='tr.collapse.in'/>
  <ws:rendition selector='tr.visible-lg'/>
  <ws:rendition selector='tr.visible-md'/>
  <ws:rendition selector='tr.visible-print'/>
  <ws:rendition selector='tr.visible-sm'/>
  <ws:rendition selector='tr.visible-xs'/>
  <ws:rendition selector='ul.nobul '/>
  <ws:rendition selector='ul.wwir-carousel-indicators '/>
  <ws:rendition selector='ul.wwir-carousel-indicators li '/>
  <ws:rendition selector='ul.wwir-carousel-indicators li:first-child '/>
  <ws:rendition selector='ul.wwir-carousel-indicators li:hover '/>
  <ws:rendition selector='val '/>
  <ws:rendition selector='val:after '/>
  <ws:rendition selector='val:before '/>
  <pt:rendition selector='[data-select]'/>
  <pt:rendition selector='a[data-select]'/>
  <pt:rendition selector='[data-select="link"]'/>
  <pt:rendition selector='a[data-select="link"]'/>
  <pt:rendition selector='div[data-div="layer1"] a[data-select="link"]'/>
  <pt:rendition selector='a:after'/>
  <pt:rendition selector='.tagA.link'/>
  <pt:rendition selector='.tagUl .link'/>
  <pt:rendition selector='.tagB > .tagA'/>
  <pt:rendition selector='[class^="wrap"]'/>
  <pt:rendition selector='.div:nth-of-type(1) a'/>
  <pt:rendition selector='.div:nth-of-type(1) .div:nth-of-type(1) a'/>
  <pt:rendition selector='div.wrapper > div.tagDiv > div.tagDiv.layer2 > ul.tagUL > li.tagLi > b.tagB > a.TagA.link'/>
  <pt:rendition selector='.tagLi .tagB a.TagA.link'/>
  <pt:rendition selector='*'/>
  <pt:rendition selector='a'/>
  <pt:rendition selector='div a'/>
  <pt:rendition selector='div ul a'/>
  <pt:rendition selector='div ul a:after;'/>
  <pt:rendition selector='.link'/>
  <pt:rendition selector='[data-select]'/>
  <pt:rendition selector='a[data-select]'/>
  <pt:rendition selector='[data-select="link"]'/>
  <pt:rendition selector='a[data-select="link"]'/>
  <pt:rendition selector='div[data-div="layer1"] a[data-select="link"]'/>
  <pt:rendition selector='a:after'/>
  <pt:rendition selector='.tagA.link'/>
  <pt:rendition selector='.tagUl .link'/>
  <pt:rendition selector='.tagB > .tagA'/>
  <pt:rendition selector='[class^="wrap"]'/>
  <pt:rendition selector='.div:nth-of-type(1) a'/>
  <pt:rendition selector='.div:nth-of-type(1) .div:nth-of-type(1) a'/>
  <pt:rendition selector='div.wrapper > div.tagDiv > div.tagDiv.layer2 > ul.tagUL > li.tagLi > b.tagB > a.TagA.link'/>
  <pt:rendition selector='.tagLi .tagB a.TagA.link'/>
  <pt:rendition selector='*'/>
  <pt:rendition selector='a'/>
  <pt:rendition selector='div a'/>
  <pt:rendition selector='div ul a'/>
  <pt:rendition selector='div ul a:after;'/>
  <pt:rendition selector='.link'/>
    <sb:rendition selector=":not(:lang(en))"/>
    <sb:rendition selector=":not( :lang(   en-GB ))"/>
    <sb:rendition selector="    :lang(en-GB-x-HPf)"/>
    <sb:rendition selector=":nth-last-of-type(odd)"/>
    <sb:rendition selector=":not(head)"/>
    <sb:rendition selector="[type='blort']"/>
    <sb:rendition selector="head[type='blort']"/>
    <sb:rendition selector="head[type='blort\&apos;snort']"/>
    <sb:rendition selector='head[type="snort\&quot;blort"]'/>
    <sb:rendition selector="head[type='blort&apos;snort']"/>
    <sb:rendition selector='head[type="snort&quot;blort"]'/>
    <sb:rendition selector="::first-line"/>
    <sb:rendition selector="::after"/>
    <sb:rendition selector=":after"/>
    <sb:rendition selector="odd"/>
    <sb:rendition selector="odd"/>
    <sb:rendition selector="odd"/>
    <sb:rendition selector="odd"/>
    <sb:rendition selector='even'/>
    <sb:rendition selector="even odd"/>
    <sb:rendition selector="evenodd"/>
    <sb:rendition selector="007"/>
    <sb:rendition selector=" +15 "/>
    <sb:rendition selector=" -11 "/>
    <sb:rendition selector='+13n+12'/>
    <sb:rendition selector='+13n +12'/>
    <sb:rendition selector='+13n + 12'/>
    <sb:rendition selector='+13n +12'/>
    <sb:rendition selector="±"/>
  <wo:rendition selector="html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed, 
figure, figcaption, footer, header, hgroup, 
menu, nav, output, ruby, section, summary,
time, mark, audio, video "/>
  <wo:rendition selector="article, aside, details, figcaption, figure, 
footer, header, hgroup, menu, nav, section "/>
  <wo:rendition selector="body "/>
  <wo:rendition selector="ol, ul "/>
  <wo:rendition selector="blockquote, q "/>
  <wo:rendition selector="blockquote:before, blockquote:after,
q:before, q:after "/>
  <wo:rendition selector="table "/>
  <wo:rendition selector=".input_tiny "/>
  <wo:rendition selector=".input_small "/>
  <wo:rendition selector=".input_medium "/>
  <wo:rendition selector=".input_large "/>
  <wo:rendition selector=".input_xlarge "/>
  <wo:rendition selector=".input_xxlarge "/>
  <wo:rendition selector=".input_full "/>
  <wo:rendition selector=".input_full_wrap "/>
  <wo:rendition selector='input[type="search"]::-webkit-search-decoration '/>
  <wo:rendition selector="input:invalid,
button:invalid,
a.button:invalid,
select:invalid,
textarea:invalid "/>
  <wo:rendition selector="input:focus,
button:focus,
a.button:focus,
select:focus,
textarea:focus "/>
  <wo:rendition selector='input[type="file"]:focus, input[type="file"]:active,
input[type="radio"]:focus,
input[type="radio"]:active,
input[type="checkbox"]:focus,
input[type="checkbox"]:active '/>
  <wo:rendition selector='button,
a.button,
input[type="reset"],
input[type="submit"],
input[type="button"] '/>
  <wo:rendition selector='button:hover,
a.button:hover,
input[type="reset"]:hover,
input[type="submit"]:hover,
input[type="button"]:hover '/>
  <wo:rendition selector='button:active,
a.button:active,
input[type="reset"]:active,
input[type="submit"]:active,
input[type="button"]:active '/>
  <wo:rendition selector='button::-moz-focus-inner,
a.button::-moz-focus-inner,
input[type="reset"]::-moz-focus-inner,
input[type="submit"]::-moz-focus-inner,
input[type="button"]::-moz-focus-inner '/>
  <wo:rendition selector="a.button "/>
  <wo:rendition selector="button "/>
  <wo:rendition selector='textarea,
select,
input[type="date"],
input[type="datetime"],
input[type="datetime-local"],
input[type="email"],
input[type="month"],
input[type="number"],
input[type="password"],
input[type="search"],
input[type="tel"],
input[type="text"],
input[type="time"],
input[type="url"],
input[type="week"] '/>
  <wo:rendition selector='textarea[disabled],
select[disabled],
input[type="date"][disabled],
input[type="datetime"][disabled],
input[type="datetime-local"][disabled],
input[type="email"][disabled],
input[type="month"][disabled],
input[type="number"][disabled],
input[type="password"][disabled],
input[type="search"][disabled],
input[type="tel"][disabled],
input[type="text"][disabled],
input[type="time"][disabled],
input[type="url"][disabled],
input[type="week"][disabled] '/>
  <wo:rendition selector="button[disabled],
input[disabled],
select[disabled],
select[disabled] option,
select[disabled] optgroup,
textarea[disabled],
a.button_disabled "/>
  <wo:rendition selector="input::-webkit-input-placeholder,
textarea::-webkit-input-placeholder "/>
  <wo:rendition selector="input:-moz-placeholder,
textarea:-moz-placeholder "/>
  <wo:rendition selector="input.placeholder_text,
textarea.placeholder_text "/>
  <wo:rendition selector="textarea,
select[size],
select[multiple] "/>
  <wo:rendition selector='select[size="0"],
select[size="1"] '/>
  <wo:rendition selector='  select,
  select[size="0"],
  select[size="1"] '/>
  <wo:rendition selector="  ::-webkit-validation-bubble-message "/>
  <wo:rendition selector="  ::-webkit-validation-bubble-arrow,
  ::-webkit-validation-bubble-top-outer-arrow,
  ::-webkit-validation-bubble-top-inner-arrow "/>
  <wo:rendition selector="optgroup "/>
  <wo:rendition selector="optgroup::-moz-focus-inner "/>
  <wo:rendition selector=".ie6_button,
* html button,
* html a.button "/>
  <wo:rendition selector="* html a.button "/>
  <wo:rendition selector="* html button "/>
  <wo:rendition selector=".ie6_input,
* html textarea,
* html select "/>
  <wo:rendition selector="* html select "/>
  <wo:rendition selector=".placeholder_text,
.ie6_input_disabled,
.ie6_button_disabled "/>
  <wo:rendition selector=".ie6_input_disabled "/>
  <wo:rendition selector="body "/>
  <wo:rendition selector="body * "/>
  <wo:rendition selector="a,
a:link,
a:visited,
button.btn-link "/>
  <wo:rendition selector="a:active,
a:link:active,
a:visited:active,
button.btn-link:active,
a:focus,
a:link:focus,
a:visited:focus,
button.btn-link:focus "/>
  <wo:rendition selector="a:hover,
a:link:hover,
a:visited:hover,
button.btn-link:hover "/>
  <wo:rendition selector="a.button,
input[type='reset'],
input[type='submit'],
input[type='button'] "/>
  <wo:rendition selector="span.debug "/>
  <wo:rendition selector='.resultsHeader,
.resultsHeader-query,
div[class^="resultsHeader"],
span[class^="resultsHeader"],
.footer '/>
  <wo:rendition selector=".hidden "/>
  <wo:rendition selector=".header "/>
  <wo:rendition selector=".header .hgroup "/>
  <wo:rendition selector=".header h1 "/>
  <wo:rendition selector=".header .nav "/>
  <wo:rendition selector=".header .nav ul "/>
  <wo:rendition selector=".header .nav li "/>
  <wo:rendition selector=".header .nav li:first-child "/>
  <wo:rendition selector="#content "/>
  <wo:rendition selector=".region-heading,
.timeline .timeline-menu "/>
  <wo:rendition selector=".region-heading "/>
  <wo:rendition selector=".region-heading h2,
.region-heading h3 "/>
  <wo:rendition selector=".region-heading h2 span,
.region-heading h3 span "/>
  <wo:rendition selector=".region-heading h2 span.textName,
.region-heading h3 span.textName "/>
  <wo:rendition selector=".region-heading h2 span.textName span,
.region-heading h3 span.textName span "/>
  <wo:rendition selector=".region-heading h2 span.reader-link,
.region-heading h3 span.reader-link "/>
  <wo:rendition selector=".region-heading a "/>
  <wo:rendition selector=".region-heading a.sort-link "/>
  <wo:rendition selector=".region-heading a.sort-link:hover,
.region-heading a.sort-link:active,
.region-heading a.sort-link:focus "/>
  <wo:rendition selector=".region-heading a.close-link "/>
  <wo:rendition selector=".region-heading a.close-link:hover,
.region-heading a.close-link:active,
.region-heading a.close-link:focus "/>
  <wo:rendition selector=".region-heading a.reader-link "/>
  <wo:rendition selector=".region-heading a.reader-link:hover,
.region-heading a.reader-link:active,
.region-heading a.reader-link:focus "/>
  <wo:rendition selector=".region-heading a.intro-link "/>
  <wo:rendition selector=".region-heading a.intro-link:hover,
.region-heading a.intro-link:active,
.region-heading a.intro-link:focus "/>
  <wo:rendition selector=".region-heading a.bio-link "/>
  <wo:rendition selector=".region-heading a.bio-link:hover,
.region-heading a.bio-link:active,
.region-heading a.bio-link:focus "/>
  <wo:rendition selector=".viewer .region-heading li:first-child "/>
  <wo:rendition selector=".browser "/>
  <wo:rendition selector="#controls "/>
  <wo:rendition selector="#controls > div "/>
  <wo:rendition selector="#controls .facet "/>
  <wo:rendition selector="#controls .facet a,
#controls .facet a:hover,
#controls .facet a:link,
#controls .facet a:visited "/>
  <wo:rendition selector="#controls .facet li "/>
  <wo:rendition selector="#controls .facet .facet-count "/>
  <wo:rendition selector="#controls .facet .facet-count:before "/>
  <wo:rendition selector="#controls .facet .facet-count:after "/>
  <wo:rendition selector=".active-searches li "/>
  <wo:rendition selector=".active-searches li a "/>
  <wo:rendition selector=".active-searches li a:hover,
.active-searches li a:active,
.active-searches li a:focus "/>
  <wo:rendition selector=".search "/>
  <wo:rendition selector=".search input[type='search'] "/>
  <wo:rendition selector=".search input[type='submit'] "/>
  <wo:rendition selector=".search a "/>
  <wo:rendition selector=".search a:hover "/>
  <wo:rendition selector=".search .query "/>
  <wo:rendition selector=".search .query .label "/>
  <wo:rendition selector=".search .query .query-part "/>
  <wo:rendition selector=".search .query .query-part .subhit "/>
  <wo:rendition selector=".search .query .query-part .query-field "/>
  <wo:rendition selector=".search .query .query-part a.query-part-remove "/>
  <wo:rendition selector=".search .query .query-part a.query-part-remove:hover,
.search .query .query-part a.query-part-remove:active,
.search .query .query-part a.query-part-remove:focus "/>
  <wo:rendition selector=".search-advanced form "/>
  <wo:rendition selector=".search-advanced form input "/>
  <wo:rendition selector=".search-advanced form input[name='text'] "/>
  <wo:rendition selector=".search-advanced form input[name='year'],
.search-advanced form input[name='year-max'] "/>
  <wo:rendition selector=".search-advanced form input[type='radio'] "/>
  <wo:rendition selector=".search-advanced form fieldset "/>
  <wo:rendition selector=".search-advanced form fieldset legend "/>
  <wo:rendition selector=".search-advanced form fieldset div.field "/>
  <wo:rendition selector=".search-advanced form .form-controls "/>
  <wo:rendition selector=".search-advanced form .form-controls input "/>
  <wo:rendition selector=".search-advanced form .itemlabel "/>
  <wo:rendition selector="#preferences form "/>
  <wo:rendition selector="#preferences form .form-group "/>
  <wo:rendition selector='#preferences form input[type="checkbox"] '/>
  <wo:rendition selector="#preferences form label "/>
  <wo:rendition selector=".results,
.timeline,
.viewer "/>
  <wo:rendition selector=".results "/>
  <wo:rendition selector=".results .forms "/>
  <wo:rendition selector=".results-sort "/>
  <wo:rendition selector=".results-sort ul "/>
  <wo:rendition selector=".results-list "/>
  <wo:rendition selector=".results-list li.docHit "/>
  <wo:rendition selector=".results-list li.docHit .date-WWO,
.results-list li.docHit .genres,
.results-list li.docHit .rank "/>
  <wo:rendition selector=".results-list li.docHit .author:after "/>
  <wo:rendition selector=".results-list li.docHit .title a "/>
  <wo:rendition selector=".results-list li.docHit .date-original:before "/>
  <wo:rendition selector=".results-list li.docHit .hits "/>
  <wo:rendition selector=".results-list li.docHit .hits .hits-val "/>
  <wo:rendition selector=".results-list li.docHit .hits,
.results-list li.docHit .snippet "/>
  <wo:rendition selector=".results-list li.docHit .snippets "/>
  <wo:rendition selector=".results-list li.docHit .snippets .snippet "/>
  <wo:rendition selector=".results-list li.docHit .snippets .snippet:before,
.results-list li.docHit .snippets .snippet:after "/>
  <wo:rendition selector=".results-list li.docHit .snippets .snippet .hit "/>
  <wo:rendition selector=".timeline "/>
  <wo:rendition selector=".timeline .timeline-menu a.timeline-reset "/>
  <wo:rendition selector=".timeline .timeline-menu a.timeline-reset:hover,
.timeline .timeline-menu a.timeline-reset:active,
.timeline .timeline-menu a.timeline-reset:focus "/>
  <wo:rendition selector=".timeline .timeline-content "/>
  <wo:rendition selector="#loader "/>
  <wo:rendition selector=".wwuniverse "/>
  <wo:rendition selector=".wwuniverse button.btn-link.wwu-expander "/>
  <wo:rendition selector=".wwuniverse button.btn-link.wwu-expander:active,
.wwuniverse button.btn-link.wwu-expander:focus "/>
  <wo:rendition selector=".wwuniverse button.btn-link.wwu-expander:hover "/>
  <wo:rendition selector=".wwuniverse .wwu-link a "/>
  <wo:rendition selector=".wwuniverse .wwuniverse-review .title-rcvd "/>
  <wo:rendition selector=".viewer "/>
  <wo:rendition selector=".viewer.active "/>
  <wo:rendition selector="browser.hidden + .viewer.fullview-mode "/>
  <wo:rendition selector=".viewer.fullview-mode .content "/>
  <wo:rendition selector=".viewer .viewer-inner "/>
  <wo:rendition selector=".viewer .viewer-inner .viewer-content "/>
  <wo:rendition selector=".viewer .viewer-inner p.error "/>
  <wo:rendition selector=".viewer .viewer-inner p.error br "/>
  <wo:rendition selector="#tooltip "/>
  <wo:rendition selector="#popup "/>
  <wo:rendition selector="#popup .popup-arrow "/>
  <wo:rendition selector="#popup .popup-arrow.down "/>
  <wo:rendition selector="#popup .popup-arrow.left "/>
  <wo:rendition selector="#popup .popout "/>
  <wo:rendition selector="#popup > div.note.content "/>
  <wo:rendition selector="#popup > div.note.content:focus "/>
  <wo:rendition selector="#popup > div.note.content > .note-WWP "/>
  <wo:rendition selector="#popup > div.note.content > .note-WWP:before "/>
  <wo:rendition selector="#overlay "/>
  <wo:rendition selector=".feedback "/>
  <wo:rendition selector=".feedback .feedback-handle button "/>
  <wo:rendition selector=".feedback .feedback-handle button:active,
.feedback .feedback-handle button:hover,
.feedback .feedback-handle button:focus "/>
  <wo:rendition selector="#popup .feedback-content h2 "/>
  <wo:rendition selector="#popup .feedback-content p "/>
  <wo:rendition selector="#popup .feedback-content a,
#popup .feedback-content a:link,
#popup .feedback-content a:visited "/>
  <wo:rendition selector="#popup .feedback-content a:hover,
#popup .feedback-content a:link:hover,
#popup .feedback-content a:visited:hover "/>
  <wo:rendition selector=":lang(en) > .title-a,
:lang(en) > .title-u,
:lang(en) > *[class~='Qboth'],
:lang(en) > *[class~='Qbefore'],
:lang(en) > *[class~='Qafter'] "/>
  <wo:rendition selector=":lang(fr) > .title-a,
:lang(fr) > .title-u,
:lang(fr) > *[class~='Qboth'],
:lang(fr) > *[class~='Qbefore'],
:lang(fr) > *[class~='Qafter'] "/>
  <wo:rendition selector=":lang(de) > .title-a,
:lang(de) > .title-u,
:lang(de) > *[class~='Qboth'],
:lang(de) > *[class~='Qbefore'],
:lang(de) > *[class~='Qafter'] "/>
  <wo:rendition selector="*[class~='Qboth']:before,
*[class~='Qbefore']:before,
*[class~='Qafter']:before "/>
  <wo:rendition selector="*[class~='Qboth']:after,
*[class~='Qbefore']:after,
*[class~='Qafter']:after "/>
  <wo:rendition selector="*[class~='noQs']:after,
*[class~='Qbefore']:after "/>
  <wo:rendition selector="*[class~='noQs']:before,
*[class~='Qafter']:before "/>
  <wo:rendition selector=".content "/>
  <wo:rendition selector=".viewer-content > .content,
.note.content "/>
  <wo:rendition selector=".content "/>
  <wo:rendition selector=".content div[align='center'] "/>
  <wo:rendition selector=".content div[class|='div'] "/>
  <wo:rendition selector=".content a[target],
.content a.prevHit,
.content a.nextHit "/>
  <wo:rendition selector=".content a[target] img,
.content a.prevHit img,
.content a.nextHit img "/>
  <wo:rendition selector=".content .hitsection "/>
  <wo:rendition selector=".content .hitsection:hover "/>
  <wo:rendition selector=".content .p "/>
  <wo:rendition selector=".content ul "/>
  <wo:rendition selector=".content ul.subscriber ul "/>
  <wo:rendition selector=".content dl "/>
  <wo:rendition selector=".content dt "/>
  <wo:rendition selector=".content dd "/>
  <wo:rendition selector=".content dd:after "/>
  <wo:rendition selector=".content div[class^='head'],
.content p[class^='head'],
.content span[class^='head'] "/>
  <wo:rendition selector=".content div[class^='head'] *[class^='head'],
.content p[class^='head'] *[class^='head'],
.content span[class^='head'] *[class^='head'] "/>
  <wo:rendition selector=".content .emph,
.content .foreign "/>
  <wo:rendition selector=".content .bibl.it,
.content .gloss.it,
.content .mcr.it,
.content .measure.it,
.content .mentioned.it,
.content .name.it,
.content .orgName.it,
.content .persName.it,
.content .placeName.it,
.content .quote.it,
.content .soCalled.it,
.content .term.it "/>
  <wo:rendition selector=".content .bibl.ro,
.content .gloss.ro,
.content .mcr.ro,
.content .measure.ro,
.content .mentioned.ro,
.content .name.ro,
.content .orgName.ro,
.content .persName.ro,
.content .placeName.ro,
.content .quote.ro,
.content .soCalled.ro,
.content .term.ro "/>
  <wo:rendition selector=".content .it .ro "/>
  <wo:rendition selector=".content span.choice "/>
  <wo:rendition selector=".content span.choice > span.abbr,
.content span.choice > span.orig,
.content span.choice > span[class*='sic'] "/>
  <wo:rendition selector=".content.with-sic span.choice > span.expan,
.content.with-sic span.choice > span.reg,
.content.with-sic span.choice > span.corr "/>
  <wo:rendition selector=".content.with-sic span.choice > span.abbr,
.content.with-sic span.choice > span.orig,
.content.with-sic span.choice > span[class*='sic'] "/>
  <wo:rendition selector=".content .icor-orig "/>
  <wo:rendition selector=".content.with-typography .icor-orig "/>
  <wo:rendition selector=".content.with-typography .icor-reg "/>
  <wo:rendition selector=".content br "/>
  <wo:rendition selector=".content .mw-border,
.content .mw-catch,
.content .mw-lineNum,
.content .mw-pageNum,
.content .mw-pressFig,
.content .mw-sig,
.content .mw-vol,
.content .mw-listHead "/>
  <wo:rendition selector=".content .pb "/>
  <wo:rendition selector=".content .milestone-sig "/>
  <wo:rendition selector=".content .quote span[class^='lg'] "/>
  <wo:rendition selector=".content .quote span[class^='lg'] .l "/>
  <wo:rendition selector=".content div[class^='lg-poem'],
.content span[class^='lg-poem'] "/>
  <wo:rendition selector=".content .l,
.content .l-inline "/>
  <wo:rendition selector=".content .lng,
.content .lnl,
.content .lnr "/>
  <wo:rendition selector=".content .castItem "/>
  <wo:rendition selector=".content span[class^='stage'] "/>
  <wo:rendition selector=".content span[class^='stage']:before "/>
  <wo:rendition selector=".content span[class^='stage']:after "/>
  <wo:rendition selector=".content .sp "/>
  <wo:rendition selector=".content .sp .speaker "/>
  <wo:rendition selector=".content .sp .speaker .note "/>
  <wo:rendition selector=".content .sp span[class^='stage'] "/>
  <wo:rendition selector=".content .epigraph .bibl "/>
  <wo:rendition selector=".content .epigraph .p .bibl "/>
  <wo:rendition selector=".content .label "/>
  <wo:rendition selector=".content .date .temporal,
.content .docDate .temporal,
.content .date span[class^='temporal'],
.content .docDate span[class^='temporal'] "/>
  <wo:rendition selector=".content *[class|='titleBlock'] "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .titlePart,
.content *[class|='titleBlock'] .titlePart-address,
.content *[class|='titleBlock'] .titlePart-alt,
.content *[class|='titleBlock'] .titlePart-desc,
.content *[class|='titleBlock'] .titlePart-main,
.content *[class|='titleBlock'] .titlePart-second,
.content *[class|='titleBlock'] .titlePart-sub,
.content *[class|='titleBlock'] .titlePart-vol "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .titlePart,
.content *[class|='titleBlock'] .titlePart-main "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .titlePart-address,
.content *[class|='titleBlock'] .titlePart-alt,
.content *[class|='titleBlock'] .titlePart-desc,
.content *[class|='titleBlock'] .titlePart-second,
.content *[class|='titleBlock'] .titlePart-sub "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .titlePart-vol "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .docImprint "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .respLine "/>
  <wo:rendition selector=".content *[class|='titleBlock'] br "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .imprimatur "/>
  <wo:rendition selector=".content *[class|='titleBlock'] ul "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph .bibl "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph br "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph p[class^='lg'] br "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph .p "/>
  <wo:rendition selector=".content *[class|='titleBlock'] .epigraph .p .bibl "/>
  <wo:rendition selector=".content .title,
.content .title-m,
.content .title-s,
.content .title-j,
.content .title-X "/>
  <wo:rendition selector=".content :lang(en) > .title-a,
.content :lang(en) > .title-u "/>
  <wo:rendition selector=".content :lang(fr) > .title-a,
.content :lang(fr) > .title-u "/>
  <wo:rendition selector=".content :lang(de) > .title-a,
.content :lang(de) > .title-u "/>
  <wo:rendition selector=".content .title-a:before,
.content .title-u:before "/>
  <wo:rendition selector=".content .title-a:after,
.content .title-u:after "/>
  <wo:rendition selector=".content .opener "/>
  <wo:rendition selector=".content .opener .salute "/>
  <wo:rendition selector=".content .opener .dateline "/>
  <wo:rendition selector=".content .trailer "/>
  <wo:rendition selector=".content .closer,
.content .signed "/>
  <wo:rendition selector=".content .closer br,
.content .signed br "/>
  <wo:rendition selector=".content .figure "/>
  <wo:rendition selector=".content .figure:before "/>
  <wo:rendition selector=".content .figure p[class^='head'] "/>
  <wo:rendition selector=".content .figure .figDesc"/>
  <wo:rendition selector=".content .figure .floatingText "/>
  <wo:rendition selector=".content .figure .ab-caption "/>
  <wo:rendition selector=".content .figure .ab-caption:before "/>
  <wo:rendition selector=".content .argument "/>
  <wo:rendition selector=".content .argument p[class^='head'] "/>
  <wo:rendition selector=".content .argument .p "/>
  <wo:rendition selector=".content td "/>
  <wo:rendition selector=".content .rdg:before "/>
  <wo:rendition selector=".content .rdg:after "/>
  <wo:rendition selector=".content .add,
.content .hw "/>
  <wo:rendition selector=".content .add:before,
.content .hw:before "/>
  <wo:rendition selector=".content .add:after,
.content .hw:after "/>
  <wo:rendition selector=".content .del "/>
  <wo:rendition selector=".content span[class^='space'] "/>
  <wo:rendition selector=".content span[class^='gap'] "/>
  <wo:rendition selector=".content span[class^='gap']:before "/>
  <wo:rendition selector=".content span[class^='gap']:after "/>
  <wo:rendition selector=".content span[class^='gap'] span.attr-reason "/>
  <wo:rendition selector=".content .anchor "/>
  <wo:rendition selector=".content .popout,
.content span.hi-xmp-note "/>
  <wo:rendition selector=".content .popout "/>
  <wo:rendition selector=".content .popout > * "/>
  <wo:rendition selector=".content span.hi-xmp-note "/>
  <wo:rendition selector=".content .note span[class^='attr'],
.content *[class^='note'] span[class^='attr'],
.content .note span[class^='note'],
.content *[class^='note'] span[class^='note'],
.content .note span[class^='head'],
.content *[class^='note'] span[class^='head'] "/>
  <wo:rendition selector=".content .endnotes .note,
.content .div-endnotes .note "/>
  <wo:rendition selector=".content .endnotes .note > .p,
.content .div-endnotes .note > .p,
.content .endnotes .note > a,
.content .div-endnotes .note > a,
.content .endnotes .note span[class^='head'],
.content .div-endnotes .note span[class^='head'] "/>
  <wo:rendition selector=".content .endnotes .note > a:hover,
.content .div-endnotes .note > a:hover "/>
  <wo:rendition selector=".content .note-WWP "/>
  <wo:rendition selector=".content .text-manuscript "/>
  <wo:rendition selector=".content .text-manuscript *[class~='noQs'],
.content .text-manuscript *[class~='Qboth'],
.content .text-manuscript *[class~='Qbefore'],
.content .text-manuscript *[class~='Qafter'] "/>
  <wo:rendition selector=".content .text-manuscript *[class~='noQs']:before,
.content .text-manuscript *[class~='Qboth']:before,
.content .text-manuscript *[class~='Qbefore']:before,
.content .text-manuscript *[class~='Qafter']:before "/>
  <wo:rendition selector=".content .text-manuscript *[class~='noQs']:after,
.content .text-manuscript *[class~='Qboth']:after,
.content .text-manuscript *[class~='Qbefore']:after,
.content .text-manuscript *[class~='Qafter']:after "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote a[target] "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote > * "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote > table td "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote > table td + td "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote > .p "/>
  <wo:rendition selector=".content .text-manuscript .note-headnote > .p .cit "/>
  <wo:rendition selector='.content .text-manuscript .note-headnote span[class="label it"] '/>
  <wo:rendition selector=".content .text-manuscript .mw-pageNum "/>
  <wo:rendition selector=".content .text-manuscript span[class|='pb'] "/>
  <wo:rendition selector=".content .text-manuscript span.pb-HM:before "/>
  <wo:rendition selector=".content .text-manuscript span.pb-BP:before "/>
  <wo:rendition selector=".content .text-manuscript span.pb-GT:before "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice']:before "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice']:after"/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice'] > span.sic:before,
.content .text-manuscript span[class~='choice'] > span.corr:before,
.content .text-manuscript span[class~='choice'] > span.orig:before,
.content .text-manuscript span[class~='choice'] > span[class|='reg']:before,
.content .text-manuscript span[class~='choice'] > span[class~='reg']:before,
.content .text-manuscript span[class~='choice'] > span.abbr:before,
.content .text-manuscript span[class~='choice'] > span.expan:before,
.content .text-manuscript span[class~='choice'] > span.unclear:before,
.content .text-manuscript span[class~='choice'] > span.seg:before "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice'] > span.sic:first-child,
.content .text-manuscript span[class~='choice'] > span.corr:first-child,
.content .text-manuscript span[class~='choice'] > span.orig:first-child,
.content .text-manuscript span[class~='choice'] > span[class|='reg']:first-child,
.content .text-manuscript span[class~='choice'] > span[class~='reg']:first-child,
.content .text-manuscript span[class~='choice'] > span.abbr:first-child,
.content .text-manuscript span[class~='choice'] > span.expan:first-child,
.content .text-manuscript span[class~='choice'] > span.unclear:first-child,
.content .text-manuscript span[class~='choice'] > span.seg:first-child "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice'] > span.sic:first-child:before,
.content .text-manuscript span[class~='choice'] > span.corr:first-child:before,
.content .text-manuscript span[class~='choice'] > span.orig:first-child:before,
.content .text-manuscript span[class~='choice'] > span[class|='reg']:first-child:before,
.content .text-manuscript span[class~='choice'] > span[class~='reg']:first-child:before,
.content .text-manuscript span[class~='choice'] > span.abbr:first-child:before,
.content .text-manuscript span[class~='choice'] > span.expan:first-child:before,
.content .text-manuscript span[class~='choice'] > span.unclear:first-child:before,
.content .text-manuscript span[class~='choice'] > span.seg:first-child:before "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice'] > span.corr,
.content .text-manuscript span[class~='choice'] > span.expan,
.content .text-manuscript span[class~='choice'] > span.seg,
.content .text-manuscript span[class~='choice'] > span[class|='reg'],
.content .text-manuscript span[class~='choice'] > span[class~='reg'] "/>
  <wo:rendition selector=".content .text-manuscript span[class~='choice'] > span.sic,
.content .text-manuscript span[class~='choice'] > span.orig,
.content .text-manuscript span[class~='choice'] > span.abbr,
.content .text-manuscript span[class~='choice'] > span.unclear,
.content .text-manuscript span[class~='choice'] > span.seg "/>
  <wo:rendition selector=".content .text-manuscript .add:before "/>
  <wo:rendition selector=".content .text-manuscript .add:after "/>
  <wo:rendition selector=".content .text-manuscript span[class^='gap'] "/>
  <wo:rendition selector=".content .text-manuscript span[class^='gap']:before "/>
  <wo:rendition selector=".content .text-manuscript span[class^='gap']:after "/>
  <wo:rendition selector=".content .text-manuscript span.gap-handwriting-GT "/>
  <wo:rendition selector=".content .text-manuscript .supplied:before "/>
  <wo:rendition selector=".content .text-manuscript .supplied:after "/>
  <wo:rendition selector=".content #TR00590 .div-corrigenda .seg.sameAs "/>
  <wo:rendition selector="#popup > div.note.content > * span.note "/>
  <wo:rendition selector="#popup > div.note.content .bibl-sref "/>
  <wo:rendition selector='#popup > div.note.content .bibl-sref span[class~="moo"],
#popup > div.note.content .bibl-sref-parenless span[class~="moo"] '/>
  <wo:rendition selector=""/>
  </xsl:template>
</xsl:stylesheet>
