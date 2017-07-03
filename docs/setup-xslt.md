<!-- Last updated 2017-07-03 -->
# Setting up transformations

We generally use XSLT version 2.0, which can only be processed with Saxon HE/PE/EE.

Our XSLT stylesheets are very likely to include optional parameters. Check the READMEs for parameter names and any available options. Parameter options should also be explained at the top of each XSLT file, in comments close to any `<xsl:param>`s.

## Transforming with oXygen



## Transforming through the command line



## Transforming with eXist-DB

eXist comes bundled with Saxon HE. As long as you have your XSLT and input document loaded into the database, you can run transformations in eXist with a simple XQuery:

    xquery version "1.0";
    
    (: namespace declarations :)
    import module namespace transform=
      "http://exist-db.org/xquery/transform";
    
    let $xslt       := doc('/db/PATH/TO/FILENAME.xslt')
    let $inputFile  := doc('/db/PATH/TO/FILENAME.xq')
    let $parameters := 
      <parameters>
        <!-- <param name="NAME" value="VALUE"/> -->
      </parameters>
    return
      transform:transform($inputFile, $xslt, $parameters)

For each XSLT parameter you wish to modify, copy the commented-out `<param>` element and paste it inside `<parameters>`. Replace `NAME` with the parameter name, and `VALUE` with your changed option.

See the [XQuery documentation](setup-xquery.md#exist) for details on running this XQuery and others.

<!--## Transforming with BaseX-->


