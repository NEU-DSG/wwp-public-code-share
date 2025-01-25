<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="#all"
  >

  <!--
    BCP47_regex_generator.xslt
    Started 2024-05-02 by Syd Bauman, based (very much)
    on IANA_language_registry_to_XML.xslt.
    Some advice taken from https://lib.uw.edu/cams/swr/language-tags/.
    © 2025 by Syd Bauman and the Women Writers Project
    Available under the terms of the MIT License.
  -->

  <!--
      Input (to XSLT engine): does not matter, input is not read
      Inputs (read in):
       * a copy of the IANA Language Subtag Registry
         default is https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
         override with parameter $langs
       * a copy of ISO 15924, codes for scripts
         default is https://www.unicode.org/iso15924/iso15924.txt
         override with parameter $scripts
       * The lists of countries and regions are hard-coded into this program from
         https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
         and
         https://unstats.un.org/unsd/methodology/m49/,
         respectively.
       * The list of extension codes is also hard-coded into this program; there
         are only two of them, ‘t’ and ‘u’.
         
      Outputs:
       0. regular expression
          to STDOUT
       1. semantic XML of language subtag registry
          default to /tmp/IANA_language_subtag_registry.xml, override with parameter $output1
       2. semantic XML of ISO 15924 scripts
          default to /tmp/ISO_15924.xml, override with parameter $output2
       3. regex as part of RELAX NG schema
          default to /tmp/BCP47.rng, override with parameter $output3
       4. regex as part of Schematron schema
          default to /tmp/BCP47.sch, override with parameter $output4

      Parameter $separator = a string you *know* does not occur in the input (default is ␞␞)
  -->
 
  <xsl:output method="text" indent="yes"/>

  <xsl:param name="input1" as="xs:string"
             select="'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry'"/>
  <xsl:param name="input2" as="xs:string" select="'https://www.unicode.org/iso15924/iso15924.txt'"/>
  <xsl:param name="output1" as="xs:string" select="'/tmp/IANA_language_subtag_registry.xml'"/>
  <xsl:param name="output2" as="xs:string" select="'/tmp/ISO_15924.xml'"/>
  <xsl:param name="output3" as="xs:string" select="'/tmp/BCP47.rng'"/>
  <xsl:param name="output4" as="xs:string" select="'/tmp/BCP47.sch'"/>
  <xsl:param name="separator" as="xs:string" select="'␞␞'"/>

  <!--
      ********* main initial template *********
  -->
  <xsl:template match="/" name="xsl:initial-template">

    <!-- language subtags -->
    <xsl:variable name="sem_lang_reg" as="element(language-subtag-registry)">
      <xsl:call-template name="process_lang_reg"/>
    </xsl:variable>
    <xsl:result-document href="{$output1}" method="xml" indent="yes">
      <xsl:sequence select="$sem_lang_reg"/>
    </xsl:result-document>

    <xsl:variable name="sem_scripts" as="element(script_codes)">
      <xsl:call-template name="process_scripts"/>
    </xsl:variable>
    <xsl:result-document href="{$output2}" method="xml" indent="yes">
      <xsl:sequence select="$sem_scripts"/>
    </xsl:result-document>
    
    <xsl:variable name="sem_regions"/>

    <xsl:sequence select="'$regularExpressionHere'"/>
    
  </xsl:template>

  <!--
      ********* process language registry *********
  -->
  <xsl:template name="process_lang_reg" as="element(language-subtag-registry)">

    <!-- First step: can we read the input? -->
    <xsl:variable name="idunno" as="xs:boolean">
      <xsl:try select="unparsed-text-available( $input1 )">
        <xsl:catch>
          <xsl:message terminate="yes"
                       select="'ERROR: Cannot read input document ('||$input1||')'"/>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    
    <!-- Read in language registry as a set of text lines: -->
    <xsl:variable name="LR_lines" select="unparsed-text-lines( $input1 )" as="xs:string+"/>
    
    <!-- Convert to a single line, remembering where line boundries occur by changing them to $separator: -->
    <xsl:variable name="LR_single_line"  select="string-join( $LR_lines, $separator ) => normalize-space()" as="xs:string"/>
    
    <!-- Join continued lines with previous line by removing the preceding $separator: -->
    <xsl:variable name="LR_continued_lines_resolved" select="replace( $LR_single_line, $separator||'&#x20;', '&#x20;')" as="xs:string"/>
    
    <!-- The registry file uses a line that contains nothing but two PERCENT SIGNs, so chop up by those: -->
    <xsl:variable name="LR_raw_entry_strings" select="tokenize( $LR_continued_lines_resolved, '%%')" as="xs:string+"/>
    
    <!-- Convert each entry string into a set of <record> elements based on remaining $separator strings (remember,
         those strings represent newlines, but those in front of continued lines have been removed). -->
    <xsl:variable name="LR_raw_entry_elements" as="element(rawEntry)+">
      <xsl:for-each select="$LR_raw_entry_strings">
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
    <xsl:variable name="LR_entries" as="element(entry)+">
      <xsl:for-each select="$LR_raw_entry_elements">
        <entry>
          <xsl:apply-templates select="entryLine"/>
        </entry>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- For the semantic structure, process each <entry> into an appropriate
         semantic element representing that entry. -->
    <xsl:variable name="semantic_languages" as="element(language-subtag-registry)">
      <language-subtag-registry count="{count($LR_entries)}"
        generated="{current-dateTime()}"
        source="{$input1}"
        sourceDate="{$LR_entries[1]/file-date}">
        <!-- But if an <entry> does not have a child <type>, we would not
             know how to generate an output element, so don’t try. -->
        <xsl:apply-templates select="$LR_entries[type]"/>
      </language-subtag-registry>
    </xsl:variable>

    <xsl:sequence select="$semantic_languages"/>

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
      ********* process scripts *********
  -->
  <xsl:template name="process_scripts" as="element(script_codes)">
    
    <!-- First step: can we read the input? -->
    <xsl:variable name="idunno" as="xs:boolean">
      <xsl:try select="unparsed-text-available( $input2 )">
        <xsl:catch>
          <xsl:message terminate="yes"
            select="'ERROR: Cannot read input document ('||$input2||')'"/>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    
    <!-- Read in language registry as a set of text lines: -->
    <xsl:variable name="SCR_lines" select="unparsed-text-lines( $input2 )" as="xs:string+"/>
    
    <script_codes>
      <xsl:for-each select="$SCR_lines[ string-length(.) gt 2  and  not( fn:starts-with( .,' ')  or  fn:starts-with( ., '#') ) ]">
        <xsl:variable name="SCR_line" select="normalize-space(.)"/>
        <xsl:variable name="SCR_line_parsed" select="fn:tokenize( $SCR_line, ';')"/>
        <script code="{$SCR_line_parsed[1]}" n="{$SCR_line_parsed[2]}" version="{$SCR_line_parsed[6]}" date="{$SCR_line_parsed[7]}">
          <name xml:lang="en"><xsl:sequence select="$SCR_line_parsed[3]"/></name>
          <name xml:lang="fr"><xsl:sequence select="$SCR_line_parsed[4]"/></name>
        </script>
      </xsl:for-each>
    </script_codes>
    
  </xsl:template>
  

  <!-- ********* -->

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
  
  <xsl:variable name="countries" as="map(xs:string,xs:string)" select="map{
    'AD': 'Andorra',
    'AE': 'United Arab Emirates',
    'AF': 'Afghanistan',(:duck:)
    'AG': 'Antigua and Barbuda',
    'AI': 'Anguilla',
    'AL': 'Albania',
    'AM': 'Armenia',
    'AO': 'Angola',
    'AQ': 'Antarctica',
    'AR': 'Argentina',
    'AS': 'American Samoa',
    'AT': 'Austria',
    'AU': 'Australia',
    'AW': 'Aruba',
    'AX': 'Åland Islands',
    'AZ': 'Azerbaijan',
    'BA': 'Bosnia and Herzegovina',
    'BB': 'Barbados',
    'BD': 'Bangladesh',
    'BE': 'Belgium',
    'BF': 'Burkina Faso',
    'BG': 'Bulgaria',
    'BH': 'Bahrain',
    'BI': 'Burundi',
    'BJ': 'Benin',
    'BL': 'Saint Barthélemy',
    'BM': 'Bermuda',
    'BN': 'Brunei Darussalam',
    'BO': 'Bolivia, Plurinational State of',
    'BQ': 'Bonaire, Sint Eustatius and Saba',
    'BR': 'Brazil',
    'BS': 'Bahamas',
    'BT': 'Bhutan',
    'BV': 'Bouvet Island',
    'BW': 'Botswana',
    'BY': 'Belarus',
    'BZ': 'Belize',
    'CA': 'Canada',
    'CC': 'Cocos (Keeling) Islands',
    'CD': 'Congo, Democratic Republic of the',
    'CF': 'Central African Republic',
    'CG': 'Congo',
    'CH': 'Switzerland',
    'CI': &quot;Côte d&apos;Ivoire&quot;,
    'CK': 'Cook Islands',
    'CL': 'Chile',
    'CM': 'Cameroon',
    'CN': 'China',
    'CO': 'Colombia',
    'CR': 'Costa Rica',
    'CU': 'Cuba',
    'CV': 'Cabo Verde',
    'CW': 'Curaçao',
    'CX': 'Christmas Island',
    'CY': 'Cyprus',
    'CZ': 'Czechia',
    'DE': 'Germany',
    'DJ': 'Djibouti',
    'DK': 'Denmark',
    'DM': 'Dominica',
    'DO': 'Dominican Republic',
    'DZ': 'Algeria',
    'EC': 'Ecuador',
    'EE': 'Estonia',
    'EG': 'Egypt',
    'EH': 'Western Sahara',
    'ER': 'Eritrea',
    'ES': 'Spain',
    'ET': 'Ethiopia',
    'FI': 'Finland',
    'FJ': 'Fiji',
    'FK': 'Falkland Islands (Malvinas)',
    'FM': 'Micronesia, Federated States of',
    'FO': 'Faroe Islands',
    'FR': 'France',
    'GA': 'Gabon',
    'GB': 'United Kingdom of Great Britain and Northern Ireland',
    'GD': 'Grenada',
    'GE': 'Georgia',
    'GF': 'French Guiana',
    'GG': 'Guernsey',
    'GH': 'Ghana',
    'GI': 'Gibraltar',
    'GL': 'Greenland',
    'GM': 'Gambia',
    'GN': 'Guinea',
    'GP': 'Guadeloupe',
    'GQ': 'Equatorial Guinea',
    'GR': 'Greece',
    'GS': 'South Georgia and the South Sandwich Islands',
    'GT': 'Guatemala',
    'GU': 'Guam',
    'GW': 'Guinea-Bissau',
    'GY': 'Guyana',
    'HK': 'Hong Kong',
    'HM': 'Heard Island and McDonald Islands',
    'HN': 'Honduras',
    'HR': 'Croatia',
    'HT': 'Haiti',
    'HU': 'Hungary',
    'ID': 'Indonesia',
    'IE': 'Ireland',
    'IL': 'Israel',
    'IM': 'Isle of Man',
    'IN': 'India',
    'IO': 'British Indian Ocean Territory',
    'IQ': 'Iraq',
    'IR': 'Iran, Islamic Republic of',
    'IS': 'Iceland',
    'IT': 'Italy',
    'JE': 'Jersey',
    'JM': 'Jamaica',
    'JO': 'Jordan',
    'JP': 'Japan',
    'KE': 'Kenya',
    'KG': 'Kyrgyzstan',
    'KH': 'Cambodia',
    'KI': 'Kiribati',
    'KM': 'Comoros',
    'KN': 'Saint Kitts and Nevis',
    'KP': &quot;Korea, Democratic People&apos;s Republic of&quot;,
    'KR': 'Korea, Republic of',
    'KW': 'Kuwait',
    'KY': 'Cayman Islands',
    'KZ': 'Kazakhstan',
    'LA': &quot;Lao People&apos;s Democratic Republic&quot;,
    'LB': 'Lebanon',
    'LC': 'Saint Lucia',
    'LI': 'Liechtenstein',
    'LK': 'Sri Lanka',
    'LR': 'Liberia',
    'LS': 'Lesotho',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'LV': 'Latvia',
    'LY': 'Libya',
    'MA': 'Morocco',
    'MC': 'Monaco',
    'MD': 'Moldova, Republic of',
    'ME': 'Montenegro',
    'MF': 'Saint Martin (French part)',
    'MG': 'Madagascar',
    'MH': 'Marshall Islands',
    'MK': 'North Macedonia',
    'ML': 'Mali',
    'MM': 'Myanmar',
    'MN': 'Mongolia',
    'MO': 'Macao',
    'MP': 'Northern Mariana Islands',
    'MQ': 'Martinique',
    'MR': 'Mauritania',
    'MS': 'Montserrat',
    'MT': 'Malta',
    'MU': 'Mauritius',
    'MV': 'Maldives',
    'MW': 'Malawi',
    'MX': 'Mexico',
    'MY': 'Malaysia',
    'MZ': 'Mozambique',
    'NA': 'Namibia',
    'NC': 'New Caledonia',
    'NE': 'Niger',
    'NF': 'Norfolk Island',
    'NG': 'Nigeria',
    'NI': 'Nicaragua',
    'NL': 'Netherlands, Kingdom of the',
    'NO': 'Norway',
    'NP': 'Nepal',
    'NR': 'Nauru',
    'NU': 'Niue',
    'NZ': 'New Zealand',
    'OM': 'Oman',
    'PA': 'Panama',
    'PE': 'Peru',
    'PF': 'French Polynesia',
    'PG': 'Papua New Guinea',
    'PH': 'Philippines',
    'PK': 'Pakistan',
    'PL': 'Poland',
    'PM': 'Saint Pierre and Miquelon',
    'PN': 'Pitcairn',
    'PR': 'Puerto Rico',
    'PS': 'Palestine, State of',
    'PT': 'Portugal',
    'PW': 'Palau',
    'PY': 'Paraguay',
    'QA': 'Qatar',
    'RE': 'Réunion',
    'RO': 'Romania',
    'RS': 'Serbia',
    'RU': 'Russian Federation',
    'RW': 'Rwanda',
    'SA': 'Saudi Arabia',
    'SB': 'Solomon Islands',
    'SC': 'Seychelles',
    'SD': 'Sudan',
    'SE': 'Sweden',
    'SG': 'Singapore',
    'SH': 'Saint Helena, Ascension and Tristan da Cunha',
    'SI': 'Slovenia',
    'SJ': 'Svalbard and Jan Mayen',
    'SK': 'Slovakia',
    'SL': 'Sierra Leone',
    'SM': 'San Marino',
    'SN': 'Senegal',
    'SO': 'Somalia',
    'SR': 'Suriname',
    'SS': 'South Sudan',
    'ST': 'Sao Tome and Principe',
    'SV': 'El Salvador',
    'SX': 'Sint Maarten (Dutch part)',
    'SY': 'Syrian Arab Republic',
    'SZ': 'Eswatini',
    'TC': 'Turks and Caicos Islands',
    'TD': 'Chad',
    'TF': 'French Southern Territories',
    'TG': 'Togo',
    'TH': 'Thailand',
    'TJ': 'Tajikistan',
    'TK': 'Tokelau',
    'TL': 'Timor-Leste',
    'TM': 'Turkmenistan',
    'TN': 'Tunisia',
    'TO': 'Tonga',
    'TR': 'Türkiye',
    'TT': 'Trinidad and Tobago',
    'TV': 'Tuvalu',
    'TW': 'Taiwan, Province of China',
    'TZ': 'Tanzania, United Republic of',
    'UA': 'Ukraine',
    'UG': 'Uganda',
    'UM': 'United States Minor Outlying Islands',
    'US': 'United States of America',
    'UY': 'Uruguay',
    'UZ': 'Uzbekistan',
    'VA': 'Holy See',
    'VC': 'Saint Vincent and the Grenadines',
    'VE': 'Venezuela, Bolivarian Republic of',
    'VG': 'Virgin Islands (British)',
    'VI': 'Virgin Islands (U.S.)',
    'VN': 'Viet Nam',
    'VU': 'Vanuatu',
    'WF': 'Wallis and Futuna',
    'WS': 'Samoa',
    'YE': 'Yemen',
    'YT': 'Mayotte',
    'ZA': 'South Africa',
    'ZM': 'Zambia',
    'ZW': 'Zimbabwe',
    'AC': 'Ascension Island',
    'CP': 'Clipperton Island',
    'CQ': 'Island of Sark',
    'DG': 'Diego Garcia',
    'EA': 'Ceuta, Melilla',
    'EU': 'European Union',
    'EZ': 'Eurozone',
    'FX': 'France, Metropolitan',
    'IC': 'Canary Islands',
    'SU': 'USSR',
    'TA': 'Tristan da Cunha',
    'UK': 'United Kingdom',
    'UN': 'United Nations'
    }">
    <!-- List created by copying the table from https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
         and hand-editing. -->
  </xsl:variable>
  
  <xsl:variable name="regions" as="map(xs:string,xs:string)" select="map{
    'Afghanistan':                                          '004',  (: AFG :)
    'Åland Islands':                                        '248',  (: ALA :)
    'Albania':                                              '008',  (: ALB :)
    'Algeria':                                              '012',  (: DZA :)
    'American Samoa':                                       '016',  (: ASM :)
    'Andorra':                                              '020',  (: AND :)
    'Angola':                                               '024',  (: AGO :)
    'Anguilla':                                             '660',  (: AIA :)
    'Antarctica':                                           '010',  (: ATA :)
    'Antigua and Barbuda':                                  '028',  (: ATG :)
    'Argentina':                                            '032',  (: ARG :)
    'Armenia':                                              '051',  (: ARM :)
    'Aruba':                                                '533',  (: ABW :)
    'Australia':                                            '036',  (: AUS :)
    'Austria':                                              '040',  (: AUT :)
    'Azerbaijan':                                           '031',  (: AZE :)
    'Bahamas':                                              '044',  (: BHS :)
    'Bahrain':                                              '048',  (: BHR :)
    'Bangladesh':                                           '050',  (: BGD :)
    'Barbados':                                             '052',  (: BRB :)
    'Belarus':                                              '112',  (: BLR :)
    'Belgium':                                              '056',  (: BEL :)
    'Belize':                                               '084',  (: BLZ :)
    'Benin':                                                '204',  (: BEN :)
    'Bermuda':                                              '060',  (: BMU :)
    'Bhutan':                                               '064',  (: BTN :)
    'Bolivia (Plurinational State of)':                     '068',  (: BOL :)
    'Bonaire, Sint Eustatius and Saba':                     '535',  (: BES :)
    'Bosnia and Herzegovina':                               '070',  (: BIH :)
    'Botswana':                                             '072',  (: BWA :)
    'Bouvet Island':                                        '074',  (: BVT :)
    'Brazil':                                               '076',  (: BRA :)
    'British Indian Ocean Territory':                       '086',  (: IOT :)
    'British Virgin Islands':                               '092',  (: VGB :)
    'Brunei Darussalam':                                    '096',  (: BRN :)
    'Bulgaria':                                             '100',  (: BGR :)
    'Burkina Faso':                                         '854',  (: BFA :)
    'Burundi':                                              '108',  (: BDI :)
    'Cabo Verde':                                           '132',  (: CPV :)
    'Cambodia':                                             '116',  (: KHM :)
    'Cameroon':                                             '120',  (: CMR :)
    'Canada':                                               '124',  (: CAN :)
    'Cayman Islands':                                       '136',  (: CYM :)
    'Central African Republic':                             '140',  (: CAF :)
    'Chad':                                                 '148',  (: TCD :)
    'Chile':                                                '152',  (: CHL :)
    'China':                                                '156',  (: CHN :)
    'China, Hong Kong Special Administrative Region':       '344',  (: HKG :)
    'China, Macao Special Administrative Region':           '446',  (: MAC :)
    'Christmas Island':                                     '162',  (: CXR :)
    'Cocos (Keeling) Islands':                              '166',  (: CCK :)
    'Colombia':                                             '170',  (: COL :)
    'Comoros':                                              '174',  (: COM :)
    'Congo':                                                '178',  (: COG :)
    'Cook Islands':                                         '184',  (: COK :)
    'Costa Rica':                                           '188',  (: CRI :)
    'Côte d’Ivoire':                                        '384',  (: CIV :)
    'Croatia':                                              '191',  (: HRV :)
    'Cuba':                                                 '192',  (: CUB :)
    'Curaçao':                                              '531',  (: CUW :)
    'Cyprus':                                               '196',  (: CYP :)
    'Czechia':                                              '203',  (: CZE :)
    &quot;Democratic People&apos;s Republic of Korea&quot;: '408',  (: PRK :)
    'Democratic Republic of the Congo':                     '180',  (: COD :)
    'Denmark':                                              '208',  (: DNK :)
    'Djibouti':                                             '262',  (: DJI :)
    'Dominica':                                             '212',  (: DMA :)
    'Dominican Republic':                                   '214',  (: DOM :)
    'Ecuador':                                              '218',  (: ECU :)
    'Egypt':                                                '818',  (: EGY :)
    'El Salvador':                                          '222',  (: SLV :)
    'Equatorial Guinea':                                    '226',  (: GNQ :)
    'Eritrea':                                              '232',  (: ERI :)
    'Estonia':                                              '233',  (: EST :)
    'Eswatini':                                             '748',  (: SWZ :)
    'Ethiopia':                                             '231',  (: ETH :)
    'Falkland Islands (Malvinas)':                          '238',  (: FLK :)
    'Faroe Islands':                                        '234',  (: FRO :)
    'Fiji':                                                 '242',  (: FJI :)
    'Finland':                                              '246',  (: FIN :)
    'France':                                               '250',  (: FRA :)
    'French Guiana':                                        '254',  (: GUF :)
    'French Polynesia':                                     '258',  (: PYF :)
    'French Southern Territories':                          '260',  (: ATF :)
    'Gabon':                                                '266',  (: GAB :)
    'Gambia':                                               '270',  (: GMB :)
    'Georgia':                                              '268',  (: GEO :)
    'Germany':                                              '276',  (: DEU :)
    'Ghana':                                                '288',  (: GHA :)
    'Gibraltar':                                            '292',  (: GIB :)
    'Greece':                                               '300',  (: GRC :)
    'Greenland':                                            '304',  (: GRL :)
    'Grenada':                                              '308',  (: GRD :)
    'Guadeloupe':                                           '312',  (: GLP :)
    'Guam':                                                 '316',  (: GUM :)
    'Guatemala':                                            '320',  (: GTM :)
    'Guernsey':                                             '831',  (: GGY :)
    'Guinea':                                               '324',  (: GIN :)
    'Guinea-Bissau':                                        '624',  (: GNB :)
    'Guyana':                                               '328',  (: GUY :)
    'Haiti':                                                '332',  (: HTI :)
    'Heard Island and McDonald Islands':                    '334',  (: HMD :)
    'Holy See':                                             '336',  (: VAT :)
    'Honduras':                                             '340',  (: HND :)
    'Hungary':                                              '348',  (: HUN :)
    'Iceland':                                              '352',  (: ISL :)
    'India':                                                '356',  (: IND :)
    'Indonesia':                                            '360',  (: IDN :)
    'Iran (Islamic Republic of)':                           '364',  (: IRN :)
    'Iraq':                                                 '368',  (: IRQ :)
    'Ireland':                                              '372',  (: IRL :)
    'Isle of Man':                                          '833',  (: IMN :)
    'Israel':                                               '376',  (: ISR :)
    'Italy':                                                '380',  (: ITA :)
    'Jamaica':                                              '388',  (: JAM :)
    'Japan':                                                '392',  (: JPN :)
    'Jersey':                                               '832',  (: JEY :)
    'Jordan':                                               '400',  (: JOR :)
    'Kazakhstan':                                           '398',  (: KAZ :)
    'Kenya':                                                '404',  (: KEN :)
    'Kiribati':                                             '296',  (: KIR :)
    'Kuwait':                                               '414',  (: KWT :)
    'Kyrgyzstan':                                           '417',  (: KGZ :)
    &quot;Lao People&apos;s Democratic Republic&quot;:      '418',  (: LAO :)
    'Latvia':                                               '428',  (: LVA :)
    'Lebanon':                                              '422',  (: LBN :)
    'Lesotho':                                              '426',  (: LSO :)
    'Liberia':                                              '430',  (: LBR :)
    'Libya':                                                '434',  (: LBY :)
    'Liechtenstein':                                        '438',  (: LIE :)
    'Lithuania':                                            '440',  (: LTU :)
    'Luxembourg':                                           '442',  (: LUX :)
    'Madagascar':                                           '450',  (: MDG :)
    'Malawi':                                               '454',  (: MWI :)
    'Malaysia':                                             '458',  (: MYS :)
    'Maldives':                                             '462',  (: MDV :)
    'Mali':                                                 '466',  (: MLI :)
    'Malta':                                                '470',  (: MLT :)
    'Marshall Islands':                                     '584',  (: MHL :)
    'Martinique':                                           '474',  (: MTQ :)
    'Mauritania':                                           '478',  (: MRT :)
    'Mauritius':                                            '480',  (: MUS :)
    'Mayotte':                                              '175',  (: MYT :)
    'Mexico':                                               '484',  (: MEX :)
    'Micronesia (Federated States of)':                     '583',  (: FSM :)
    'Monaco':                                               '492',  (: MCO :)
    'Mongolia':                                             '496',  (: MNG :)
    'Montenegro':                                           '499',  (: MNE :)
    'Montserrat':                                           '500',  (: MSR :)
    'Morocco':                                              '504',  (: MAR :)
    'Mozambique':                                           '508',  (: MOZ :)
    'Myanmar':                                              '104',  (: MMR :)
    'Namibia':                                              '516',  (: NAM :)
    'Nauru':                                                '520',  (: NRU :)
    'Nepal':                                                '524',  (: NPL :)
    'Netherlands (Kingdom of the)':                         '528',  (: NLD :)
    'New Caledonia':                                        '540',  (: NCL :)
    'New Zealand':                                          '554',  (: NZL :)
    'Nicaragua':                                            '558',  (: NIC :)
    'Niger':                                                '562',  (: NER :)
    'Nigeria':                                              '566',  (: NGA :)
    'Niue':                                                 '570',  (: NIU :)
    'Norfolk Island':                                       '574',  (: NFK :)
    'North Macedonia':                                      '807',  (: MKD :)
    'Northern Mariana Islands':                             '580',  (: MNP :)
    'Norway':                                               '578',  (: NOR :)
    'Oman':                                                 '512',  (: OMN :)
    'Pakistan':                                             '586',  (: PAK :)
    'Palau':                                                '585',  (: PLW :)
    'Panama':                                               '591',  (: PAN :)
    'Papua New Guinea':                                     '598',  (: PNG :)
    'Paraguay':                                             '600',  (: PRY :)
    'Peru':                                                 '604',  (: PER :)
    'Philippines':                                          '608',  (: PHL :)
    'Pitcairn':                                             '612',  (: PCN :)
    'Poland':                                               '616',  (: POL :)
    'Portugal':                                             '620',  (: PRT :)
    'Puerto Rico':                                          '630',  (: PRI :)
    'Qatar':                                                '634',  (: QAT :)
    'Republic of Korea':                                    '410',  (: KOR :)
    'Republic of Moldova':                                  '498',  (: MDA :)
    'Réunion':                                              '638',  (: REU :)
    'Romania':                                              '642',  (: ROU :)
    'Russian Federation':                                   '643',  (: RUS :)
    'Rwanda':                                               '646',  (: RWA :)
    'Saint Barthélemy':                                     '652',  (: BLM :)
    'Saint Helena':                                         '654',  (: SHN :)
    'Saint Kitts and Nevis':                                '659',  (: KNA :)
    'Saint Lucia':                                          '662',  (: LCA :)
    'Saint Martin (French Part)':                           '663',  (: MAF :)
    'Saint Pierre and Miquelon':                            '666',  (: SPM :)
    'Saint Vincent and the Grenadines':                     '670',  (: VCT :)
    'Samoa':                                                '882',  (: WSM :)
    'San Marino':                                           '674',  (: SMR :)
    'Sao Tome and Principe':                                '678',  (: STP :)
    'Saudi Arabia':                                         '682',  (: SAU :)
    'Senegal':                                              '686',  (: SEN :)
    'Serbia':                                               '688',  (: SRB :)
    'Seychelles':                                           '690',  (: SYC :)
    'Sierra Leone':                                         '694',  (: SLE :)
    'Singapore':                                            '702',  (: SGP :)
    'Sint Maarten (Dutch part)':                            '534',  (: SXM :)
    'Slovakia':                                             '703',  (: SVK :)
    'Slovenia':                                             '705',  (: SVN :)
    'Solomon Islands':                                      '090',  (: SLB :)
    'Somalia':                                              '706',  (: SOM :)
    'South Africa':                                         '710',  (: ZAF :)
    'South Georgia and the South Sandwich Islands':         '239',  (: SGS :)
    'South Sudan':                                          '728',  (: SSD :)
    'Spain':                                                '724',  (: ESP :)
    'Sri Lanka':                                            '144',  (: LKA :)
    'State of Palestine':                                   '275',  (: PSE :)
    'Sudan':                                                '729',  (: SDN :)
    'Suriname':                                             '740',  (: SUR :)
    'Svalbard and Jan Mayen Islands':                       '744',  (: SJM :)
    'Sweden':                                               '752',  (: SWE :)
    'Switzerland':                                          '756',  (: CHE :)
    'Syrian Arab Republic':                                 '760',  (: SYR :)
    'Tajikistan':                                           '762',  (: TJK :)
    'Thailand':                                             '764',  (: THA :)
    'Timor-Leste':                                          '626',  (: TLS :)
    'Togo':                                                 '768',  (: TGO :)
    'Tokelau':                                              '772',  (: TKL :)
    'Tonga':                                                '776',  (: TON :)
    'Trinidad and Tobago':                                  '780',  (: TTO :)
    'Tunisia':                                              '788',  (: TUN :)
    'Türkiye':                                              '792',  (: TUR :)
    'Turkmenistan':                                         '795',  (: TKM :)
    'Turks and Caicos Islands':                             '796',  (: TCA :)
    'Tuvalu':                                               '798',  (: TUV :)
    'Uganda':                                               '800',  (: UGA :)
    'Ukraine':                                              '804',  (: UKR :)
    'United Arab Emirates':                                 '784',  (: ARE :)
    'United Kingdom of Great Britain and Northern Ireland': '826',  (: GBR :)
    'United Republic of Tanzania':                          '834',  (: TZA :)
    'United States Minor Outlying Islands':                 '581',  (: UMI :)
    'United States of America':                             '840',  (: USA :)
    'United States Virgin Islands':                         '850',  (: VIR :)
    'Uruguay':                                              '858',  (: URY :)
    'Uzbekistan':                                           '860',  (: UZB :)
    'Vanuatu':                                              '548',  (: VUT :)
    'Venezuela (Bolivarian Republic of)':                   '862',  (: VEN :)
    'Viet Nam':                                             '704',  (: VNM :)
    'Wallis and Futuna Islands':                            '876',  (: WLF :)
    'Western Sahara':                                       '732',  (: ESH :)
    'Yemen':                                                '887',  (: YEM :)
    'Zambia':                                               '894',  (: ZMB :)
    'Zimbabwe':                                             '716'   (: ZWE :)
    }">
    <!-- List created by copying the content of the table on
         https://unstats.un.org/unsd/methodology/m49/
         on 2025-01-24 and hand-editing. -->
  </xsl:variable>
  
  <!-- Next step: scripts from https://www.unicode.org/iso15924/iso15924.txt -->
</xsl:stylesheet>
