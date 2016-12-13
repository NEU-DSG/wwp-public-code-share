<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  exclude-result-prefixes="xs xsl wwp wf"
  xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
  version="2.0">
  
  <!-- 
    This stylesheet creates a version of a WWO text suitable for full-text indexing, 
    and any other activity where having access to semi-regularized, complete words 
    might be useful. 
    
    Author: Ashley M. Clark
  -->
  
  <xsl:output indent="no"/>
  
  <!-- PARAMETERS -->
  
  <!-- Parameter option to keep/remove WWP-created content within <text>, such as 
    <note type="WWP"> and <figDesc>. The default is to keep WWP content. -->
  <xsl:param name="keep-wwp-text"               as="xs:boolean" select="true()"/>
  
  <!-- Parameter option to keep/remove <lb>s and <cb>s from output. The default is 
    to keep them. -->
  <xsl:param name="keep-line-and-column-breaks" as="xs:boolean" select="true()"/>
  
  
  <!-- FUNCTIONS -->
  
  <xsl:function name="wf:get-first-word" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:variable name="slim-text" select="normalize-space($text)"/>
    <xsl:variable name="pattern">
      <xsl:text>^\s*([\w'-]+[\.,;:!?”/)\]]?)((\s+|[―—]*|-{2,}).*)?$</xsl:text>
    </xsl:variable>
    <xsl:value-of select="replace($slim-text, $pattern, '$1')"/>
  </xsl:function>
  
  <xsl:function name="wf:is-pbGroup-candidate" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:value-of select="exists( $node[  self::mw[@type = ('catch', 'pageNum', 'sig', 'vol')] 
                                       (: The XPath above tests for mw with types that could trigger a pbGroup. 
                                          The XPath below tests for mw that could belong to a pbGroup. :)
                                       or self::mw[@type = ('border', 'border-ornamental', 'border-rule', 'other', 'pressFig', 'unknown')]
                                       or self::pb 
                                       or self::milestone
                                       or self::text()[normalize-space() eq ''] ] )"/>
  </xsl:function>
  
  <xsl:function name="wf:remove-shy" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:value-of select="replace($text,'@\s*','')"/>
  </xsl:function>
  
  
  <!-- TEMPLATES -->
  
  <xsl:template match="/">
    <xsl:variable name="first-pass">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:apply-templates select="$first-pass" mode="unifier"/>
  </xsl:template>
  
  <!-- Copy the element and its attributes, but none of its descendants. -->
  <xsl:template name="not-as-shallow-copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Copy the element and its attributes, and add @read on any text content. -->
  <xsl:template name="read-as-copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="node()">
        <xsl:attribute name="read" select="data(.)"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- OPTIONAL: remove WWP text content. -->
  
  <!-- If requested, remove the content of WWP notes and <figDesc>s. -->
  <xsl:template match="note[@type eq 'WWP'][not($keep-wwp-text)]
                     | figDesc             [not($keep-wwp-text)]">
    <xsl:call-template name="not-as-shallow-copy"/>
  </xsl:template>
  
  <!-- OPTIONAL: remove <lb>s and <cb>s. Add a single space. -->
  <xsl:template match="lb | cb">
    <xsl:if test="$keep-line-and-column-breaks">
      <xsl:call-template name="not-as-shallow-copy"/>
    </xsl:if>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- MODE: #default -->
  
  <!-- Normalize 'ſ' to 's' and (temporarily) turn soft hyphens into '@'. Whitespace 
    after a soft hyphen is dropped. -->
  <xsl:template match="text()" name="normalizeText">
    <xsl:value-of select="replace(translate(.,'ſ­','s@'),'@\s*','@')"/>
  </xsl:template>
  
  <!-- By default when matching elements, copy it and apply templates to its children. -->
  <xsl:template match="*" mode="#default unifier" priority="-40">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*|text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Favor <expan>, <reg> and <corr> within <choice>. -->
  <xsl:template match="choice">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="choice"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="abbr | sic | orig" mode="choice">
    <xsl:copy>
      <xsl:attribute name="read" select="text()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="expan | corr | reg" mode="choice">
    <xsl:copy>
      <xsl:apply-templates mode="#default"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Make sure Distinct Initial Capitals are uppercased. -->
  <xsl:template match="hi[@rend][contains(@rend,'class(#DIC)')]">
    <xsl:variable name="up">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(*) and $up ne data(.)">
        <xsl:attribute name="read" select="text()"/>
      </xsl:if>
      <xsl:copy-of select="$up"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="hi[@rend][contains(@rend,'class(#DIC)')]//text()" priority="15">
    <xsl:variable name="replacement">
      <xsl:call-template name="normalizeText"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$replacement ne .">
        <xsl:element name="seg">
          <xsl:attribute name="read" select="data(.)"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Replace <vuji>'s content with its regularized character. -->
  <xsl:template match="vuji">
    <xsl:variable name="text" select="normalize-space(.)"/>
    <xsl:copy>
      <xsl:attribute name="read" select="text()"/>
      <xsl:value-of select="if ( $text eq 'VV' ) then 'W'
                       else if ( $text eq 'vv' ) then 'w'
                       else translate($text,'vujiVUJI','uvijUVIJ')"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Remove the content of <ref type="pageNum">s. -->
  <xsl:template match="ref[@type][@type eq 'pageNum']">
    <xsl:call-template name="read-as-copy"/>
  </xsl:template>
  
  <!-- Working assumptions:
        * Elements in a "pbGroup" will always share the same parent.
          * This apparently isn't always true in our textbase, but it probably should be?
        * If there are text nodes in between pbGroup elements, they will contain only whitespace.
        * Relevant <mw>s have a @type of "catch", "pageNum", "sig", or "vol".
        * Each pbGroup must contain, at minimum, one <pb> and one <milestone> (2 members minimum).
        * Each pbGroup may contain one <mw> of each relevant @type (6 members maximum).
        * With intermediate whitespace, the final member of an pbGroup may be 11 
          positions away from the first, at most.
        * However, blank pages can be grouped closely, increasing the maximum number of members.
        * pbGroups don't currently distinguish between the metawork around a single 
          <pb>. If they did, the following would apply:
          * Catchwords must appear before <pb>.
          * <milestone> must appear immediately after <pb>.
          * Other @types of <mw> can appear either before or after <pb>, depending on the text.
  -->
  <xsl:template match="mw[@type = ('catch', 'pageNum', 'sig', 'vol')] | pb | milestone">
    <!-- If this is the first in an pbGroup, start pbGrouper mode to collect this 
      element's related siblings. If there are other pbGroup candidates before this 
      one, nothing happens. -->
    <xsl:if test="not(preceding-sibling::*[1][wf:is-pbGroup-candidate(.)])">
      <ab xmlns="http://www.wwp.northeastern.edu/ns/textbase" type="pbGroup">
        <xsl:variable name="my-position" select="position()"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="pbSubsequencer">
          <xsl:with-param name="start-position" select="$my-position"/>
        </xsl:call-template>
      </ab>
    </xsl:if>
  </xsl:template>
  
  <!-- Group all pbGroup candidates together. If there are more than $max-length 
    candidates within a pbGroup, call this template again on the next $max-length 
    siblings. -->
  <xsl:template name="pbSubsequencer">
    <xsl:param name="start-position" as="xs:integer"/>
    <xsl:variable name="max-length" select="14"/>
    <xsl:if test="count(subsequence(parent::*/(* | text()),1,$start-position)) gt 0">
      <xsl:variable name="groupmates">
        <xsl:variable name="siblings-after" as="node()*">
          <xsl:variable name="all-after" select="subsequence(parent::*/(* | text()),$start-position,last())"/>
          <xsl:copy-of select="if ( count($all-after) gt $max-length ) then
                                 subsequence($all-after,1,$max-length)
                               else $all-after"/>
        </xsl:variable>
        <xsl:variable name="first-nonmatch">
          <xsl:variable name="nonmatches" as="xs:boolean*">
            <xsl:for-each select="$siblings-after">
              <xsl:variable name="this" select="."/>
              <xsl:value-of select="not(wf:is-pbGroup-candidate($this))"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="index-of($nonmatches,true())[1]"/>
        </xsl:variable>
        <xsl:variable name="potential-group" select=" if ( $first-nonmatch ne '' ) then 
                                                        subsequence($siblings-after, 1, $first-nonmatch - 1) 
                                                      else $siblings-after"/>
        <!--<xsl:variable name="pattern" select="for $i in $potential-group
                                             return 
                                              if ( $i[self::mw] ) then 
                                                $i/@type
                                              else $i/local-name()"/>
        <xsl:message>
          <xsl:value-of select="string-join($pattern,'/')"/>
        </xsl:message>-->
        <xsl:copy-of select="$potential-group"/>
        <xsl:if test="$first-nonmatch eq '' and count($siblings-after) eq $max-length">
          <xsl:call-template name="pbSubsequencer">
            <xsl:with-param name="start-position" select="$start-position + $max-length"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
      <xsl:apply-templates select="$groupmates" mode="pbGrouper"/>
    </xsl:if>
  </xsl:template>
  
  <!-- Delete whitespace and certain types of <mw> when they trail along with a pbGroup. -->
  <xsl:template match="mw [@type = ('border', 'border-ornamental', 'border-rule', 'other', 'pressFig', 'unknown')]
                          [preceding-sibling::*[1][wf:is-pbGroup-candidate(.)]]
                      | text()[normalize-space(.) eq ''] 
                          [preceding-sibling::*[1][wf:is-pbGroup-candidate(.)]]"/>
  
  
  <!-- MODE: pbGrouper -->
  
  <!-- Any non-whitespace content of a pbGroup is ignored. -->
  <xsl:template match="text()" mode="pbGrouper">
    <xsl:if test="normalize-space(.) eq ''">
      <xsl:copy/>
    </xsl:if>
  </xsl:template>
  
  <!-- The members of a pbGroup are copied through, retaining their attributes but 
    none of their children. -->
  <xsl:template match="mw | pb | milestone" mode="#default pbGrouper" priority="-10">
    <xsl:call-template name="read-as-copy"/>
  </xsl:template>
  
  
  <!-- MODE: unifier -->
  
  <!-- Copy whitespace forward. -->
  <xsl:template match="text()[normalize-space(.) eq '']" mode="unifier" priority="10">
    <xsl:copy/>
  </xsl:template>
  
  <!-- If text has a soft-hyphen delimiter at the end, grab the next part of the 
    word from the next non-whitespace text node. -->
  <xsl:template name="wordpart-end">
    <xsl:if test="matches(.,'@\s*$')">
      <xsl:variable name="text-after" select="following::text()[not(normalize-space(.) eq '')][1]"/>
      <xsl:variable name="wordpart-two" select="if ( $text-after ) then wf:get-first-word($text-after) else ''"/>
      <xsl:element name="seg" namespace="http://www.wwp.northeastern.edu/ns/textbase">
        <xsl:attribute name="read" select="''"/>
        <xsl:value-of select="wf:remove-shy($wordpart-two)"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  
  <!-- If the preceding non-whitespace text node ends with a soft-hyphen delimiter, 
    create a <seg> placeholder for the part of the word drawn out. -->
  <xsl:template name="wordpart-start">
    <xsl:if test="preceding::text()[not(normalize-space(.) eq '')][1][matches(.,'@\s*$')]">
      <xsl:if test="preceding::text()[1][matches(.,'\s*$')]">
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:variable name="wordpart" select="wf:get-first-word(.)"/>
      <xsl:element name="seg" namespace="http://www.wwp.northeastern.edu/ns/textbase">
        <xsl:attribute name="read" select="$wordpart"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  
  <!-- Remove '@' delimiters from text. If the preceding non-whitespace node ended 
    with an '@', remove the initial word fragment. If the delimiter occurs at the 
    end of the text node, fold in the next part of the fragmented word. -->
  <xsl:template match="text()" mode="unifier">
    <xsl:variable name="wordpartStart" as="node()*">
      <xsl:call-template name="wordpart-start"/>
    </xsl:variable>
    <xsl:copy-of select="$wordpartStart"/>
    <xsl:variable name="munged" select="if ( $wordpartStart ) then
                                          substring-after(., $wordpartStart/@read)
                                        else ."/>
    <xsl:value-of select="wf:remove-shy($munged)"/>
    <xsl:call-template name="wordpart-end"/>
  </xsl:template>
  
  <!-- Add blank lines around pbGroups, to aid readability. -->
  <xsl:template match="ab[@type eq 'pbGroup']" mode="unifier">
    <xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="."/>
    <xsl:text>&#xa;&#xa;</xsl:text>
  </xsl:template>
  
</xsl:stylesheet>