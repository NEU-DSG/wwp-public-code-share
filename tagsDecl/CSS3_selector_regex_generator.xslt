<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:out="http://www.w3.org/1999/XSL/Transform-NOT!"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:sb="http://bauman.zapto.org/ns-for-testing-CSS"
  xmlns:wi="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:ws="http://www.wwp-test.northeastern.edu/"
  xmlns:wpt="https://github.com/web-platform-tests/wpt"
  xmlns:w3c="https://www.w3.org/Style/CSS/Test/CSS3/Selectors/current/"
  xmlns:wo="http://wwo.wwp-test.northeastern.edu/WWO/css/wwo/wwo.css"
  xmlns:pt="https://github.com/benfrain/css-performance-tests"
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:namespace-alias stylesheet-prefix="out" result-prefix="xsl"/>
  <xsl:param name="output" as="xs:string" select="'Relax NG'"/>
  <xsl:variable name="outLang">
    <xsl:choose>
      <xsl:when test="$output = ('rng','rnc','RNG','RNC','RELAXNG','RELAX NG','RelaxNG','Relax NG','http://relaxng.org/ns/structure/1.0')">RNG</xsl:when>
      <xsl:when test="$output = ('xsl','xslt','XSL','XSLT','http://www.w3.org/1999/XSL/Transform')">XSL</xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes" select="'Fatal error: output type '||$output||' not recognized.'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
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
    <xsl:template match="/">
      <xsl:message select="$regexp"/>
    </xsl:template> 
</xsl:stylesheet>
