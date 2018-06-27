<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  exclude-result-prefixes="xs xsl wwp wf"
  xmlns="http://www.wwp.northeastern.edu/ns/textbase"
  xpath-default-namespace="http://www.wwp.northeastern.edu/ns/textbase"
  version="2.0">
  
  <!-- 
    This stylesheet creates a version of a WWO text suitable for full-text indexing, 
    and any other activity where having access to semi-regularized, complete words 
    might be useful.
    
    Author: Ashley M. Clark
    
    Changelog:
      2018-06-20, v2.0: Began fixing soft hyphen handling by partially walking back 
        the previous workflow of moving wordparts from one side of a break tag to 
        the other. Instead, any intermediate whitespace is deleted between the soft 
        hyphen and its following wordparts. One consequence of this is that break 
        tags such as <lb> can no longer imply whitespace once this transformation 
        has been run.
        The soft hyphen delimiter "@" has been changed back to "­", and made into a
        global parameter.
        "Vv" is allowed as the content of <vuji>.
      2018-04-04: When $move-notes-to-anchors is toggled on, notes in the <hyperDiv>
        are run through 'unifier' mode, then tunnelled through to the anchors. 
        (Since the first pass returns a sequence of nodes, getting to the <hyperDiv> 
        from an anchoring element in <body> is non-trivial—they no longer share an 
        ancestor.)
      2017-08-14: Ensured that anchors will always have at least one space 
        separating it from a moved note.
      2017-08-09: Added $move-notes-to-anchors parameter. When toggled on, notes 
        will be copied next to their anchors, and deleted from their original 
        positions.
      2017-08-03: Set `//note[@type eq 'temp']` to be removed when $keep-wwp-text is 
        toggled off.
      2017-04-25: Added function to test if an element has mixed content. Created 
        'text2attr' mode so that when content is turned into an @read, the XML tree 
        isn't flattened unnecessarily. @read propagates to descendant elements, and 
        wrapper <seg>s are created to hold @read in the case of mixed content. 
        Expanded intervention subtypes to make clear when they occur on the contents 
        of an element, versus when an element is itself added.
      2017-04-14: Added @subtypes to <seg>s, and filled out the list of elements 
        which imply whitespace delimiters. Ensured that the <teiHeader> is not 
        processed but copied forward. Put deleted soft hyphens in @read where 
        appropriate. Replaced processing instructions.
      2017-04-13: Added templates to include whitespace around elements which imply 
        some sort of spacing. Added @type to <seg>s to allow tracking of 
        intervention types.
  -->
  
  <xsl:output encoding="UTF-8" indent="no"/>
  <xsl:preserve-space elements="*"/>
  
<!-- PARAMETERS -->
  
  <!-- Parameter option to include/disinclude explanatory attributes (@resp, @type, 
    @subtype) when an element's textual content is added, deleted, or modified. Such 
    signposts might be useful in determining the provenance of interventions made by 
    this stylesheet, or for debugging, or for tracking types of normally-implicit 
    behavior. The default is to include these attributes. -->
  <xsl:param name="include-provenance-attributes" as="xs:boolean" select="true()"/>
  
  <!-- Parameter option to keep/remove <lb>s and <cb>s from output. The default is 
    to keep them. -->
  <xsl:param name="keep-line-and-column-breaks"   as="xs:boolean" select="true()"/>
  
  <!-- Parameter option to keep/remove text around page breaks, such as catchwords
    and signatures. As part of this transform, text nodes in <mw> will always be 
    removed and their content placed in an @read on their parent. This parameter 
    determines whether the text content will be reconstituted from @read when their 
    inclusion won't mess up soft hyphen handling. The default is to remove the text 
    content of <mw>. -->
  <xsl:param name="keep-metawork-text"            as="xs:boolean" select="false()"/>
  
  <!-- Parameter option to keep/remove modern, WWP-authored content within <text>, 
    such as <figDesc> and <note type="WWP">. The default is to keep WWP content. If 
    WWP content is removed, no @read is used to capture deleted content. -->
  <xsl:param name="keep-wwp-text"                 as="xs:boolean" select="true()"/>
  
  <!-- Parameter option to move notes from the <hyperDiv> or endnotes section, to 
    their anchorpoint. This could be useful for proximity-based text analysis. The 
    default is to keep the notes where they appeared in the input XML. -->
  <xsl:param name="move-notes-to-anchors"         as="xs:boolean" select="false()"/>
  
  
<!-- VARIABLES and KEYS -->
  
  <xsl:variable name="fulltextBot" select="'fulltextBot'"/>
  <xsl:variable name="shyDelimiter" select="'­'"/>
  <xsl:variable name="shyEndingPattern" select="concat($shyDelimiter,'\s*$')"/>
  
  
<!-- FUNCTIONS -->
  
  <xsl:function name="wf:get-first-word" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:variable name="slim-text" select="normalize-space($text)"/>
    <xsl:variable name="pattern">
      <xsl:text>^\s*([\w'-]+[\.,;:!?”/)\]]?)((\s+|[―—]*|-{2,}).*)?$</xsl:text>
    </xsl:variable>
    <xsl:value-of select="replace($slim-text, $pattern, '$1')"/>
  </xsl:function>
  
  <xsl:function name="wf:has-mixed-content" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:value-of select="exists($element[*][text()])"/>
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
  
  <xsl:function name="wf:is-splitting-a-word" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:value-of select="exists($node/preceding::text()[not(normalize-space(.) eq '')][1]
                                                        [matches(., $shyEndingPattern)])"/>
  </xsl:function>
  
  <xsl:function name="wf:remove-shy" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:value-of select="replace($text, $shyEndingPattern, '')"/>
  </xsl:function>
  
  
<!-- TEMPLATES -->
  
  <xsl:template match="/">
    <xsl:for-each select="processing-instruction()">
      <xsl:text>&#x0A;</xsl:text>
      <xsl:copy-of select="."/>
    </xsl:for-each>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- Test if the current element has whitespace preceding it explicitly. If the 
    current element is <lb> or <cb> (read: empty), then test the following node for 
    whitespace too. Add a single space as needed. -->
  <xsl:template name="make-whitespace-explicit">
    <xsl:variable name="has-preceding-sibling" select="exists(preceding-sibling::node())"/>
    <xsl:if test="( ( $has-preceding-sibling and preceding-sibling::node()[1][not(matches(.,'\s+$'))] )
                    or ( not($has-preceding-sibling) and not(exists(parent::*/preceding-sibling::node())) )
                  )
                  and self::*[not(@rend) or not(matches(@rend,'break\(\s*no\s*\)'))]">
      <xsl:if test="not((self::lb | self::cb)) 
                    or (self::lb | self::cb)[following-sibling::node()[1][not(matches(.,'^\s+'))]]">
        <seg read="" type="implicit-whitespace">
          <!-- It is useful to provide @type="implicit-whitespace" even if 
            $include-provenance-attributes is turned off. -->
          <xsl:call-template name="set-provenance-attributes">
            <xsl:with-param name="subtype" select="'add-content add-element'"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
        </seg>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- Copy the element and its attributes, but none of its descendants. -->
  <xsl:template name="not-as-shallow-copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(self::lb) and not(self::cb)">
        <xsl:call-template name="set-provenance-attributes"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- Copy the element and its attributes, and add @read on any text content. -->
  <xsl:template name="read-as-copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="text2attr"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Include explanatory attributes about the types of interventions occurring on 
    the element and its content.
    OPTIONAL: Do not add any provenance information. -->
  <xsl:template name="set-provenance-attributes">
    <xsl:param name="type" as="xs:string" select="''"/>
    <xsl:param name="subtype" as="xs:string" select="''"/>
    <xsl:if test="$include-provenance-attributes">
      <xsl:if test="$type ne ''">
        <xsl:attribute name="type" select="$type"/>
      </xsl:if>
      <xsl:if test="$subtype ne ''">
        <xsl:attribute name="subtype" select="$subtype"/>
      </xsl:if>
      <xsl:attribute name="resp" select="$fulltextBot"/>
    </xsl:if>
  </xsl:template>
  
<!-- MODE: #default -->
  
  <!-- Copy the <teiHeader>. -->
  <xsl:template match="teiHeader">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <!-- Run default mode on the descendants of <text>, then resolve soft hyphens. -->
  <xsl:template match="text">
    <xsl:variable name="first-pass" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <!-- If $move-notes-to-anchors is toggled on, pre-process soft hyphens for notes 
      in the <hyperDiv>. These notes will be tunnelled to anchors. -->
    <xsl:variable name="notes" as="node()*">
      <xsl:if test="$move-notes-to-anchors">
        <xsl:apply-templates select="$first-pass[self::hyperDiv]//note" mode="unifier">
          <xsl:with-param name="is-anchored" select="true()"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="$first-pass" mode="unifier">
        <xsl:with-param name="processed-notes" select="$notes" as="node()*" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <!-- Normalize 'ſ' to 's'. Soft hyphens are replaced with $shyDelimiter, which is 
    by default just a soft hyphen. For debugging purposes, it may be useful to 
    change $shyDelimiter to something more visible. -->
  <xsl:template match="text()" name="normalizeText">
    <xsl:variable name="replaceStr" select="concat('s',$shyDelimiter)"/>
    <xsl:value-of select="translate(., 'ſ­', $replaceStr)"/>
  </xsl:template>
  
  <!-- By default when matching an element, copy it and apply templates to its 
    children. -->
  <xsl:template match="*" mode="#default text2attr unifier" priority="-40">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*|text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- OPTIONAL: completely remove the content of WWP notes and <figDesc>s. -->
  <xsl:template match="note[@type eq 'WWP'] [not($keep-wwp-text)]
                     | note[@type eq 'temp'][not($keep-wwp-text)]
                     | figDesc              [not($keep-wwp-text)]" priority="30">
    <xsl:call-template name="not-as-shallow-copy"/>
  </xsl:template>
  
  <!-- Add a single space before any element that implies some kind of whitespace 
    separator. This implementation may be incomplete. -->
  <xsl:template match="ab | argument | castGroup | castItem | castList | closer 
                      | dateline | div | docEdition | docImprint | docSale | epigraph 
                      | figDesc | figure | head | imprimatur | item | l | lg | list 
                      | note | opener | p | respLine | salute | signed | sp | speaker 
                      | stage | titleBlock | titlePart | trailer 
                      | table | row | cell
                      | *[@rend][matches(@rend,'break\(\s*yes\s*\)')]" priority="-15">
    <xsl:call-template name="make-whitespace-explicit"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Add a single space if there is no whitespace around <lb>s or <cb>s.
     OPTIONAL: remove <lb>s and <cb>s. -->
  <xsl:template match="lb | cb">
    <xsl:call-template name="make-whitespace-explicit"/>
    <xsl:if test="$keep-line-and-column-breaks">
      <xsl:call-template name="not-as-shallow-copy"/>
    </xsl:if>
  </xsl:template>
  
  <!-- Favor <expan>, <reg>, and <corr> within <choice>. -->
  <xsl:template match="choice">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="choice"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="abbr | sic | orig" mode="choice">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="text2attr">
        <xsl:with-param name="intervention-type" select="'choice'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="expan | corr | reg" mode="choice">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
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
        <xsl:attribute name="read" select="data(.)"/>
        <xsl:call-template name="set-provenance-attributes"/>
      </xsl:if>
      <xsl:copy-of select="$up"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Replace <vuji>'s content with its regularized character. -->
  <xsl:template match="vuji">
    <xsl:variable name="text" select="normalize-space(.)"/>
    <xsl:copy>
      <xsl:attribute name="read" select="text()"/>
      <xsl:call-template name="set-provenance-attributes">
        <xsl:with-param name="subtype" select="'mod-content'"/>
      </xsl:call-template>
      <xsl:value-of select="if ( $text = ('VV', 'Vv') ) then 'W'
                       else if ( $text eq 'vv' )        then 'w'
                       else translate($text,'vujiVUJI','uvijUVIJ')"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Remove the content of <ref type="pageNum">s. -->
  <xsl:template match="ref[@type][@type eq 'pageNum']">
    <xsl:call-template name="read-as-copy">
      <xsl:with-param name="intervention-type" select="'pageNum'" tunnel="yes"/>
    </xsl:call-template>
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
      <ab type="pbGroup">
        <!-- It is useful to provide @type="pbGroup" even if 
          $include-provenance-attributes is turned off. -->
        <xsl:call-template name="set-provenance-attributes">
          <xsl:with-param name="subtype" select="'add-element'"/>
        </xsl:call-template>
        <xsl:variable name="my-position" select="position()"/>
        <!--<xsl:text>&#xa;</xsl:text>-->
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
  
  
<!-- MODE: text2attr -->
  
  <!-- Create @read and provenance attributes from text nodes. This template will 
    only work if the matched text node is the first or only child of its parent, 
    since attributes cannot be inserted after an element's child nodes. -->
  <xsl:template name="read-text-node" match="text()" mode="text2attr">
    <xsl:param name="intervention-type" select="''" as="xs:string" tunnel="yes"/>
    <xsl:param name="adding-element" select="false()" as="xs:boolean"/>
    <xsl:attribute name="read" select="."/>
    <xsl:call-template name="set-provenance-attributes">
      <xsl:with-param name="type" select="$intervention-type"/>
      <xsl:with-param name="subtype">
        <xsl:text>del-content</xsl:text>
        <xsl:if test="$adding-element">
          <xsl:text> add-element</xsl:text>
        </xsl:if>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <!-- If a text node is not the only child of its parent element, create a wrapper 
    <seg> to house the generated @read and provenance attributes. -->
  <xsl:template match="text()[parent::*[wf:has-mixed-content(.)]]" mode="text2attr" priority="35">
    <seg>
      <xsl:call-template name="read-text-node">
        <xsl:with-param name="adding-element" select="true()"/>
      </xsl:call-template>
    </seg>
  </xsl:template>
  
  
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
    <xsl:call-template name="make-whitespace-explicit"/>
    <xsl:call-template name="read-as-copy"/>
  </xsl:template>
  
  
<!-- MODE: unifier -->
  
  <!-- Copy whitespace-only text nodes forward, unless they occur between a soft 
    hyphen and a subsequent wordpart. -->
  <xsl:template match="text()[normalize-space(.) eq '']" mode="unifier" priority="10">
    <xsl:choose>
      <xsl:when test="wf:is-splitting-a-word(.)" >
        <seg read="\s+">
          <xsl:call-template name="set-provenance-attributes">
            <xsl:with-param name="type" select="'explicit-whitespace'"/>
            <xsl:with-param name="subtype" select="'add-element mod-content'"/>
          </xsl:call-template>
        </seg>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Delete the results of the 'make-whitespace-explicit' template, iff they occur 
    between a soft hyphen and following wordparts. -->
  <xsl:template match="seg[@type eq 'implicit-whitespace'][wf:is-splitting-a-word(.)]" mode="unifier"/>
  
  <!-- Remove soft hyphen delimiters from text nodes. -->
  <xsl:template match="text()" mode="unifier">
    <!-- If the preceding non-whitespace text node ended with a soft hyphen, remove 
      any leading whitespace. -->
    <xsl:variable name="mungedStart" as="xs:string">
      <xsl:choose>
        <xsl:when test="preceding::text()[not(normalize-space(.) eq '')][1][matches(., $shyEndingPattern)]">
          <xsl:value-of select="replace(., '^\s+', '')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- If the soft hyphen delimiter occurs at the end of the text node, remove it 
      and mark where it was. -->
    <xsl:value-of select="wf:remove-shy($mungedStart)"/>
    <xsl:call-template name="wordpart-end"/>
  </xsl:template>
  
  <!-- If text has a soft-hyphen delimiter at the end, grab the next part of the 
    word from the next non-whitespace text node. -->
  <xsl:template name="wordpart-end">
    <xsl:if test="matches(., $shyEndingPattern)">
      <xsl:variable name="endingWhitespace" 
        select="if ( matches(., '\s+$') ) then '\s+'
                else ''"/>
      <seg>
        <xsl:attribute name="read" select="concat('­',$endingWhitespace)"/>
        <xsl:call-template name="set-provenance-attributes">
          <xsl:with-param name="type" select="'shy-part'"/>
          <xsl:with-param name="subtype" select="'add-element mod-content'"/>
        </xsl:call-template>
      </seg>
    </xsl:if>
  </xsl:template>
  
  <!-- If metawork will not be reconstituted, keep <ab> wrappers around pbGroups. -->
  <xsl:template match="ab[@type eq 'pbGroup'][not($keep-metawork-text)]" mode="unifier">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- If $keep-metawork-text is toggled on, remove <ab> wrappers around pbGroups. -->
  <xsl:template match="ab[@type eq 'pbGroup'][$keep-metawork-text]" mode="unifier">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <!-- If $keep-metawork-text is toggled on, text nodes should be reconstituted from 
    @read appearing on the members of a pbGroup. -->
  <xsl:template match="ab[@type eq 'pbGroup'][$keep-metawork-text]//*[@read]" mode="unifier">
    <xsl:copy>
      <xsl:copy-of select="@* except @read"/>
      <xsl:value-of select="@read"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- If $move-notes-to-anchors is toggled on, elements with @corresp get copies of 
    any matching notes placed immediately after them. -->
  <xsl:template match="*[@corresp][$move-notes-to-anchors]" mode="unifier">
    <xsl:param name="processed-notes" as="node()*" tunnel="yes"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
    <xsl:variable name="idref" select="@corresp/data(.)"/>
    <xsl:variable name="matchedNote" select="$processed-notes[@sameAs eq $idref]"/>
    <xsl:variable name="hasSpacing" 
      select=" matches($matchedNote/data(.), '^\s') 
            or matches(data(.), '\s$') 
            or (
                normalize-space() eq '' 
            and matches(preceding-sibling::node()[self::text() or self::*[text()]][1], '\s$') 
            )"/>
    <xsl:if test="not($hasSpacing)">
      <seg read="">
        <xsl:call-template name="set-provenance-attributes">
          <xsl:with-param name="type" select="'implicit-whitespace'"/>
          <xsl:with-param name="subtype" select="'add-content add-element'"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </seg>
    </xsl:if>
    <xsl:copy-of select="$matchedNote"/>
  </xsl:template>
  
  <!-- If $move-notes-to-anchors is toggled on, anchored notes are suppressed where 
    they appeared in the XML, and copied alongside their referencing context. -->
  <xsl:template match="note[@xml:id][@target][$move-notes-to-anchors]" mode="unifier">
    <xsl:param name="is-anchored" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$is-anchored">
        <xsl:copy>
          <!-- The copy of the note does not get the @xml:id. Instead, it points to 
            its original by using @sameAs. -->
          <xsl:copy-of select="@* except @xml:id"/>
          <xsl:attribute name="read" select="''"/>
          <xsl:attribute name="sameAs" select="concat('#',@xml:id)"/>
          <xsl:call-template name="set-provenance-attributes">
            <xsl:with-param name="subtype" select="'add-content add-element'"/>
          </xsl:call-template>
          <xsl:apply-templates mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:call-template name="set-provenance-attributes">
            <xsl:with-param name="subtype" select="'del-content'"/>
          </xsl:call-template>
          <!--<xsl:apply-templates select="*|text()" mode="text2attr"/>-->
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
