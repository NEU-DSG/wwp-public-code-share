<!-- Last updated 2019-03-15 -->
# Setting up transformations

Most of our stylesheets use XSLT version 2.0, which can only be processed with Saxon HE/PE/EE. XSLT 1.0 and 3.0 can also be processed with Saxon. With a little set-up, XSL transformations can also be run in XML databases such as eXist-DB or BaseX.

Our XSLT stylesheets are very likely to include optional parameters. Check the READMEs for parameter names and any available options. Parameter options should also be explained at the top of each XSLT file, in comments close to any `<xsl:param>`s.

<!-- ## Transforming with oXygen

-->

## Transforming through the command line

To use XSLT 2.0+ on the command line, you will need a copy of the Saxon HE processor. Download the latest ZIP file from [Sourceforge](https://sourceforge.net/projects/saxon/files/Saxon-HE/) and decompress it somewhere you can easily find it. Inside the unzipped folder is a file called something like “saxon9he.jar.” This JAR file is your Saxon processor.

Before you continue, navigate to the JAR file in your command line interface and make sure that you can execute it.

This command will process an input XML document using an XSLT stylesheet: 

    java -jar "/PATH/TO/saxon9he.jar" -expand:off -s:"/PATH/TO/INPUTFILE.xml" -xsl:"/PATH/TO/FILENAME.xslt" -o:"/PATH/TO/OUTPUTFILE"

If you need to add/modify any parameters, append your choices to the command, using the format `NAME=VALUE`.

See the Saxonica documentation for other options: <http://www.saxonica.com/documentation/#!using-xsl/commandline>.

## Transforming with eXist-DB

eXist-DB comes bundled with Saxon HE. As long as you have your XSLT and input document loaded into the database, you can run transformations in eXist with a simple XQuery:

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


