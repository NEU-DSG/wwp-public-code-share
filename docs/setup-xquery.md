<!-- Last updated 2017-07-03 -->
# Setting up queries

We generally use XQuery version 3.0, which can be processed with Saxon HE/PE/EE, eXist-DB, and BaseX.

<h2 id="oxygen">Querying with oXygen</h2>

If you haven't already done so, make sure that oXygen knows to allow XQuery version 3.0. Go to oXygen's Options menu and select "Preferences". Type "XQuery" into the search bar at the top left. Select XML > XSLT-FO-XQuery > XQuery > Saxon-HE/PE/EE. Make sure "Enable XQuery 3.0 support" is checked, and hit "OK".

### The general XQuery transformation scenario



1. Click on the button that has a wrench above a tiny play symbol, or use the shortcut <kbd><kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd></kbd>. (In Windows: <kbd><kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd></kbd>)
2. Select "New" to create a new scenario. The default XML and XQuery URLs are fine; you can ignore them. 
3. Name the transformation "General XQuery with Saxon" or something similar.
4. Select "Global Options" for storage, so that you won't have to re-make this transformation scenario for multiple projects.
5. Click the drop-down menu for "Transformer" and select Saxon HE (PE or EE are fine too). 
6. Click the "Output" button toward the top. 
7. Un-check "Present as sequence" and you'll have access to more fields. 
8. Select "Open in Editor" and make sure none of the options for "results view" are checked. 
9. Hit "OK". 
10. Select your new scenario, then click "Apply associated".
11. If all goes well, your results will show up as text in a new, untitled document.

If you still don't get any results, don't worry! Make sure you're using the right namespace in your XQuery. WWO uses TEI-esque elements in a special namespace. You can reference them using the prefix "wwp:" (Reception and Exhibits use regular TEI elements.)

Now that your preferences and scenario are configured, you can re-run your counting robot by hitting the big play button next to the wrench, or with <kbd><kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd></kbd>. (In Windows: <kbd><kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd></kbd>)

<h2 id="cli">Querying with the command line</h2>

To use an XQuery on the command line, you will need a copy of the Saxon HE processor. Download the latest ZIP file from [Sourceforge](https://sourceforge.net/projects/saxon/files/Saxon-HE/) and decompress it somewhere you can easily find it. Inside the unzipped folder is a file called something like "saxon9he.jar". This JAR file is your Saxon processor.

Before you continue, navigate to the JAR file in your command line interface and make sure that you can execute it.

This command will process an XQuery: 

    java -classpath "/PATH/TO/saxon9he.jar" net.sf.saxon.Query -q:"/PATH/TO/FILENAME.xq" -o:"/PATH/TO/OUTPUTFILE"

If you need to add/modify any parameters, append your choices to the command, using the format `NAME=VALUE`.

See the Saxonica documentation for other options. http://www.saxonica.com/documentation/#!using-xquery/commandline

<h2 id="exist">Querying with eXist-DB</h2>



<!--<h2 id="basex">Querying with BaseX</h2>-->

