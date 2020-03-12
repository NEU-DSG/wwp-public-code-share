<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process">

  <!-- 
       co-terminus_checker.sch    copyright and licensing at bottom of file
       A Schematron schema that issues a warning for every element
       that is co-terminus with its parent, i.e. both starts and ends
       in the same place as its parent.
       This schema reports on three different conditions; note that
       comments and processing instructions are summarily ignored.
       1) Completely co-terminus elements, e.g. "<a><b>duck</b></a>".
       2) Almost completely co-terminus elements, i.e. those in which
          there is nothing in the parent except the one child and
          whitespace, e.g. "<a> <?xmp comment or PI here ?> <b>duck</b></a>".
       3) Nearly co-terminus elements: those in which the one child
          has the same characters as its parent except the parent has
          some punctuation marks after the child, e.g. "<a><b>duck</b>:</a>".
       Note that it does *not* report cases where there is no text
       content of the child element, e.g. "<a><b/></a>".
       Written 2018-11-27 by Syd Bauman
       Updated 2020-03-11/12 by Syd Bauman: added comments, use
       variables for the space-normalized string value of the parent
       element an the list of punction strings used in the test for
       (3).
  -->
  
  <sch:pattern id="coterminal">
    <!-- The string value of my parent, normalized: -->
    <sch:let name="parentString" value="normalize-space( string-join( string(..), '') )"/>
    <!-- List of punctuation character strings which, if one is the
         only difference between me and my parent, we are "nearly co-terminus": -->
    <sch:let name="puncs"
	     value="('.',
		     ':',
		     ',',
		     '―',
		     '――',
		     '—',
		     ',.',
		     '.,',
		     ' , .',
		     ' . ,'
		     )"/>
    <!-- The @context of the rules contain all of the logic so that
         only one of them will be fired. -->
    <sch:rule context="*[not(*)][normalize-space(.) ne '']
                        [string(.) eq string(..)]">
      <sch:report test="true()">This <sch:name/> element is completely co-terminus with its parent <sch:value-of select="local-name(..)"/>.</sch:report>
    </sch:rule>
    <sch:rule context="*[not(*)][normalize-space(.) ne '']
                        [normalize-space( . ) eq normalize-space( .. )]">
      <sch:report test="true()">This <sch:name/> element is almost completely co-terminus with its parent <sch:value-of select="local-name(..)"/>.</sch:report>
    </sch:rule>
    <sch:rule context="*[not(*)][normalize-space(.) ne '']
                        [normalize-space( substring-before( $parentString, normalize-space(.) ) ) eq ''
                         and
                         substring-after( $parentString, normalize-space(.) ) = $puncs ]">
      <sch:report test="true()">This <sch:name/> element is nearly co-terminus with its parent <sch:value-of select="local-name(..)"/>.</sch:report>
    </sch:rule>
  </sch:pattern>
  
</sch:schema>

<!--
    © 2018 Syd Bauman and the Women Writers Project; available under
    the terms of the MIT License:

       Permission is hereby granted, free of charge, to any person
       obtaining a copy of this software and associated documentation
       files (the “Software”), to deal in the Software without
       restriction, including without limitation the rights to use,
       copy, modify, merge, publish, distribute, sublicense, or sell
       copies of the Software, and to permit persons to whom the
       Software is furnished to do so, subject to the following
       conditions:

       The above copyright notice and this permission notice shall be
       included in all copies or substantial portions of the Software.

       THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
       OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
       HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
       WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
       FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
       OTHER DEALINGS IN THE SOFTWARE.
-->

