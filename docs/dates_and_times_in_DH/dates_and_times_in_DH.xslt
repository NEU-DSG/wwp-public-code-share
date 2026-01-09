<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:teix="http://www.tei-c.org/ns/Examples"
    xmlns:eg="http://www.tei-c.org/ns/Examples"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:wd="http://www.wwp.northeastern.edu/ns/internal_documentation/1.0"
    exclude-result-prefixes="#all"
    version="3.0">

  <!--
    dates_and_times_in_DH.xslt: © 2025 Syd Bauman
    Available under terms like those of the TEI Stylesheets:
    1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License http://creativecommons.org/licenses/by-sa/3.0/ 
    2. http://www.opensource.org/licenses/BSD-2-Clause
    So pretty much do whatever you want with it so long as you give me credit for writing it.
  -->

  <!--
    This is intended as a (perhaps temporary) one-off wrapper/driver
    of the TEI Stylesheets for the particular use case of the “Dates
    and Times in DH: An annotated application profile of ISO 8601:2019
    for use with TEI and other DH systems” document. Mostly it loads
    the main TEI convert-to-HTML5 stylesheet, and then re-defines the
    templates used in generation of examples (i.e., <egXML>).

    It is (very heavily) based on checking_pointers_in_ODD.xslt.
    
    To use THIS method of generating HTML for dates_and_times_in_DH:
    a) change the path in the <xsl:import> to the correct path on your system
    b) issue something like the following, with the paths corrected to your local system:
    `saxon -xsl:./dates_and_times_in_DH.xslt -s:./dates_and_times_in_DH.tei -o:./dates_and_times_in_DH.html cssInlineFiles='/home/syd/Documents/WWPweb/research/publications/documentation/other/dates_and_times_in_DH.css' numberBackFigures='true' showTitleAuthor='true' generationComment='true' verbose='true' footnoteBackLink='true' wrapLength=650 attLength=400`
    
    To use the “normal” stylesheets try
    `saxon -xsl:/PATH/TO/Stylesheets/profiles/default/html5/to.xsl -s:./dates_and_times_in_DH.xml -o:./dates_and_times_in_DH.html numberBackFigures='true' showTitleAuthor='true' generationComment='true' verbose='true' footnoteBackLink='true'`

    To use the “normal” stylesheets the way I generate proofing copies
    see the header comment to the dates_and_times_in_DH.tei file.
  -->
  
  <xsl:import href="/home/syd/Documents/Stylesheets/profiles/default/html5/to.xsl"/>
  <!--
      Of course it would be preferable to grab stylesheet off the web:
      <xsl:import href=
      "https://tei-c.org/Vault/Stylesheets/7.52.0/xml/tei/stylesheet/profiles/default/html5/to.xsl"
      />
      But that screws up the relative link to CSS.
  -->

  <!-- Standard TEI strips some spaces we need to keep. (In
       particular, we need to preserve the spaces inside every <egXML>
       *and* anything that could be its parent element, in this case
       only <figure>): -->
  <xsl:preserve-space elements="tei:figure teix:*"/>

  <!-- Are we generating output for use on WWP website? -->
  <xsl:param name="wwp" select="false()" as="xs:boolean" static="true"/>
  <xsl:param name="returnString" select="'go back to text'" as="xs:string"/>
  
  <!-- Just easier to process LIT and LITA if you have variables: -->
  <xsl:variable name="quot" select="'&quot;'"/>
  <xsl:variable name="apos" select='"&apos;"'/>

  <!-- Take advantage of TEI hook to insert WWP SSI statements. -->
  <xsl:template name="headHook">
    <xsl:choose>
      <xsl:when test="$wwp">
        <xsl:comment>#include virtual="../../../../utils/includes/scripts.ssi"</xsl:comment>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:comment>#include virtual="../../../../utils/includes/styles.ssi"</xsl:comment>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment> NOT including WWP scripts &amp; styles (set $wwp paramater to true() if you want them.) </xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Nuke the TEI standard footer, as we already inserted the WWP
       standard footer as last child if div.frame in "simpleBody". -->
  <xsl:template name="stdfooter"/>

  <!-- Replace TEI "simpleBody" template so we can insert (weird)
       extra levels of <div> nesting WWP styling requires -->
  <xsl:template name="simpleBody" use-when="$wwp">
    <div class="frame">
      <xsl:comment>#include virtual="../../../../utils/includes/banner.ssi"</xsl:comment>
      <div class="main">
        <xsl:comment>#include virtual="../../../../utils/includes/area_navigation.ssi"</xsl:comment>
        <div class="content">
          <xsl:comment> TEI &lt;front> (from dates_and_times_in_DH.xslt version of "simpleBody" template) </xsl:comment>
          <xsl:apply-templates select="tei:text/tei:front"/>
          <xsl:if test="$autoToc = 'true' and (descendant::tei:div or descendant::tei:div1) and not(descendant::tei:divGen[@type = 'toc'])">
            <h2><xsl:sequence select="tei:i18n('tocWords')"/></h2>
            <xsl:call-template name="mainTOC"/>
          </xsl:if>
          <xsl:comment> TEI &lt;body> (from dates_and_times_in_DH.xslt version of "simpleBody" template) </xsl:comment>
          <xsl:apply-templates select="tei:text/tei:body"/>
          <xsl:comment> TEI &lt;back> (from dates_and_times_in_DH.xslt version of "simpleBody" template) </xsl:comment>
          <xsl:apply-templates select="tei:text/tei:back"/>
          <xsl:call-template name="printNotes"/>
        </div>
      </div>
      <xsl:comment>#include virtual="../../../../utils/includes/footer.ssi"</xsl:comment>
    </div>
  </xsl:template>

  <!-- Override standard TEI TOC generation so we can make ours easily collapsable. -->
  <xsl:template match="tei:divGen[ @type eq 'toc']">
    <div class="tei_toc">
      <summary class="TOC">
        <xsl:sequence select="tei:i18n('tocWords')"/>
      </summary>
      <details class="TOC">
	<xsl:call-template name="mainTOC"/>
      </details>
    </div>
  </xsl:template>

  <!-- OVerride standard TEI generation of footnotes so we can use an accessible return link -->
  <xsl:template name="makeaNote">
    <xsl:variable name="identifier">
      <xsl:call-template name="noteID"/>
    </xsl:variable>
    <xsl:if test="$verbose='true'">
      <xsl:message>Make note <xsl:value-of select="$identifier"/></xsl:message>
    </xsl:if>
    <div class="note">
      <xsl:if test="$identifier castable as xs:integer  and  10 > $identifier">
	<xsl:text>&#x2007;</xsl:text>
      </xsl:if>
      <xsl:call-template name="makeAnchor">
        <xsl:with-param name="name" select="$identifier"/>
      </xsl:call-template>
      <span class="noteLabel">
        <xsl:call-template name="noteN"/>
        <xsl:if test="matches(@n,'[0-9]')">
          <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:text> </xsl:text>
      </span>
      <div class="noteBody">
        <xsl:apply-templates/>
      </div>
      <xsl:if test="$footnoteBackLink= 'true'">
        <xsl:text> </xsl:text>
        <a class="link_return" title="Go back to text" href="#{concat($identifier,'_return')}">
	  <xsl:sequence select="$returnString"/>
	</a>
      </xsl:if>
    </div>
  </xsl:template>
  
  <!-- Our local <fix> and <var> elements need to be handled (but are easy) -->
  <xsl:template match="wd:fix|wd:var" expand-text="yes">
    <span class="{local-name(.)}">{.}</span>
  </xsl:template>
  
  <!-- Completely replace standard TEI processing of <egXML>. -->
  <!--
    Basic idea: When we hit an <egXML> remember the string of whitespace that immediately
    precedes the start tag. Then subtract that string from the whitespace that immediately
    precedes any child elements, so they are indented in the output only as much as they
    are indented beyond the “base” in the source XML.
  -->
  <xsl:template match="teix:egXML">
    <!--
      Note: at the moment the following definition of
      $whitespace_B4_me would fail if the whitespace before the
      <egXML> start-tag did not contain a newline (or something
      else that was NOT space or tab). At the WWP (from where this
      code is adopted) this is not supposed to happen (and is enforced
      by a <constraintSpec>), but here in TEI-land we may have code
      around it at some point. —Syd, 2022-01-14
    -->
    <xsl:variable name="whitespace_B4_me"
                  select="if (@xml:space eq 'preserve')
                          then ''
                          else
                            replace(
                              preceding-sibling::node()[1][self::text()],
                              '^.*[^&#x20;&#x09;]([&#x20;&#x09;]+)$',
                              '$1',
                              's'
                            )" />
    <pre>
      <xsl:copy-of select="@xml:lang|@xml:base|@style"/>
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <xsl:attribute name="class" select="if (@valid)
                                          then local-name(.)||'_'||@valid
                                          else local-name(.)"/>
      <xsl:apply-templates select="node()" mode="eg">
        <xsl:with-param name="spaceB4eg" select="$whitespace_B4_me" tunnel="yes"/>
      </xsl:apply-templates>
    </pre>
    <xsl:if test=".//text()[ ends-with( ., '&#x200B;')  or starts-with( ., '&#x200B;') ]">
      <p class="fineprint">Warning: this example uses an invisible character (ZERO WIDTH SPACE, U+200B) for formatting.</p>
    </xsl:if>
  </xsl:template>

  <!-- Element inside an <egXML>: -->
  <xsl:template match="*" mode="eg">
    <xsl:param name="spaceB4eg" tunnel="yes"/>
    <!-- Use different classes (and thus colors) for TEI vs non-TEI namespaces: -->
    <xsl:variable name="class" select="if ( self::teix:* ) then 'eg-tei' else 'eg-tag'"/>
    <span class="{$class}">
      <!-- I do not understand why, but using <xsl:sequence> here
           results in extraneous whitespace. -->
      <xsl:value-of select="'&lt;'||name(.)"/>
      <xsl:apply-templates select="@*" mode="eg"/>
      <!-- If I am empty, we will use self-closing syntax later: -->
      <xsl:value-of select="if (child::node()) then '>' else ''"/>
    </span>
    <xsl:apply-templates select="node()" mode="eg">
      <xsl:with-param name="spaceB4eg" select="$spaceB4eg"/>
    </xsl:apply-templates>
    <span class="{$class}">
      <!-- If I am empty use self-closing syntax: -->
      <xsl:value-of select="if (child::node())
                            then '&lt;/'||name(.)||'>'
                            else '/>'"/>
    </span>
  </xsl:template>

  <!-- Attributes on descendants of <egXML> (not on <egXML> itself): -->
  <xsl:template match="@*" mode="eg">
    <xsl:param name="spaceB4eg" tunnel="yes"/>
    <xsl:sequence select="'&#x20;'"/>
    <span class="eg-attrName">
      <xsl:sequence select="name(.)||'='"/>
    </span>
    <span class="eg-attrVal">
      <!--
        Use the LIT delimiter (a &quot;) unless there is a &quote; in the value,
        in which case use LITA (an &apos;).
      -->
      <xsl:variable name="LITa" select="if (contains( .,'&quot;')) then $apos else $quot"/>
      <!-- Unlike oXygen, use a separate class (and thus color) for attr delimeters: -->
      <span class="eg-lit"><xsl:sequence select="$LITa"/></span>
      <!--
        Newlines in attribute values have already been converted to spaces. (See section
        3.3.3 of the XML spec.) What a pain, we want to reflect them here. So take a
        guess that for any sequence of spaces that is *longer* than the space we are
        stripping off the first space should probably be a newline instead.
      -->
      <xsl:variable name="regex" select="' '||$spaceB4eg||'( *)'"/>
      <xsl:analyze-string select="." regex="{$regex}">
        <xsl:matching-substring>
          <br/>
          <xsl:sequence select="translate( regex-group(1), '&#x20;','&#xA0;')"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
      </xsl:analyze-string>
      <!-- Unlike oXygen, use a separate class (and thus color) for attr delimeters: -->
      <span class="eg-lit"><xsl:sequence select="$LITa"/></span>
    </span>
  </xsl:template>

  <!-- Processing instruction descendants of <egXML>: -->
  <xsl:template match="processing-instruction()" mode="eg">
    <xsl:param name="spaceB4eg" tunnel="yes"/>
    <xsl:variable name="pi" select="replace( ., '&#x0A;'||$spaceB4eg, '&#x0A;')"/>
    <span class="eg-pi">
      <xsl:sequence select="'&lt;?'||name(.)||'&#x20;'||$pi||'?>'"/>
    </span>
  </xsl:template>
  
  <!-- Comment descendants of <egXML>: -->
  <xsl:template match="comment()" mode="eg">
    <xsl:param name="spaceB4eg" tunnel="yes"/>
    <span class="eg-com">
      <xsl:variable name="com" select="replace( ., '&#x0A;'||$spaceB4eg, '&#x0A;')"/>
      <xsl:sequence select="'&lt;!--'||$com||'-->'"/>
    </span>
  </xsl:template>

  <xsl:template match="text()" mode="eg">
    <xsl:param name="spaceB4eg" tunnel="yes"/>
    <!-- 
      First, decide what we should be considering as this node’s
      string value. If @xml:space is "preserve", just consider exactly
      what the string value of this node is. But IF @xml:space is NOT
      "preserve", AND we are a child (not descendant) of the
      <egXML>, AND we are either the very first or the very last
      child, THEN nuke the newlines first, and consider the result to
      be our value.

      The purpose here is to avoid an empty line at the top or bottom
      of the output box that contains the example, unless (of course)
      the user explicitly asked for it.
    -->
    <xsl:variable name="me" as="xs:string">
      <xsl:choose>
        <xsl:when test="ancestor::*[@xml:space][1]/@xml:space eq 'preserve'">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:when test="parent::teix:egXML|parent::eg">
          <xsl:value-of select="if ( preceding-sibling::node() and following-sibling::node() )
                                then .
                                else translate( ., '&#x0A;','')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <span class="eg-content">
      <!-- 
        Parse our considered value around the last line feed.
        Note that we are examining our actual value, not the
        "consider me" value, which may no longer have a linefeed!
      -->
      <xsl:analyze-string select="." regex="^(.*)&#x0A;([^&#x0A;]*)$" flags="s">
        <xsl:matching-substring>
          <xsl:variable name="pre"  select="regex-group(1)"/>
          <xsl:variable name="post" select="regex-group(2)"/>
          <!-- 
            Remove the same amount of whitespace that appeared immediately
            before our ancestor <egXML> from *after* the last linefeed.
          -->
          <xsl:variable name="new"  select="replace( $post, '^'||$spaceB4eg, '')"/>
          <xsl:sequence
            select="if ( . eq $me )
                    then $pre||'&#x0A;'||$new
                    else $pre||$new"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <!-- No linefeed, just output the considered text. -->
          <xsl:sequence select="$me"/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </span>
  </xsl:template>

  <!--
      Override processing of an expanded abbreviation in the title
      (Turns out this is not needed, as we take our main <h1> title
      from the title page, not the metadata.)
  -->
  <xsl:template match="tei:titleStmt/tei:title//tei:choice[tei:abbr and tei:expan]">
    <xsl:apply-templates select="tei:abbr" mode="simple"/>
  </xsl:template>

  <xsl:template match="tei:titlePart/tei:title[ @type ]">
    <xsl:call-template name="makeInline">
      <xsl:with-param name="style">
	<xsl:value-of select="('titlem', @type, @rend )" separator=" "/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
