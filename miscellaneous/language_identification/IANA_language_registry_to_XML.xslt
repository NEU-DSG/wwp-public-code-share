<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="#all"
  >

  <!--
    IANA_language_registry_to_XML.xslt
    Written 2024-04-24 by Syd Bauman, based (very much)
    on IANA_lang_registry_in_XML.xslt.
    © 2024 by Syd Bauman and the Women Writers Project
    Available under the terms of the MIT License.
  -->

  <!--
      Input (to XSLT engine): does not matter, input is not read
      Input (read in): A copy of the IANA Language Subtag Registry.
      Output: The information from the input converted to a “semantic” XML structure.
      Parameter $input = URL of input (default is https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
      Parameter $output = URL for storing output (default is /tmp/IANA_language_registry.xml)
      Parameter $separator = a string you *know* does not occur in the input (default is ␞␞)
  -->

  <!-- See USAGE NOTE near end for how to process the output of this
       routine into a regular expression for testing @xml:lang (i.e.,
       BCP 47) values. -->
  
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="input" as="xs:string"
             select="'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry'"/>
  <xsl:param name="output" as="xs:string"
             select="'/tmp/IANA_language_subtag_registry.xml'"/>
  <xsl:param name="separator" as="xs:string"
             select="'␞␞'"/>
  
  <xsl:template match="/" name="xsl:initial-template">
    
    <!-- First step: can we read the input? -->
    <xsl:variable name="idunno" as="xs:boolean">
      <xsl:try select="unparsed-text-available( $input )">
        <xsl:catch>
          <xsl:message terminate="yes"
                       select="'ERROR: Cannot read input document ('||$input||')'"/>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    
    <!-- Read in input as a set of text lines: -->
    <xsl:variable name="original_lines" select="unparsed-text-lines( $input )" as="xs:string+"/>
    
    <!-- Convert to a single line, remembering where line boundries occur by changing them to $separator: -->
    <xsl:variable name="origs_as_line"  select="string-join( $original_lines, $separator ) => normalize-space()" as="xs:string"/>
    
    <!-- Join continued lines with previous line by removing the preceding $separator: -->
    <xsl:variable name="joined_as_line" select="replace( $origs_as_line, $separator||'&#x20;', '&#x20;')" as="xs:string"/>
    
    <!-- The registry file uses a line that contains nothing but two PERCENT SIGNs, so chop up by those: -->
    <xsl:variable name="entry_strings" select="tokenize( $joined_as_line, '%%')" as="xs:string+"/>
    
    <!-- Convert each entry string into a set of <record> elements based on remaining $separator strings (remember,
         those strings represent newlines, but those in front of continued lines have been removed). -->
    <xsl:variable name="rawEntries" as="element(rawEntry)+">
      <xsl:for-each select="$entry_strings">
        <rawEntry>
          <!-- The contents of a <rawEntry> is just a sequence of <record> elements, one for each line of text. -->
          <xsl:for-each select="tokenize( ., $separator )">
            <xsl:if test="normalize-space(.) ne ''">
              <entryLine><xsl:sequence select="."/></entryLine>
            </xsl:if>
          </xsl:for-each>
        </rawEntry>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- Convert each raw entry into an entry by processing each line within. -->
    <xsl:variable name="entries" as="element(entry)+">
      <xsl:for-each select="$rawEntries">
        <entry>
          <xsl:apply-templates select="entryLine"/>
        </entry>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- For the output document, process each <entry> into an appropriate
         semantic element representing that entry. -->
    <xsl:result-document href="{$output}">
      <language-subtag-registry count="{count($entries)}"
                                generated="{current-dateTime()}"
                                source="{$input}"
                                sourceDate="{$entries[1]/file-date}">
        <xsl:apply-templates select="$entries[type]"/>
        <!-- But if an <entry> does not have a child <type>, we would not
             know how to generate an output element, so don’t try. -->
      </language-subtag-registry>
    </xsl:result-document>
  </xsl:template>
  
  <!-- The content of each entryLine is a string of the format “Tname: Tcontent”, where Tname is the
       metadata field name (e.g., “Description”, “Added”, “Type”, and “Subtag” are the most common
       by far), and Tcontent, the field value, is just a string. -->
  <xsl:template match="entryLine">
    <!-- Use the field name as the element name: -->
    <xsl:variable name="gi" select="substring-before( ., ':') => lower-case()" as="xs:string"/>
    <!-- Use the rest as the element content: -->
    <xsl:variable name="content" select="substring-after( ., ':') => normalize-space()"/>
    <!-- And now output the new element: -->
    <xsl:element name="{$gi}"><xsl:value-of select="$content"/></xsl:element>
  </xsl:template>
  
  <!-- Convert <entry> to an output element whose name is the entry’s type, whose
       content is the description or comments, and whose attributes are all the
       other information. -->
  <xsl:template match="entry">
    <xsl:element name="{type}">
      <xsl:attribute name="n" select="position()"/>
      <xsl:for-each select="* except ( type, description, comments )">
        <xsl:attribute name="{name(.)}" select="normalize-space(.)"/>
      </xsl:for-each>
      <xsl:copy-of select="description|comments"/>
    </xsl:element>
  </xsl:template>

  <!--
      USAGE NOTE
      
      To generate a regular expression that matches a registered language tag
      alone (i.e., just the “language” production of RFC 5646,
      "lang-extlang"), try
      $ xmlstarlet sel ==template ==match "/"
                         ==output "("
                       ==break 
                       ==template ==match "/*/language/@subtag"
                         ==value "."
                         ==if "position()=last()"
                           ==output ""
                         ==else
                           ==output "|"
                         ==break
                       ==break
                       ==output ")" 
                       ==template ==match "/"
                         ==output "(-("
                       ==break 
                       ==template ==match "/*/extlang/@subtag"
                         ==value "."
                         ==if "position()=last()"
                           ==output ""
                         ==else
                           ==output "|"
                         ==break
                       ==break
                       ==output "))?"
                       ==nl
                       /tmp/IANA_language_subtag_registry.xml 
      all on one line, and changing U+003D to U+002D, of course.
  -->
  
  <!-- Next step: scripts from https://www.unicode.org/iso15924/iso15924.txt -->
</xsl:stylesheet>
