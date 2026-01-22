#!/usr/bin/env perl
#
# $Id: dates_and_times_in_DH_regex_generator.perl 3842 2025-12-19 02:24:37Z syd $
#
# Copyright 2023 Syd Bauman and the Northeastern University Digital
# Scholarship Group. Some rights reserved. For complete copyleft
# notice, see block comment at the end of this file.
#
# when-iso_regex_generator.perl
#
# usage
# -----
#       $PROGRAM_NAME
#
# Input: none.
# Output to STDERR: possibly some debugging information and a copy of
# a W3C-flavored regular expression that should match most any temporal
# expression that uses “Dates and Times in DH” facet of ISO 8601:2019,
# and reject most any string that is not such a temporal expression.
# intended to be used in a schema that wants to check the value of
# the TEI @when-iso attribute.
# Output to STDOUT: a small RELAX NG grammar which uses said regexp to
# check @when-iso, @valid, and @invalid; it can be used to validate
# itself for debugging.
# Alternate to STDOUT: by changing the final "print STDOUT" statement,
# you can instead get a small XSLT program which uses said regexp to
# check //@valid and //@invalid which can be used to transform itself
# for debugging.
# NOTE: Plans are to create a switch for whether the XSLT or RELAX NG
# output is generated. Right now it's just hard coded.
# NOTE: The regexp has a "\s*" appended at each end, as W3C regular
# expressions are by default anchored. For the XSLT version, though, 
# we also anchor it, as there we are using matches(), which does not
# anchor the regexp (because it is looking for any sub-string that matches).
#
# debugging
# ---------
# With output set to $relax, set $regexp to the sub-component you want
# to test, or leave it as $wheniso for the entire thing, and issue:
# $ /path/to/this_pgm.perl > /tmp/twirg.rng && java -Xss4m -jar /path/to/Oxygen_XML_Editor_26/lib/oxygen-patched-jing.jar /tmp/twirg.rng /tmp/twirg.rng | egrep -v '^.?\]' | perl -pe 's,;.*$,,;' | tee /tmp/twirg.err | perl -pe 's,^([^:]+):([0-9]+):.*$,head -n $2 $1 | tail -n 1,;' > /tmp/twirg.run && source /tmp/twirg.run
# This gives you:
# 1) The regexp to STDERR
# 2) /tmp/twirg.rng: the generated RELAX NG schema
# 3) /tmp/twirg.err: an extract of output of running `jing` on that
#    schema against itself
# 4) /tmp/twirg.run: that output re-arranged into bash commands to
#    extract the lines that cause errors
# 5) The lines extracted to STDOUT

use English; use strict;

# --------- program goes here --------- #

sub now {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    $mon++;
    $year += 1900;
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d", 
                   $year, $mon, $mday, $hour, $min, $sec);
}
my $now=now();

# general purpose snippets
my $dx = "[0-9X]";                 # a digit or ‘X’ for unspecified
my $optminus = "-?";               # optional minus, ‘⊖’ (U+2296) in the paper
my $plusminus = "[+\\-]";          # plus or minus, ‘±’ (U+00B1) in the paper
my $q  = "[?~%]?";                 # optional quantification character
my $decsep = "[,.]";               # decimal separator
my $decimal = "( $decsep $dx+ )?"; # optional decimal expression of fractions

# implicit form snippets
my $YYYY = "$optminus$dx\{4\}"; # year, always 4 digits (‘X’ for unspecified)
my $MM = "( [0X][1-9X] | 1[012X] )"; # month, 01–12 (‘X’ for unspecified)
my $ydiv = "( 2[1-9] | 3[0-9] | 4[01] )"; # sub-year division (other than month), 21–41
my $DD = "( 0[1-9X] | [12X]$dx | 3[01X] )"; # day of month, 01–31 (‘X’ for unspecified)
my $HH = "( [01X]$dx | 2[0-3X] )";      # hour, 01–23 (‘X’ for unspecified)
my $mm = "( [0-5X]$dx )";               # minute, 00–59 (‘X’ for unspecified)
my $ss = "( [0-5X]$dx )";               # second, 00–59 (‘X’ for unspecified)
my $TZ = "( ( $plusminus $HH ([:][0-5][0-9])? ) | Z )?";   # time zone shift indicator
my $ordinalday = "( 00[1-9X] | 0[1-9X][0-9X] | [123X][0-9X][0-9X] )"; # 001–366 (‘X’ for unspecified)
my $weeknum = "( 0[1-9X] | [1-4X][0-9X] | 5[0-3X] )"; # 01–53 (‘X’ for unspecified)
my $weekday = "[1-7X]";

# implicit forms WITHOUT qualification
## normal
my $century  = "$optminus$dx\{2\}";     # 2 digits (‘X’ for unspecified)
my $decade   = "$optminus$dx\{3\}";     # 3 digits (‘X’ for unspecified)
my $date     = "$YYYY(-$MM(-$DD)?)?$decimal"; # date, possibly with reduced prescision of components, possibly with added decimal precision
my $timecon  = "T$HH([:]$mm([:]$ss)?)?$decimal$TZ"; # time with 'T' (neither mins nor secs required)
my $timesans = "$HH:$mm([:]$ss)?$decimal$TZ"; # time without 'T' (mins required)
my $dateTime = "$YYYY-$MM-$DD" . "$timecon"; # complete date & time to hour, min, or sec, possibly w/ decimal or TZ
## ordinal
my $ordinalsanstime = "$YYYY-$ordinalday$decimal$TZ";
my $ordinalcontime  = "$YYYY-$ordinalday$timecon";
## weekdates
my $weekdatesanstime = "$YYYY-W$weeknum(-$weekday)?";
my $weekdatecontime  = "$YYYY-W$weeknum-$weekday$timecon";

# implicit forms with general qualification
## normal
my $Qcentury  = "$century$q";
my $Qdecade   = "$decade$q";
my $QYYYY     = "$YYYY$decimal$q";
my $QYYYY_MM  = "$YYYY$q-$q$MM$decimal$q";
my $QYYYY_div = "$YYYY$q-$q$ydiv$q";
my $QYYYY_MM_DD = "$YYYY$q-$q$MM$q-$q$DD$decimal$q";
my $QYYYY_MM_DD_HH = "$YYYY$q-$q$MM$q-$q$DD$q" . "T" . "$q$HH$decimal$q$TZ";
my $QYYYY_MM_DD_HH_MM = "$YYYY$q-$q$MM$q-$q$DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$decimal$q$TZ";
my $QYYYY_MM_DD_HH_MM_SS = "$YYYY$q-$q$MM$q-$q$DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ";
my $QHHcon = "T$HH$decimal$q$TZ";
my $QHH_MMcon = "T$q$HH$q" . ":" . "$q$mm$decimal$q$TZ";
my $QHH_MM_SScon = "T$q$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ";
my $QHH_MMsans = "$q$HH$q" . ":" . "$q$mm$decimal$q$TZ";
my $QHH_MM_SSsans = "$q$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ";
my $Qtimecon = "( $QHHcon | $QHH_MMcon | $QHH_MM_SScon )";
## ordinal
my $Qordinalsanstime = "$YYYY$q-$q$ordinalday$decimal$TZ";
my $Qordinalcontime  = "$YYYY$q-$q$ordinalday$Qtimecon";
## weekdates
my $Qweekdatesanstime = "$YYYY$q-$q" . "W$weeknum$q(-$q$weekday$q)?";
my $Qweekdatecontime  = "$YYYY$q-$q" . "W$weeknum$q-$q$weekday$Qtimecon";

# explicit forms WITHOUT qualification
## snippets
my $eyear   = "( $optminus$dx+$q" . "Y )";      # parens useful later
my $emonth  = "( [0X]?[1-9X] | 1[012X] )$q" . "M";
my $eday    = "( 0?[1-9X] | [12X]$dx | 3[01X] )$q" . "D";
my $ehour   = "( ( [01X]?$dx | 2[0-3X] )$q" . "H)";
my $emin    = "( ( [0-5X]?$dx )$q" . "M)";
my $esec    = "( [0-5X]?$dx )$q" . "S";
my $eweek   = "( 0?$dx | [1-4X]$dx | 5[0-3X] )$q" . "W";
## snippets w/ decimal (the ‘u’ at the end is for “ultimate”)
my $eyearu  = "( $optminus$dx+$q" . "Y$decimal )";      # parens useful later
my $emonthu = "( [0X]?[1-9X] | 1[012X] )$q" . "M$decimal";
my $edayu   = "( 0?[1-9X] | [12X]$dx | 3[01X] )$q" . "D$decimal";
my $ehouru  = "( [01X]?$dx | 2[0-3X] )$q" . "H$decimal";
my $eminu   = "( [0-5X]?$dx )$q" . "M$decimal";
my $esecu   = "( [0-5X]?$dx )$q" . "S$decimal";
my $eweeku  = "( 0?$dx | [1-4X]$dx | 5[0-3X] )$q" . "W$decimal";

my $explicitY  = "$eyearu";
my $explicitYM = "$eyear $emonthu";
my $explicitYD = "$eyear $emonth $edayu";
my $explicitYH = "$eyear $emonth $eday T $ehouru";
my $explicitYm = "$eyear $emonth $eday T $ehour? $eminu";
my $explicitYS = "$eyear $emonth $eday T $ehour? $emin? $esecu";
my $explicitM  = "$emonthu";
my $explicitMD = "$emonth $edayu";
my $explicitMH = "$emonth $eday T $ehouru";
my $explicitMm = "$emonth $eday T $ehour? $eminu";
my $explicitMS = "$emonth $eday T $ehour? $emin? $esecu";
my $explicitD  = "$edayu";
my $explicitDH = "$eday T $ehouru";
my $explicitDm = "$eday T $ehour? $eminu";
my $explicitDS = "$eday T $ehour? $emin? $esecu";
my $explicitH  = "T $ehouru";
my $explicitHm = "T $ehour? $eminu";
my $explicitHS = "T $ehour? $emin? $esecu";
my $explicitm  = "T $eminu";
my $explicitmS = "T $emin? $esecu";
my $explicitS  = "T $esecu";

my $explicit = "( $explicitY | $explicitYM | $explicitYD | $explicitYH | $explicitYm | $explicitYS | $explicitM | $explicitMD | $explicitMH | $explicitMm | $explicitMS | $explicitD | $explicitDH | $explicitDm | $explicitDS | $explicitH | $explicitHm | $explicitHS | $explicitm | $explicitmS | $explicitS )";
my $duration = "P($explicit|( [1-9X] | [1-4X][0-9X] | 5[23X] )$q" . "W)";

##
## Major components are a collection of the above Note that since
## these are _only_ used in alternation the parens surrounding each
## set of alternates are not strictly needed. They make debugging a
## bit easier, though.
##
my $supra = "( $Qcentury | $Qdecade | $QYYYY_div )";
my $normal = "( $QYYYY | $QYYYY_MM | $QYYYY_MM_DD | $QYYYY_MM_DD_HH | $QYYYY_MM_DD_HH_MM | $QYYYY_MM_DD_HH_MM_SS | $QHHcon | $QHH_MMcon | $QHH_MM_SScon | $QHH_MMsans | $QHH_MM_SSsans )";
# weekord is for “week (date) or ordinal”; your choice whether the “or” is the disjunction or abbreviation of “ordinal”
my $weekord = "( $Qordinalsanstime | $Qordinalcontime | $Qweekdatesanstime | $Qweekdatecontime )";
# Date OR Time
my $dort = "( $supra | $normal | $weekord | $explicit )";

## The second part of an interval may be L-abbreviated when the first has the missing parts
my $abbrdort = "( $MM$q-$q$DD$decimal$q"
             . "| $MM$q-$q$DD$q" . "T" . "$q$HH$decimal$q$TZ"
             . "| $MM$q-$q$DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$decimal$q$TZ"
             . "| $MM$q-$q$DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ"
             . "| $DD$decimal$q"
             . "| $DD$q" . "T" . "$q$HH$decimal$q$TZ"
             . "| $DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$decimal$q$TZ"
             . "| $DD$q" . "T" . "$q$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ"
             . "| T" . "$HH$decimal$q$TZ"
             . "| T" . "$HH$q" . ":" . "$q$mm$decimal$q$TZ"
             . "| T" . "$HH$q" . ":" . "$q$mm$q" . ":" . "$q$ss$decimal$q$TZ )";

## intervals and recurring intervals
my $intervalA = "(R0*[1-9][0-9]*/)?($dort/($dort|$abbrdort))";
my $intervalB = "(R0*[1-9][0-9]*/)?($dort/$duration)";
my $intervalC = "(R0*[1-9][0-9]*/)?($duration/$dort)";

## --------------------------------------------------------------- ##
## Final assembly of regular expression.                           ##
## The simple expression would be                                  ##
## "$dort|$intervalA|$intervalB|$intervalC"                        ##
## but it is a *lot* shorter to factor out the $dort.              ##
## --------------------------------------------------------------- ##
my $wheniso = "$dort(/($dort|$abbrdort|$duration)?|$intervalC)?";

## ------------------------------------------------------- ##
## final creation of regular expression by removing spaces ##
## we add the anchors (if needed) later                    ##
## ------------------------------------------------------- ##
# DEBUGging can be performed by changing each occurence of
# $wheniso in the below 2 lines to some component thereof,
# e.g. $timesans
$wheniso = ( $wheniso =~ s, ,,gr );
my $regexp = "($wheniso)";

## ----------------------------- ##
## create namespace declarations ##
## ----------------------------- ##
my $namespaces = <<NSDECLS;
  xmlns:sb="http://bauman.zapto.org/ns-for-testing-8601"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
NSDECLS

## --------------------------------------------- ##
## create the "test suite" portion of the output ##
## --------------------------------------------- ##
# Should conform to the following not-quite-RELAX_NG description:
#   tests = sbtest+
#   sbtest = element sb:test {
#     ( attribute valid { pattern = "$wheniso" } | attribute invalid { pattern != "$wheniso" } ),
#     text
#     }
# Note that if, ostensibly for debugging, you change the value of
# $regex from $wheniso (sans spaces) to some other variable
# representing a component part of $wheniso, the @valid vs. @invalid
# distinction will be messed up a bit.
my $tests = <<TESTS;
  <sb:test   valid="12">century</sb:test>
  <sb:test   valid="-12">century BCE</sb:test>
  <sb:test   valid="1X">some century within a milenium, not saying which one</sb:test>
  <sb:test   valid="X5">a particular century within some milenium, not saying which one</sb:test>
  <sb:test invalid="~12">qual char should be on R</sb:test>
  <sb:test invalid="~-12">qual char should be on R</sb:test>
  <sb:test invalid="-~12">not even sure what this is supposed to meaan</sb:test>
  <sb:test   valid="12~">qualified century</sb:test>
  <sb:test   valid="-12~">qualified century BCE</sb:test>
  <sb:test   valid="1X~">qualified century … does this even make sense?</sb:test>
  <sb:test   valid="X1~">a particular century within some milenium … does this even make sense?</sb:test>
  <sb:test   valid="196">decade</sb:test>
  <sb:test   valid="19X">some decade within the given century</sb:test>
  <sb:test   valid="1XX">some century within the given milenium</sb:test>
  <sb:test invalid="?196">qual char should be on R</sb:test>
  <sb:test invalid="?19X">qual char should be on R</sb:test>
  <sb:test invalid="?1XX">qual char should be on R</sb:test>
  <sb:test   valid="196?">qualified decade</sb:test>
  <sb:test   valid="19X?">qualified year within a decade … does this make sense?</sb:test>
  <sb:test   valid="1XX?">qualified century within a milenium … does this make sense?</sb:test>
  <sb:test   valid="1962">year</sb:test>
  <sb:test   valid="-1962">year BCE</sb:test>
  <sb:test invalid="nineteenhundredsixtytwo">alphabetic representations not allowed</sb:test>
  <sb:test invalid="7AA">hexidecimal representations not allowed</sb:test>
  <sb:test invalid="-7AA">hexidecimal representations not allowed</sb:test>
  <sb:test invalid="%1962">qual char should be on R</sb:test>
  <sb:test invalid="%-1962">qual char should be on R</sb:test>
  <sb:test   valid="1962%">qualified year</sb:test>
  <sb:test   valid="-1962%">qualified year BCE</sb:test>
  <sb:test   valid="196X">a year within a decade</sb:test>
  <sb:test   valid="-196X">a year within a decade BCE</sb:test>
  <sb:test   valid="196X~">a qualified year within a decade</sb:test>
  <sb:test   valid="-196X~">a qualified year within a decade BCE</sb:test>
  <sb:test   valid="19X2">2nd year of a decade within century</sb:test>
  <sb:test   valid="-19X2">2nd year of a decade within century BCE</sb:test>
  <sb:test   valid="19X2~">qualified 2nd year of a decade within century</sb:test>
  <sb:test   valid="-19X2~">qualified 2nd year of a decade within century BCE</sb:test>
  <sb:test   valid="1X62">62nd year of a century within milenium</sb:test>
  <sb:test   valid="-1X62">62nd year of a century within milenium BCE</sb:test>
  <sb:test   valid="1X62~">qualified 62nd year of a century within milenium</sb:test>
  <sb:test   valid="-1X62~">qualified 62nd year of a century within milenium BCE</sb:test>
  <sb:test   valid="X962">962nd year within a milenium</sb:test>
  <sb:test   valid="-X962">962nd year within a milenium BCE</sb:test>
  <sb:test   valid="X962~">qualified 962nd year a within milenium</sb:test>
  <sb:test   valid="-X962~">qualified 962nd year a within milenium BCE</sb:test>

  <sb:test   valid="19XX">a year within century</sb:test>
  <sb:test   valid="-19XX">a year within century BCE</sb:test>
  <sb:test   valid="1X6X">unknown century &amp; year</sb:test>
  <sb:test   valid="-1X6X">unknown century &amp; year, BCE</sb:test>
  <sb:test   valid="X9X2">unknown milenium &amp; decade</sb:test>
  <sb:test   valid="-X9X2">unknown milenium &amp; decade, BCE</sb:test>
  <sb:test   valid="X96X">unknown milenium &amp; year</sb:test>
  <sb:test   valid="-X96X">unknown milenium &amp; year, BCE</sb:test>
  <sb:test   valid="1XXX">only know milenium digit</sb:test>
  <sb:test   valid="-1XXX">only know milenium digit, BCE</sb:test>
  <sb:test   valid="XXXX">what’s the point?</sb:test>
  <sb:test   valid="-XXXX">what’s the point?</sb:test>
  <sb:test   valid="1X6X?">unknown century &amp; year, qualified</sb:test>
  <sb:test   valid="-1X6X~">unknown century &amp; year, BCE, qualified</sb:test>
  <sb:test   valid="X9X2%">unknown milenium &amp; decade, qualified</sb:test>
  <sb:test invalid="?-X9X2">should be R qualified</sb:test>
  <sb:test invalid="~X96X">should be R qualified</sb:test>
  <sb:test invalid="%-X96X">should be R qualified</sb:test>
  <sb:test invalid="+1XXX">positives are indicated by lack of minus sign, plus sign not allowed</sb:test>
  <sb:test invalid="--1XXX">no double negatives</sb:test>
  <sb:test invalid="+-XXXX">leading plus not allowed</sb:test>
  <sb:test invalid="-+XXXX">plus sign not allowed</sb:test>
  <sb:test invalid="+12">leading plus not allowed</sb:test>
  <sb:test invalid="+~12">leading plus not allowed</sb:test>
  <sb:test invalid="+12~">leading plus not allowed</sb:test>
  <sb:test invalid="+1962">leading plus not allowed</sb:test>
  <sb:test invalid="+7AA">leading plus not allowed</sb:test>
  <sb:test invalid="+1962%">leading plus not allowed</sb:test>
  <sb:test invalid="+196X">leading plus not allowed</sb:test>
  <sb:test invalid="+196X~">leading plus not allowed</sb:test>
  <sb:test invalid="+19X2">leading plus not allowed</sb:test>
  <sb:test invalid="+19X2~">leading plus not allowed</sb:test>
  <sb:test invalid="+1X62">leading plus not allowed</sb:test>
  <sb:test invalid="+1X62~">leading plus not allowed</sb:test>
  <sb:test invalid="+X962">leading plus not allowed</sb:test>
  <sb:test invalid="+X962~">leading plus not allowed</sb:test>
  <sb:test   valid="1962-10">year month</sb:test>
  <sb:test   valid="-1962-10">year month BCE</sb:test>
  <sb:test   valid="1962-?10">year and qualified month</sb:test>
  <sb:test   valid="-1962-?10">year and qualified month BCE</sb:test>
  <sb:test   valid="1962?-10">month of a qualified year</sb:test>
  <sb:test   valid="-1962?-10">month of a qualified yeaf BCE</sb:test>
  <sb:test   valid="1962-10?">qualified year month</sb:test>
  <sb:test   valid="-1962-10?">qualified year month BCE</sb:test>
  <sb:test invalid="?1962-10">qualification char should not be on L</sb:test>
  <sb:test invalid="?-1962-10">qualification char should not be on L</sb:test>
  <sb:test invalid="-?1962-10">qualification char should not be on L</sb:test>
  <sb:test invalid="2019--01">missing month not allowed</sb:test>
  <sb:test invalid="2019--1">missing month, one digit day or month not allowed</sb:test>
  <sb:test invalid="2019-00">"00" not allowed as a month</sb:test>
  <sb:test   valid="2019-01">year-month</sb:test>
  <sb:test   valid="2019-02?">R qualified, year-month</sb:test>
  <sb:test   valid="2019-~03">year-L qualified month</sb:test>
  <sb:test   valid="2019%-04">R qualified year-month</sb:test>
  <sb:test   valid="2019~-?05">R qualified year - L qualified month</sb:test>
  <sb:test   valid="2019%-%06">Should be “2019-06%”, but we have no test for that optimization</sb:test>
  <sb:test   valid="2019-0X">year-month, missing digit</sb:test>
  <sb:test   valid="2019-X8">year-month, missing digit</sb:test>
  <sb:test   valid="201X-09">year-month, missing digit</sb:test>
  <sb:test   valid="20X9-10">year-month, missing digit</sb:test>
  <sb:test   valid="2X19-11">year-month, missing digit</sb:test>
  <sb:test   valid="X019-12">year-month, missing digit</sb:test>
  <sb:test   valid="2019-XX">year-month, missing 2 digits</sb:test>
  <sb:test   valid="201X-X2?">year-month, missing 2 digits, R qualified</sb:test>
  <sb:test   valid="20XX-~03">year missing 2 digits - L qualified month</sb:test>
  <sb:test   valid="2XX9%-04">year missing 2 digits R qualified - month</sb:test>
  <sb:test   valid="XX19~-?05">year missing 2 digits R qualified - L qualified month</sb:test>
  <sb:test   valid="201X%-%0X">Should be “201X-0X%”, but we have no test for that optimization</sb:test>
  <sb:test   valid="20X9-X7">year-month, each missing a digit</sb:test>
  <sb:test   valid="2X1X-08">year missign 2 digits-month</sb:test>
  <sb:test   valid="X0X9-09">year missign 2 digits-month</sb:test>
  <sb:test   valid="20X9-1X">year-month, each missing a digit</sb:test>
  <sb:test   valid="2X19-X1">year-month, each missing a digit</sb:test>
  <sb:test   valid="X01X-12">year missing 2 digits-month</sb:test>
  <!-- -->
  <sb:test invalid="2019-13">there are only 12 months</sb:test>
  <sb:test invalid="2019-14?">even when you are unsure about it, there are only 12 months</sb:test>
  <sb:test invalid="2019-?15">even when you are unsure about it, there are only 12 months</sb:test>
  <sb:test invalid="2019?-16">even if you are unsure about the year, there are only 12 months</sb:test>
  <sb:test invalid="?2019-17">even if you are unsure about the year, there are only 12 months</sb:test>
  <sb:test invalid="201X-18">even if you are missing a digit, there are only 12 months</sb:test>
  <sb:test invalid="20XX-19">even if you are missing 2 digits, there are only 12 months</sb:test>
  <sb:test invalid="2XXX-20">even if you are missing 3 digits, there are only 12 months</sb:test>
  <sb:test   valid="2019-21">Spring (independent of location)</sb:test>        
  <sb:test   valid="2019-22">Summer (independent of location)</sb:test>        
  <sb:test   valid="2019-23">Autumn (independent of location)</sb:test>        
  <sb:test   valid="2019-24">Winter (independent of location)</sb:test>        
  <sb:test   valid="2019-25">Spring — Northern Hemisphere</sb:test>            
  <sb:test   valid="2019-26">Summer — Northern Hemisphere</sb:test>            
  <sb:test   valid="2019-27">Autumn — Northern Hemisphere</sb:test>            
  <sb:test   valid="2019-28">Winter — Northern Hemisphere</sb:test>            
  <sb:test   valid="2019-29">Spring — Southern Hemisphere</sb:test>            
  <sb:test   valid="2019-30">Summer — Southern Hemisphere</sb:test>            
  <sb:test   valid="2019-31">Autumn — Southern Hemisphere</sb:test>            
  <sb:test   valid="2019-32">Winter — Southern Hemisphere</sb:test>            
  <sb:test   valid="2019-33">Quarter 1 (3 months in duration)</sb:test>        
  <sb:test   valid="2019-34">Quarter 2 (3 months in duration)</sb:test>        
  <sb:test   valid="2019-35">Quarter 3 (3 months in duration)</sb:test>        
  <sb:test   valid="2019-36">Quarter 4 (3 months in duration)</sb:test>        
  <sb:test   valid="2019-37">Quadrimester 1 (4 months in duration)</sb:test>   
  <sb:test   valid="2019-38">Quadrimester 2 (4 months in duration)</sb:test>   
  <sb:test   valid="2019-39">Quadrimester 3 (4 months in duration)</sb:test>   
  <sb:test   valid="2019-40">Semestral 1 (6 months in duration)</sb:test>      
  <sb:test   valid="2019-41">Semestral 2 (6 months in duration)</sb:test>
  <sb:test invalid="2019-42">42 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-43">43 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-44">44 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-45">45 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-46">46 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-47">47 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-48">48 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-49">49 is neither a valid month nor a valid sub-year grouping</sb:test>
  <sb:test invalid="2019-50">50 is neither a valid month nor a valid sub-year grouping</sb:test>

  <sb:test   valid="1988-W44-6"></sb:test>
  <sb:test   valid="1987-W43"></sb:test>
  <sb:test   valid="-0001-W02"></sb:test>
  <sb:test invalid="5432-W01-0">0 is not a valid weekday</sb:test>
  <sb:test invalid="6543-W02-8">8 is not a valid weekday</sb:test>
  <sb:test invalid="7654-W03-01">01 is not a valid weekday</sb:test>
  <sb:test invalid="8765-W04-08">08 is not a valid weekday</sb:test>
  <sb:test invalid="9876-W05-787">787 is not a valid weekday</sb:test>
  <sb:test invalid="0987-W05-4Z">time shift not valid w/o a time</sb:test>
  <sb:test invalid="0987-W05-4+03">time shift not valid w/o a time</sb:test>
  <sb:test invalid="0987-W05-4-03">time shift not valid w/o a time</sb:test>
  <sb:test invalid="1098-W76">76 is not a valid week number</sb:test>
  <sb:test invalid="1098-W76-5">76 is not a valid week number</sb:test>
  <sb:test invalid="2109-W8-7">8 is not a valid week number</sb:test>
  <sb:test   valid="1234-W05-6T12"></sb:test>
  <sb:test   valid="1234-W05-6T12:34"></sb:test>
  <sb:test   valid="1234-W05-6T12:34:56"></sb:test>
  <sb:test   valid="1234-W05-6T12+08"></sb:test>
  <sb:test   valid="1234-W05-6T12:34+09"></sb:test>
  <sb:test   valid="1234-W05-6T12:34:56+10"></sb:test>
  <sb:test   valid="1234-W05-6T12-08"></sb:test>
  <sb:test   valid="1234-W05-6T12:34-09"></sb:test>
  <sb:test   valid="1234-W05-6T12:34:56-10"></sb:test>
  <sb:test   valid="1234-W05-6T12-08:00"></sb:test>
  <sb:test   valid="1234-W05-6T12:34-09:30"></sb:test>
  <sb:test   valid="1234-W05-6T12:34:56-10:45"></sb:test>
  <sb:test   valid="1234-W05-6T12Z"></sb:test>
  <sb:test invalid="1234-W05-6T12+8">TZ should have 2 digits</sb:test>
  <sb:test invalid="1234-W05-6T12:34+090">TZ should have 2 digits</sb:test>
  <sb:test invalid="1234-W05-6T12:34:56+71">TZ hours must be ≤ 23</sb:test>
  <sb:test invalid="1234-W05-6T12-A">single letter TZ codes no longer used, except ‘Z’</sb:test>
  <sb:test invalid="1234-W05-6T12:34-09.2">no decimals in TZs</sb:test>
  <sb:test invalid="1234-W05-6T12:34:56-10,3">no decimals in TZs</sb:test>
  <sb:test invalid="1234-W05-6T12-08:00:05">no seconds in TZs</sb:test>
  <sb:test invalid="1234-W05-6T12:34-09:30:00.0">no seconds in TZs, even with decimal</sb:test>
  <sb:test invalid="1234-W05-6T12B">± separator required, and ‘B’ not valid</sb:test>
  <!-- ... -->
  <sb:test   valid="1962-007">It‘s an ordinal day in this neighbor hood,</sb:test> <!-- Dr. No -->
  <sb:test   valid="-1022-364.90210"></sb:test>
  <sb:test   valid="1963-007T13"></sb:test> <!-- From Russia with Love -->
  <sb:test   valid="1964-007T13.987"></sb:test> <!-- Goldfinger -->
  <sb:test   valid="1965-007T23:54"></sb:test> <!-- Thunderball -->
  <sb:test   valid="1967-007T23:54.45608713"></sb:test> <!-- You Only Live Twice -->
  <sb:test   valid="1969-007T01:23:45"></sb:test> <!-- On Her Majesty’s Secret Service -->
  <sb:test   valid="1971-007T01:23:45.6789"></sb:test> <!-- Diamonds Are Forever -->
  <sb:test invalid="0123-456">day must be ≤ 366</sb:test>
  <sb:test invalid="1828-0123">day must be 3 digits, not 4 (2 would be MM)</sb:test>
  <sb:test invalid="1767-00123">day must be 3 digits, not 5 (2 would be MM)</sb:test>
  <sb:test invalid="1234-123T123">HH must be 2 digits, not 3</sb:test>
  <sb:test invalid="1234-123T123456">HH must be 2 digits, not 6</sb:test>
  <sb:test invalid="1234-123T12:99">MM must ≤ 59</sb:test>
  <sb:test invalid="1234-123T12:34:99">SS must ≤ 59</sb:test>
  <sb:test invalid="1234-123T12:99.17">MM must ≤ 59, even with extra precision</sb:test>
  <sb:test invalid="1234-123T12:34:99.17">SS must ≤ 59, even with extra precision</sb:test>
  <!-- ... -->
  <sb:test   valid="2025-W07-6"></sb:test> <!-- Valentine’s Day this year -->
  <sb:test   valid="2025-W07-6?"></sb:test>
  <sb:test   valid="2025-W07~-6"></sb:test>
  <sb:test   valid="2025%-W07-6"></sb:test>
  <sb:test   valid="2025-W07-?6"></sb:test>
  <sb:test   valid="2025-~W07-6"></sb:test>
  <sb:test invalid="%2025-W07-6">should be 2025%-W07-6</sb:test>
  <sb:test   valid="2025?-~W07-6"></sb:test>
  <sb:test   valid="2025-?W07-~6"></sb:test>
  <sb:test   valid="2025?-W07-~6"></sb:test>
  <!-- ... -->
  <sb:test   valid="1797Y"></sb:test>
  <sb:test   valid="1797Y3M"></sb:test>
  <sb:test   valid="1797Y03M"></sb:test>
  <sb:test   valid="1797Y3M4D"></sb:test>
  <sb:test   valid="1797Y3M04D"></sb:test>
  <sb:test   valid="1962Y10M20DT1H"></sb:test>
  <sb:test   valid="1952Y7M26DT20H25M"></sb:test>
  <sb:test   valid="1952Y07M26DT20H25M"></sb:test>
  <sb:test   valid="1970Y4M13DT22H8M19S"></sb:test>
  <sb:test   valid="1970Y04M13DT22H08M19S"></sb:test>
  <sb:test   valid="2035Y1M2DT8M19S"></sb:test>
  <sb:test   valid="-17Y"></sb:test>
  <sb:test   valid="-17Y6M"></sb:test>
  <sb:test   valid="-17Y06M"></sb:test>
  <!-- 1970-04-13T22:08:19-05:00 = “Houston, we’ve had a problem” -->
  <!-- 1970-04-17T13:07:00-05:00 = splashdown -->
  <!-- 1961-07-04T04:15 local time = pressure in K-19’s nuclear reactor starboard cooling system drops to zero -->
  <sb:test   valid="1961-07-04T04:15/T17.2">from incident to 17.2 hrs later</sb:test>
  <sb:test   valid="1961-07-04T04:15/T17:12">from incident to 17.2 hrs later</sb:test>
  <sb:test   valid="1961-07-04T04:15/T17:12.04">from incident to 17.2 hrs + 4 s later</sb:test>
  <sb:test   valid="1961-07-04T04:15/05">form incident to sometime on the 5th</sb:test>
  <sb:test   valid="1961-07-04T04:15/05T04:15">for 1 day post-incident</sb:test>
  <sb:test   valid="1961-07-04T04:15/07-05T04:15">same</sb:test>
  <sb:test   valid="1961-07-04T04:15/1961-07-05T04:15">same</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08:57-05:00">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08:57">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08.95-05:00">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08.95">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08:~57-05:00">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:08:~57">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:~08.95-05:00">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/T22:~08.95">~ until “pretty large bang”</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/1970-04-17T13:07:00-05:00">until splashdown</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/04-17T13:07:00">until splashdown</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/17T13:07:00">until splashdown</sb:test>
  <sb:test   valid="1970-04-13T22:08:19-05:00/17T13:07.0">until splashdown</sb:test>
  <sb:test invalid="1961-07-04T04:15/T1.2">one-digit hour not allowed</sb:test>
  <sb:test invalid="1961-07-04T4:15/T17:12">one-digit hour not allowed</sb:test>
  <sb:test invalid="1961-70-04T04:15/T17:12.04">month > 12 not allowed</sb:test>
  <sb:test invalid="07-04T04:15/05">yearless date (allowed?)</sb:test>
  <sb:test invalid="1961-07-04T04:15/05T04:15+72">|TZ| > 12 not OK</sb:test>
  <sb:test invalid="1961-07-04T04:15-93/07-05T04:15">|TZ| > 12 not OK</sb:test>
  <sb:test invalid="1961-07-04T04.4:15/1961-07-05T04:15">decimal min + sec not allowed</sb:test>
  <sb:test invalid="1970-04-1T22:08:19-05:00/T22:08:57-05:00">one-digit day not allowed</sb:test>
  <sb:test invalid="1970-04-137T22:08:19-05:00/T22:08:57">three-digit day not allowed</sb:test>
  <sb:test invalid="1970-4-13T22:08:19-05:00/T22:08.95-05:00">one-digit month not allowed</sb:test>
  <sb:test invalid="1970-045-13T22:08:19-05:00/T22:08.95">three-digit month not allowed</sb:test>
  <sb:test invalid="197-04-13T22:08:19-05:00/T22:08:~57-05:00">three-digit year not allowed</sb:test>
  <sb:test invalid="01970-04-13T22:08:19-05:00/T22:08:~57">5-digit year not allowed</sb:test>
  <sb:test invalid="1970-04-13T22:08:19-05:00/T22:08.95-05:00?">qualification of TZ not allowed</sb:test>
  <sb:test invalid="1970-04-13T22:08:19-05:00/T22:08.%95">qualification of decimal not allowed</sb:test>
  <sb:test invalid="1970-04T22:08:19-05:00/1970-04T13:07:00-05:00">missing days should not have times</sb:test>
  <sb:test invalid="1970-%-04-13T22:08:19-05:00/04-17T13:07:00">extraneous hyphen</sb:test>
  <sb:test invalid="1970-04-13T22:08:19-05:00/17T13:07,,00">double decimal separator not allowed</sb:test>
  <sb:test   valid="2022/2025"></sb:test>
  <sb:test   valid="2022-12/2025-08"></sb:test>
  <sb:test   valid="2022-12-25/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25T16/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25T16:05/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15-05/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15-05:00/2025-08-10"></sb:test>
  <sb:test   valid="2022-12/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25/2025-08-10T00"></sb:test>
  <sb:test   valid="2022-12-25T16/2025-08-10T00:54"></sb:test>
  <sb:test   valid="2022-12-25T16:05/2025-08-10T00:54:16"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15/2025-08-10T00:54:16.8705"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15-05/2025-08-10T00:54:16-05"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15-05/2025-08-10T00:54:16-05:00"></sb:test>
  <sb:test   valid="2022-12-25T16:05:15Z/2025-08-10T00:54:16Z"></sb:test>
  <sb:test   valid="2022-12-25/P959D"></sb:test>
  <sb:test   valid="P2.625598904Y/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25/P2.625598904Y"></sb:test>
  <sb:test   valid="P959D/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25/P959D"></sb:test>
  <sb:test   valid="P2Y7M16D/2025-08-10"></sb:test>
  <sb:test   valid="2022-12-25/P2Y7M16D"></sb:test>
  <sb:test   valid="P959D/2025-08-10"></sb:test>
  <sb:test   valid="P959D/2025-08-10T00:56:05-0400"></sb:test>
  <sb:test   valid="P2Y7M16D/2025-08-10"></sb:test>
  <sb:test   valid="P2Y7M16D/2025-08-10T00:56:05-0400"></sb:test>
TESTS

## ----------------------------- ##
## output what we've created ... ##
## ----------------------------- ##
print STDERR "$regexp\n";

## ----------------- ##
## main output, XSLT ##
## ----------------- ##
my $xslt = <<EXSLT;
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
$namespaces
  version="3.0">

  <!-- This pgm written $now by $0 -->

  <xsl:output method="text"/>

  <xsl:variable name="apos" select='"&apos;"'/> <!-- not used at the moment -->
  <xsl:variable name="quot" select="'&quot;'"/> <!-- not used at the moment -->
  <xsl:variable name="when-iso_regex" as="xs:string" select="'$regexp'"/>
  <xsl:variable name="anchored_when-iso_regex" select="'^'||\$when-iso_regex||'\$'"/>
    
  <xsl:template match="/">
    <xsl:text>\&#x0A;</xsl:text>
    <xsl:apply-templates select="//*[\@invalid|\@valid]"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:apply-templates select="\@invalid|\@valid"/>
  </xsl:template>

  <xsl:template match="\@invalid|\@valid">
    <xsl:variable name="valid" select="matches( ., \$anchored_when-iso_regex, 'x')" as="xs:boolean"/>
    <xsl:value-of select="local-name(.)
                        ||' of “'
                        ||.
                        ||'” is\&#x09;\&#x09;'"/>
    <xsl:if test="not( \$valid )">NOT </xsl:if>
    <xsl:value-of select="'valid.'"/>
    <xsl:if test="name(.) eq 'valid'  and  not( \$valid )
                  or
                  name(.) eq 'invalid'  and  \$valid">
      <xsl:value-of select="'  EGADS! a mis-match. :-('"/>
    </xsl:if>
    <xsl:value-of select="'\&#x0A;'"/> 
  </xsl:template>

$tests
    
</xsl:stylesheet>
EXSLT

## -------------------- ##
## main RELAX NG output ##
## -------------------- ##
my $relax = <<ERELAX;
<?xml version="1.0" encoding="UTF-8"?>
<grammar 
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
$namespaces
  datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
  <!-- This grammar written $now by $0 -->  
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
              <name>valid</name>
              <name>invalid</name>
              <name>when-iso</name>
            </except>
          </anyName>
        </attribute>
      </zeroOrMore>
      <optional>
        <attribute name="valid">
          <data type="string">
            <param name="pattern">$regexp</param>
          </data>
        </attribute>
      </optional>
      <optional>
        <attribute name="invalid">
          <data type="string">
            <param name="pattern">$regexp</param>
          </data>
        </attribute>
      </optional>
      <optional>
        <attribute name="when-iso">
          <data type="string">
            <param name="pattern">$regexp</param>
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
$tests    
</grammar>
ERELAX

## ----------- ##
## main output ##
## ----------- ##
print STDOUT $relax;            # use either "$relax" or "$xslt"
exit 0;


# -----------------------------------------------------
# Notes
# -----
# -----------------------------------------------------


# -----------------------------------------------------
# Update Hx
# ------ --
# $Log:$
#
# -----------------------------------------------------
# Copyright 2025 Syd Bauman and Northeastern University Digital
# Scholarship Group. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details. You should have received a
# copy of the GNU General Public License along with this program; if
# not, write to the
#        Free Software Foundation, Inc.
#        675 Mass Ave
#        Cambridge, MA  02139
#        USA
#        gnu@prep.ai.mit.edu
#
# Syd Bauman, senior XML textbase programmer/analyst
# Northeastern University Digital Scholarship Group / Women Writers Project
# SL 371
# 360 Huntington Avenue
# Boston, MA  02115-5005
# s.bauman@northeastern.edu
#
