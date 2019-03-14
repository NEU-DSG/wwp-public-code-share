<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  version="3.0">
  
  <!-- Copyleft 2018 Syd Bauman and the Women Writers Project -->
  
  <!--
    NOTE: There is a more WWP-specific version of this
    program in [TB]/stylesheets/.
  -->

  <!--
    Read in a TEI document, and write out the default rendition(s)
    that match a specified GI. GIs may be specified on the commandline
    via the $GIs parameter. (A sequence of strings that should match the
    requirements of xs:NCName or '*', but are actually xs:string(s).)
  -->

  <!--
    Example usage on a single file:
    $ saxon -xsl:/path/to/find_specific_renditional_defaults.xslt -s:distribution/elizabeth.lastspeech.xml -o:/dev/null/ '?GIs=("fw","pb","milestone","div")'
    Example usage on a directory:
    $ saxon -xsl:/path/to/find_specific_renditional_defaults.xslt -s:INPUTdir/ -o:/tmp/OUTPUTdir/ '?GIs=("fw","pb","milestone","div")'
    Note that in the single file case we can just toss away the output
    by sending it to /dev/null; but we can't do that in the directory-
    at-a-time case, because Saxon requires that if -s: is a directory
    then so must -o: be.
  -->

  <!-- The elements to look for as a sequence of GIs (i.e., element names) -->
  <xsl:param select="('p','bibl')" name="GIs" as="xs:string+"/>
  <xsl:variable name="universal" select="$GIs = '*'" as="xs:boolean"/>
  <!-- Get the name of the input file (and its directory) for future use -->
  <xsl:variable name="inputDir" select="tokenize( base-uri(/),'/')[last()-1]"/>
  <xsl:variable name="inputFile" select="tokenize( base-uri(/),'/')[last()]"/>

  <!--
    Proclaim our output as simple text just to keep output files smaller
    (no XML declaration). Actually, there is no useful output to STDOUT
    at all. All useful information goes to STDERR via <xsl:message>
    instructions.
  -->
  <xsl:output method="text"/>
  
  <xsl:template match="/">
    <!-- Process only the bits of the document we are interested in -->
    <xsl:apply-templates select="/TEI/teiHeader/encodingDesc//rendition"/>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="rendition">
    <!--
      Get our content for reporting later. Notes:
      1) We won't be able to just use '.' later, because by the time we want access
         to this information the context node will have changed.
      2) We normalize the space for readability. But if you have rendition ladders
         that have significant space within (e.g., "fill(.  )"), you probably don't
         want that.
    -->
    <xsl:variable name="content" select="normalize-space(.)"/>
    <!-- Parse out individual selectors from a group of selectors. -->
    <xsl:variable name="selectors" select="for $s in tokenize( @selector,',') return normalize-space($s)"/>
    <!-- Now iterate over each individual selector, and for each of 'em ... -->
    <xsl:for-each select="$selectors">
      <!--
        ... check to see if one of the GIs of interest appears. Note that this simple
        test works for us because we have only type selectors, never an attribute
        selector, class selector, ID selector, pseudo-element, or a pseudo-class.
        In fact, we never use an adjacent ('+') or general ('~') sibling cominator,
        either, but there's no harm checking for 'em.
      -->
      <xsl:if test="$universal  or  tokenize( .,'[&#x20;&gt;+~]+') = $GIs">
        <!--
          So that test above first checks to see if user asked for '*', the
          universal selector; if so, test succeeds. If not, it then chops
          the selector we are examining into a sequences of simple selectors,
          and compares each simple selector to each requested GI. If any one
          on L matches any one on R, test succeeds.
        -->
        <xsl:message select="'---------'||$inputDir||'/'||$inputFile||' | selector='||.||' | '||$content"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
