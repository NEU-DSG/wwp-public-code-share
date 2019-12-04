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
    
    Author: Ashley M. Clark, Northeastern University Women Writers Project
    See https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
    
    Changelog:
      2019-12-04, v2.9: Expanded handling of `@break="no"` to include intermediate 
        space and `//ab[@type eq 'pbGroup']/pb[@break eq 'no']`.
        Normalized the content of @read by reducing adjacent whitespace to a single 
        space. This improves parsability for humans and programs. To map a 
        fulltexted node back to the original version, test for equality after using
        normalize-space() on both nodes.
      2019-12-03, v2.8: When $choose-original-content is toggled on, the usual 
        <choice> resolution is reversed: abbreviations, errors, and original text 
        content are preferred over expansions, corrections, and regularizations. 
        Similarly, when $substitute-deletions is toggled on, <subst> resolution 
        prefers the deleted text content over later additions. Text nodes 
        (whitespace) are removed inside <choice> and <subst>.
        Expanded handling of word breakage to include `@break="no"` encoding. 
        Whitespace is deleted around a non-breaking <lb> or <pb>, but hard hyphen 
        characters are not deleted. With this change, the FulltextBot produces much 
        better results when run on the Mary Moody Emerson manuscript (currently the 
        only document in WWO to use this method of encoding word breakage).
      2019-10-31, v2.7: Added code to favor <add> over <del> inside <subst>.
      2019-10-29, v2.6: Fixed a bug where notes in the <hyperDiv> were not deleted 
        when copied to an anchor but its original parent was <add> instead of 
        <notes>. All notes in the <hyperDiv> should be moved correctly now.
      2019-09-23, v2.5: Tweaked note insertion such that notes on notes are inserted 
        at the same time as the annotated notes. At the time of this writing, only 
        documents in the textbase sandbox have notes with @corresp pointing to other 
        notes.
      2019-07-26, v2.4: Added MIT license and descriptive comments.
      2019-05-31, v2.3: Ensured that the non-<group> children of `//text[group]` are
        processed with unifier mode.
        If $move-notes-to-anchors is toggled on, each <text> inherits pre-processed 
        <note>s from its ancestors. Nested <text>s are copied forward during 
        "unifier" mode, since its descendents would already have been run through 
        unifier (and possibly "noted") mode.
        The unused function wf:get-first-word() has been deleted.
      2019-01-30, v2.2: Added "noted" mode to ensure that <note>s will not break 
        up words. Instead of being resolved in "unifier" mode, these interrupting 
        <note>s are withheld and put back where they were in a third pass.
      2018-06-27, v2.1: Ensured that any whitespace deleted during shy handling is
        represented in @read, either on the soft hyphen, or by adding a <seg> with a
        @type of 'explicit-whitespace'. Added function to test if a node occurs 
        after an unresolved soft hyphen. During unifier mode, the results of the 
        'make-whitespace-explicit' template are removed if they prove unnecessary.
        Appended this XSLT's version number to the $fulltextBot variable.
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
    
    MIT License
    
    Copyright (c) 2019 Northeastern University Women Writers Project
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  -->
  
  <xsl:output encoding="UTF-8" indent="no"/>
  <xsl:preserve-space elements="*"/>
  
<!-- PARAMETERS -->
  
  <!-- Parameter option to prefer abbreviations, errors, and other original text 
    content within <choice>. The default is to use the full, modern variant of text 
    content: expansions, corrections, and regularizations. -->
  <xsl:param name="choose-original-content"       as="xs:boolean" select="false()"/>
  
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
  
  <!-- Parameter option to keep/remove modern era, WWP-authored content within <text>, 
    such as <figDesc> and <note type="WWP">. The default is to keep WWP content. If 
    WWP content is removed, no @read attribute is used to capture deleted content. -->
  <xsl:param name="keep-wwp-text"                 as="xs:boolean" select="true()"/>
  
  <!-- Parameter option to move notes from the <hyperDiv> section, to their 
    anchorpoint. This could be useful for proximity-based text analysis. The default 
    is to keep the notes where they appeared in the input XML. -->
  <xsl:param name="move-notes-to-anchors"         as="xs:boolean" select="false()"/>
  
  <!-- Parameter option to prefer deletions over additions within <subst>. The 
    default is to use the added text content. -->
  <xsl:param name="substitute-deletions"          as="xs:boolean" select="false()"/>
  
  
<!-- VARIABLES and KEYS -->
  
  <xsl:variable name="fulltextBotVersion" select="'2.8'"/>
  <xsl:variable name="fulltextBot" select="concat('fulltextBot-',$fulltextBotVersion)"/>
  <xsl:variable name="shyDelimiter" select="'­'"/>
  <xsl:variable name="shyEndingPattern" select="concat($shyDelimiter,'\s*$')"/>
  
  
<!-- FUNCTIONS -->
  
  <!-- Determine if a node has a @break attribute with a value of "no". This 
    attribute-value combination is the TEI-approved way of handling words which 
    break over lines and pages. -->
  <xsl:function name="wf:has-break-attribute-no" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:value-of 
      select="exists($node[self::*][@break eq 'no']) 
              or exists($node[self::ab][@type eq 'pbGroup']/*[wf:has-break-attribute-no(.)])"/>
  </xsl:function>
  
  <!-- Determine if a given element has both element and text node children. -->
  <xsl:function name="wf:has-mixed-content" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:value-of select="exists($element[*][text()])"/>
  </xsl:function>
  
  <!-- Determine if a node meets the criteria for belonging to a pbGroup. This 
    function does not imply that the given node *is* a part of a pbGroup, only that 
    it could belong to one. -->
  <xsl:function name="wf:is-pbGroup-candidate" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:value-of 
      select="exists( $node[  self::mw[@type = ('catch', 'pageNum', 'sig', 'vol')] 
                           (: The XPath above tests for mw with types that could trigger a pbGroup. 
                              The XPath below tests for mw that could belong to a pbGroup. :)
                           or self::mw[@type = ('border', 'border-ornamental', 'border-rule', 'other', 'pressFig', 'unknown')]
                           or self::pb 
                           or self::milestone
                           or self::text()[normalize-space() eq ''] ] )"/>
  </xsl:function>
  
  <!-- Determine if a node appears in between parts of a single word. -->
  <xsl:function name="wf:is-splitting-a-word" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="precedingShy"
       select="$node/preceding::text()[not(normalize-space(.) eq '')][1]
                                      [matches(., $shyEndingPattern)]"/>
    <xsl:variable name="nearbyBreakAttrNo"
       select="$node/(preceding::node()[1] | following::node()[1])
                [wf:has-break-attribute-no(.)]"/>
    <xsl:value-of select="exists($precedingShy) or exists($nearbyBreakAttrNo)"/>
  </xsl:function>
  
  <!-- Given some textual content from the XML document, reduce whitespace down to a 
    single space for inclusion in a @read attribute. -->
  <xsl:function name="wf:normalize-for-read" as="xs:string">
    <xsl:param name="content" as="item()"/>
    <xsl:value-of select="replace(xs:string($content), '\s+', ' ')"/>
  </xsl:function>
  
  <!-- Given a string, remove any soft hyphens and return the result. -->
  <xsl:function name="wf:remove-shy" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:value-of select="replace($text, $shyEndingPattern, '')"/>
  </xsl:function>
  
  
<!-- TEMPLATES -->
  
  <!-- Move a <note> to its anchor, making sure to set it off with whitespace if 
    needed. -->
  <xsl:template name="insert-preprocessed-note">
    <xsl:param name="processed-notes" as="node()*" tunnel="yes"/>
    <xsl:variable name="whitespaceSeg">
      <seg read="">
        <xsl:call-template name="set-provenance-attributes">
          <xsl:with-param name="type" select="'implicit-whitespace'"/>
          <xsl:with-param name="subtype" select="'add-content add-element'"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </seg>
    </xsl:variable>
    <xsl:variable name="idref" select="@corresp/data(.)"/>
    <xsl:variable name="matchedNote" 
      select="$processed-notes[@sameAs eq $idref][1]" as="node()?"/>
    <xsl:variable name="inserts" as="node()*">
      <xsl:copy-of select="$matchedNote"/>
      <xsl:if test="$matchedNote[@corresp[. = $processed-notes/@sameAs]]">
        <xsl:variable name="matchedNoteForNote" 
          select="$processed-notes[@sameAs eq $matchedNote/@corresp/data(.)]"/>
        <xsl:if test="not($matchedNote[matches(data(.), '\s$')] 
                      or $matchedNoteForNote[matches(data(.), '^\s')])">
          <xsl:copy-of select="$whitespaceSeg"/>
        </xsl:if>
        <xsl:copy-of select="$matchedNoteForNote"/>
      </xsl:if>
    </xsl:variable>
    <!-- Add a space before the note if needed. -->
    <xsl:variable name="hasPreSpacing" 
      select=" matches($matchedNote/data(.), '^\s')
            or (
                normalize-space() eq '' 
            and matches(preceding-sibling::node()[self::text() or self::*[text()]][1], '\s$') 
            )"/>
    <xsl:if test="not($hasPreSpacing)">
      <xsl:copy-of select="$whitespaceSeg"/>
    </xsl:if>
    <xsl:copy-of select="$inserts"/>
    <!-- Add a space after the note if needed. -->
    <xsl:variable name="hasPostSpacing" 
      select=" matches($inserts[last()]/data(.), '\s$')
            or (
                normalize-space() eq '' 
            and matches(following::node()[self::text() or self::*[text()]][1], '^\s') 
            )"/>
    <xsl:if test="not($hasPostSpacing)">
      <xsl:copy-of select="$whitespaceSeg"/>
    </xsl:if>
  </xsl:template>
  
  <!-- Test if the current element has, explicitly, whitespace preceding it. If the 
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
          <!-- It is useful to provide @type="implicit-whitespace" even when 
            $include-provenance-attributes is turned off. The attribute will be 
            removed during 'unifier' mode if necessary. -->
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
  
  <!-- Begin processing the document by giving each leading processing instruction 
    its own line, for readability. (Based on code by Syd Bauman.) -->
  <xsl:template match="/">
    <xsl:for-each select="processing-instruction()">
      <xsl:text>&#x0A;</xsl:text>
      <xsl:copy-of select="."/>
    </xsl:for-each>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- Copy the <teiHeader>. -->
  <xsl:template match="teiHeader">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <!-- Run default mode on the outermost <text> elements, then resolve soft hyphens. -->
  <xsl:template match="text">
    <!-- Include any notes from an ancestor with a <hyperDiv>. -->
    <xsl:param name="notes-preprocessed" as="node()*" tunnel="yes"/>
    <!-- The first pass makes most whitespace explicit, creates pbGroups, makes 
      <choice>s, etc. -->
    <xsl:variable name="first-pass" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <!-- Now that most processing has taken place, enter unifier mode to connect up 
      wordparts which were separated by soft hyphens. If $move-notes-to-anchors is 
      toggled on, notes also are placed after their anchors. -->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="$first-pass" mode="unifier">
        <xsl:with-param name="processed-notes" select="$notes-preprocessed" as="node()*" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <!-- If $move-notes-to-anchors is toggled on, preprocess the notes in the 
    <hyperDiv> before continuing to apply templates. -->
  <xsl:template match="text[hyperDiv][$move-notes-to-anchors]" priority="5">
    <!-- Include any notes from an ancestor with a <hyperDiv>. -->
    <xsl:param name="notes-preprocessed" as="node()*" tunnel="yes"/>
    <!-- Pre-process notes in the <hyperDiv>. These notes will be tunnelled to 
      anchors. -->
    <xsl:variable name="notes-processed" as="node()*">
      <xsl:variable name="first-pass" as="node()*">
        <xsl:apply-templates select="hyperDiv//note[@xml:id]"/>
      </xsl:variable>
      <xsl:apply-templates select="$first-pass" mode="unifier">
        <xsl:with-param name="is-anchored" select="true()"/>
      </xsl:apply-templates>
    </xsl:variable>
    <!-- Use all preprocessed notes currently available and apply the default 
      template for <text> (above). -->
    <xsl:variable name="notes-full" as="node()*" 
      select="( $notes-preprocessed, $notes-processed )"/>
    <xsl:variable name="default-transform" as="node()">
      <xsl:next-match>
        <xsl:with-param name="notes-preprocessed" select="$notes-full" tunnel="yes"/>
      </xsl:next-match>
    </xsl:variable>
    <!-- Check for and copy any <note>s that haven't been moved into the text yet. -->
    <xsl:variable name="unmoved-notes" as="node()*">
      <xsl:variable name="moved-notes" select="$default-transform//note/@sameAs/data(.)"/>
      <xsl:copy-of select="$notes-processed[not(@sameAs[. = $moved-notes])]"/>
    </xsl:variable>
    <xsl:choose>
      <!-- If there are anchored notes from this <text>'s <hyperDiv> that could not 
        be inserted (because they break up a word), make sure the processed notes 
        are put back in their original locations. -->
      <xsl:when test="exists($unmoved-notes)">
        <xsl:apply-templates select="$default-transform" mode="noted">
          <xsl:with-param name="unmoved-notes" select="$unmoved-notes" as="node()*" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <!-- If a third pass isn't needed, just copy the results from the default 
        transformation. -->
      <xsl:otherwise>
        <xsl:copy-of select="$default-transform"/>
      </xsl:otherwise>
    </xsl:choose>
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
  <xsl:template match="*" mode="#default text2attr unifier noted" priority="-40">
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
    separator. This implementation may be incomplete. See the WWP’s internal 
    documentation (https://wwp.northeastern.edu/research/publications/documentation/internal/#!/entry/break_narrative)
    for more information. -->
  <xsl:template match="ab | argument | bibl | castGroup | castItem | castList | closer 
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
  
  <!-- Add a single space if there is no whitespace around <lb>s or <cb>s. If 
    $keep-line-and-column-breaks is toggled on, <lb>s and <cb>s are then removed. -->
  <xsl:template match="lb | cb">
    <xsl:call-template name="make-whitespace-explicit"/>
    <xsl:if test="$keep-line-and-column-breaks">
      <xsl:call-template name="not-as-shallow-copy"/>
    </xsl:if>
  </xsl:template>
  
  <!-- By default, delete all text inside <choice> and <subst>. -->
  <xsl:template match="text()" mode="choice subst">
    <seg>
      <xsl:call-template name="read-text-node">
        <xsl:with-param name="adding-element" select="true()"/>
      </xsl:call-template>
    </seg>
  </xsl:template>
  
  <!-- Favor <expan>, <reg>, and <corr> within <choice>. If $choose-original-content 
    is toggled on, <abbr>, <sic>, and <orig> will be used instead. -->
  <xsl:template match="choice">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="choice"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="abbr | sic | orig" mode="choice">
    <xsl:choose>
      <xsl:when test="$choose-original-content">
        <xsl:apply-templates select="." mode="#default"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="read-as-copy">
          <xsl:with-param name="intervention-type" select="'choice'" tunnel="yes"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="expan | corr | reg" mode="choice">
    <xsl:choose>
      <xsl:when test="$choose-original-content">
        <xsl:call-template name="read-as-copy">
          <xsl:with-param name="intervention-type" select="'choice'" tunnel="yes"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="#default"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Favor <add> within <subst>. If $substitute-deletions is toggled on, <del> 
    will be used instead. -->
  <xsl:template match="subst">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="subst"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="del" mode="subst">
    <xsl:choose>
      <xsl:when test="$substitute-deletions">
        <xsl:apply-templates select="." mode="#default"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="read-as-copy">
          <xsl:with-param name="intervention-type" select="'subst'" tunnel="yes"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="add" mode="subst">
    <xsl:choose>
      <xsl:when test="$substitute-deletions">
        <xsl:call-template name="read-as-copy">
          <xsl:with-param name="intervention-type" select="'subst'" tunnel="yes"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="#default"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Make sure Distinct Initial Capitals are uppercased. -->
  <xsl:template match="hi[@rend][contains(@rend,'class(#DIC)')]">
    <xsl:variable name="up">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(*) and $up ne data(.)">
        <xsl:attribute name="read" select="wf:normalize-for-read(.)"/>
        <xsl:call-template name="set-provenance-attributes"/>
      </xsl:if>
      <xsl:copy-of select="$up"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Replace <vuji>'s content with its regularized character. -->
  <xsl:template match="vuji">
    <xsl:variable name="text" select="normalize-space(.)"/>
    <xsl:copy>
      <xsl:attribute name="read" select="wf:normalize-for-read(.)"/>
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
  
  <!-- Identify artifacts around page breaks in a "pbGroup". If this pbGroup 
    candidate is not preceded by another candidate, it is made the first child of 
    the pbGroup. If the candidate does have preceding siblings which are candidates, 
    it has already been wrapped, and nothing more needs to be done.
    
    Working assumptions:
      * Elements in a "pbGroup" will always share the same parent.
        * This apparently isn't always true in our textbase, but it probably should 
           be.
      * If there are text nodes in between pbGroup elements, they will contain only 
         whitespace.
      * Relevant <mw>s have a @type of "catch", "pageNum", "sig", or "vol" 
         (catchwords, page numbers, signature marks, printed volume numbers).
         https://wwp.northeastern.edu/research/publications/documentation/internal/#!/entry/mw_element
      * Each pbGroup must contain, at minimum, one <pb> and one <milestone> (2 
         members minimum).
      * Each pbGroup may contain one <mw> of each relevant @type (6 members maximum).
      * With intermediate whitespace, the final member of an pbGroup may be 11 
         positions away from the first, at most.
      * However, blank pages can be grouped closely, increasing the maximum number 
         of members.
      * pbGroups don't currently distinguish between the metawork around a single 
         <pb>. If they did, the following would apply:
        * Catchwords must appear before <pb>.
        * <milestone> must appear immediately after <pb>.
        * Other @types of <mw> can appear either before or after <pb>, depending on the text.
  -->
  <xsl:template match="mw[@type = ('catch', 'pageNum', 'sig', 'vol')] | pb | milestone">
    <!-- If this is the first in an pbGroup, start pb-grouper mode to collect this 
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
    <!-- Continue only if there are text or element siblings after this 
      $start-position. -->
    <xsl:if test="count(subsequence(parent::*/(* | text()),1,$start-position)) gt 0">
      <xsl:variable name="groupmates">
        <!-- Get the next $max-length siblings... -->
        <xsl:variable name="siblings-after" as="node()*">
          <xsl:variable name="all-after" 
            select="subsequence(parent::*/(* | text()), $start-position, last())"/>
          <xsl:copy-of select="if ( count($all-after) gt $max-length ) then
                                 subsequence($all-after, 1, $max-length)
                               else $all-after"/>
        </xsl:variable>
        <!-- ...and test them to find the first which doesn't qualify as a pbGroup 
          candidate. -->
        <xsl:variable name="first-nonmatch">
          <xsl:variable name="nonmatches" as="xs:boolean*">
            <xsl:for-each select="$siblings-after">
              <xsl:variable name="this" select="."/>
              <xsl:value-of select="not(wf:is-pbGroup-candidate($this))"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="index-of($nonmatches,true())[1]"/>
        </xsl:variable>
        <!-- Identify and copy the pbGroup candidates in this set. -->
        <xsl:variable name="potential-group" 
          select="if ( $first-nonmatch ne '' ) then 
                    subsequence($siblings-after, 1, $first-nonmatch - 1) 
                  else $siblings-after"/>
        <xsl:copy-of select="$potential-group"/>
        <!-- Run this template again if all $max-length nodes were pbGroup 
          candidates. -->
        <xsl:if test="$first-nonmatch eq '' and count($siblings-after) eq $max-length">
          <xsl:call-template name="pbSubsequencer">
            <xsl:with-param name="start-position" select="$start-position + $max-length"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
      <!-- Run all pbGroup-mates through pb-grouper mode. -->
      <xsl:apply-templates select="$groupmates" mode="pb-grouper"/>
    </xsl:if>
  </xsl:template>
  
  <!-- Delete whitespace and certain types of <mw> when they trail along with a 
    pbGroup. -->
  <xsl:template match="mw [@type = ('border', 'border-ornamental', 'border-rule', 'other', 'pressFig', 'unknown')]
                          [preceding-sibling::*[1][wf:is-pbGroup-candidate(.)]]
                      | text()[normalize-space(.) eq '']
                          [preceding-sibling::*[1][wf:is-pbGroup-candidate(.)]]"/>
  
  
<!-- MODE: text2attr -->
  
  <!-- Create @read and any provenance attributes from text nodes. This template 
    will only work if the matched text node is the first or only child of its parent, 
    since attributes cannot be inserted after an element's child nodes. -->
  <xsl:template name="read-text-node" match="text()" mode="text2attr">
    <xsl:param name="intervention-type" select="''" as="xs:string" tunnel="yes"/>
    <xsl:param name="adding-element" select="false()" as="xs:boolean"/>
    <xsl:attribute name="read" select="wf:normalize-for-read(.)"/>
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
  
  
<!-- MODE: pb-grouper -->
  
  <!-- Any non-whitespace content of a pbGroup is ignored. -->
  <xsl:template match="text()" mode="pb-grouper">
    <xsl:if test="normalize-space(.) eq ''">
      <xsl:copy/>
    </xsl:if>
  </xsl:template>
  
  <!-- The members of a pbGroup are copied through, retaining their attributes but 
    none of their children. -->
  <xsl:template match="mw | pb | milestone" mode="#default pb-grouper" priority="-10">
    <xsl:call-template name="make-whitespace-explicit"/>
    <xsl:call-template name="read-as-copy"/>
  </xsl:template>
  
  
<!-- MODE: unifier -->
  
  <!-- Nested <text>s should have already been handled; here they are copied forward. -->
  <xsl:template match="text" mode="unifier">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <!-- Copy whitespace-only text nodes forward, unless they occur between a soft 
    hyphen and a subsequent wordpart. -->
  <xsl:template match="text()[normalize-space(.) eq '']" mode="unifier" priority="10">
    <xsl:choose>
      <xsl:when test="wf:is-splitting-a-word(.)">
        <seg>
          <xsl:attribute name="read" select="wf:normalize-for-read(.)"/>
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
  
  <!-- Remove soft hyphen delimiters from text nodes.
    If the document uses `@break="no"` to indicate that a word breaks over a line, 
    leading and/or following whitespace will be removed as needed. -->
  <xsl:template match="text()" mode="unifier">
    <xsl:variable name="replaceLeadingRegex" as="xs:string?">
      <xsl:if test="exists(preceding::text()[not(normalize-space(.) eq '')][1]
                                            [matches(., $shyEndingPattern)]) 
                    or exists(preceding::node()[1][wf:has-break-attribute-no(.)])">
        <xsl:text>^\s+</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="replaceEndingRegex" as="xs:string?">
      <xsl:if test="matches(., $shyEndingPattern) 
                    or exists(following::node()[1][wf:has-break-attribute-no(.)])">
        <xsl:text>(­\s*|\s+)$</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="nodeMungingRegex" as="xs:string"
      select="string-join(($replaceLeadingRegex, $replaceEndingRegex), '|')"/>
    <!-- Mark any deletions to the start of this text node. -->
    <xsl:if test="exists($replaceLeadingRegex) and matches(., $replaceLeadingRegex)">
      <xsl:call-template name="remove-breaking-whitespace">
        <xsl:with-param name="replaceLeadingWhitespace" select="true()"/>
      </xsl:call-template>
    </xsl:if>
    <!-- Replace any relevant whitespace. -->
    <xsl:value-of select="if ( $nodeMungingRegex eq '' ) then .
                          else replace(., $nodeMungingRegex, '')"/>
    <!-- Mark any deletions to the end of this text node. -->
    <xsl:if test="exists($replaceEndingRegex) and matches(., $replaceEndingRegex)">
      <xsl:call-template name="remove-breaking-whitespace">
        <xsl:with-param name="replaceLeadingWhitespace" select="false()"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-- Create a <seg> to mark the removal of content from a text node. -->
  <xsl:template name="remove-breaking-whitespace">
    <xsl:param name="replaceLeadingWhitespace" as="xs:boolean"/>
    <xsl:variable name="regex" 
       select="if ( $replaceLeadingWhitespace ) then '^(\s+)' else '(\s+)$'"/>
    <seg>
      <xsl:attribute name="read">
        <xsl:if test="not($replaceLeadingWhitespace) and matches(., $shyEndingPattern)">
          <xsl:text>­</xsl:text>
        </xsl:if>
        <!-- Only mark the deleted whitespace of this text node. -->
        <xsl:analyze-string select="." regex="{ $regex }">
          <xsl:matching-substring>
            <xsl:value-of select="wf:normalize-for-read(regex-group(1))"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring/>
        </xsl:analyze-string>
      </xsl:attribute>
      <xsl:call-template name="set-provenance-attributes">
        <xsl:with-param name="type" select="'shy-part'"/>
        <xsl:with-param name="subtype" select="'add-element mod-content'"/>
      </xsl:call-template>
    </seg>
  </xsl:template>
  
  <!-- If $include-provenance-attributes is toggled off, remove the auto-generated 
    @type of 'implicit-whitespace'. -->
  <xsl:template match="seg[@type eq 'implicit-whitespace']
                          [not($include-provenance-attributes)]" mode="unifier">
    <xsl:copy>
      <xsl:copy-of select="@* except @type"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Delete the results of the 'make-whitespace-explicit' template, if (1) they 
    occur between the parts of a broken word, OR, (2) they are the first child of a 
    pbGroup that has preceding whitespace. -->
  <xsl:template 
    match="seg[@type eq 'implicit-whitespace'][wf:is-splitting-a-word(.)]
         | ab[@type eq 'pbGroup'][preceding::node()[self::text() and matches(., '\s+$')]]
            /*[1][self::seg[@type eq 'implicit-whitespace']]" priority="15" mode="unifier"/>
  
  <!-- If metawork will not be reconstituted ($keep-metawork-text is toggled off), 
    keep <ab> wrappers around pbGroups. -->
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
  <xsl:template match="*[@corresp][not(self::note)][$move-notes-to-anchors]" mode="unifier">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
    <!-- Do not copy the matching note if the current element appears in the middle 
      of a word. -->
    <xsl:if test="not(wf:is-splitting-a-word(.)) and not(@break eq 'no')">
      <xsl:call-template name="insert-preprocessed-note"/>
    </xsl:if>
  </xsl:template>
  
  <!-- If $move-notes-to-anchors is toggled on, anchored notes are suppressed where 
    they appeared in the XML, and copied alongside their referencing context. -->
  <xsl:template match="note[@xml:id][$move-notes-to-anchors]
                           [exists(ancestor::hyperDiv) or not(exists(parent::*))]" mode="unifier">
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
  
  
<!-- MODE: noted -->
  
  <!-- If $move-notes-to-anchors is toggled on, and a <note> cannot be moved 
    without interrupting a word, move it back into the <hyperDiv>. -->
  <xsl:template match="hyperDiv//note[@xml:id][not(node())]" mode="noted">
    <xsl:param name="unmoved-notes" as="node()*" tunnel="yes"/>
    <xsl:variable name="idref" select="concat('#', @xml:id)"/>
    <xsl:choose>
      <xsl:when test="$idref = $unmoved-notes/@sameAs/data(.)">
        <xsl:copy>
          <xsl:copy-of select="@* except (@resp[starts-with(., 'fulltextBot')], @subtype)"/>
          <xsl:copy-of select="$unmoved-notes[@sameAs eq $idref]/node()"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
