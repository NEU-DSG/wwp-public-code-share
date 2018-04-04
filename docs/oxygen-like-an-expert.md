# oXygen like an Expert

Notes for WWP Practicum, 2017-11-08.

## About oXygen

* Proprietary product
  * Library pays for your license to use it
  * Generously licensed: if you buy a license (~100 USD for an academic), you can use it on your Mac laptop, your GNU/Linux machine at home, and your Windows machine at work
  * Company that makes it ([SyncRO Soft](https://www.oxygenxml.com/)) is **very** supportive of digital humanities in general, and TEI in particular
  * They are also very responsive and helpful
* An XML “IDE” (integrated development environment)
  * That means it does lots of stuff we don’t care about
* Written in Java
  * That means lots of things it does it does by calling some Java library, over which SyncRO Soft has no control. So, e.g., (last Syd heard) R-to-L writing in oXygen is kinda lame, but SyncRO Soft is just waiting for the Java people to fix it
* Very powerful
  * All sorts of goodies built-in (that’s why you’re here :-)
  * Under some conditions can be resource intensive
* Somewhat extensible

## Projects

* Everything you do in oXygen is within a project.
* Projects allow you to compartmentalize different kinds of work (wwp/personal, encoding/querying).
* oXygen always starts you off in the "sample" project, which includes examples of the kinds of things you can do in oXygen.
* Projects consist of a "xpr" file saved to your computer, which indexes:
  * your project-specific preferences,
  * the paths to the files and folders you've added to the project, and
  * the working sets and project-specific transformation scenarios you've defined.
* Creating a project:
  * oXygen requests (1) the directory in which to save the project, and (2) the name of the project file.
  * The directory will serve as the home base for the project.
  * The name of the project file will be the name oXygen uses to refer to the project itself.
  * You can use the "Project View" to add resources to your project, such as individual files and folders.
* Projects also allow you to create "logical folders" of files. The files will still be saved in the same place, but oXygen will create shortcuts to the files you choose to group together. This is especially useful for querying or exploring.
* Projects are sharable! ...as long as everyone has access to the directory that the project is based in, and all other resources within the project. But still a great way to share transformation scenarios and settings so that everyone is on the same page.


## Powering up oXygen

### Frameworks

* a **framework** is a package to standardize oXygen resources for use with specific XML vocabularies or file types
  * sort of like projects but allowing people to create their own workspaces
  * can provide genre-specific transformations, validation, quick fixes
* like projects, can be created and shared
* to create/manage a framework:
  * Options > Preferences > Document Type Association
  * lots and lots of configuration options: schemas, transformation scenarios, code templates, etc.
* to share a framework, you have three options:
  * make the framework a part of your project preferences;
  * give out a copy of the directory where the framework is kept, and have others save it in the OXYGEN-APPLICATION/frameworks directory;
  * make the framework an add-on.

[https://www.oxygenxml.com/doc/versions/19.1/ug-editor/topics/author-document-type-sharing.html]

3 TEI frameworks available:

* built-in to oXygen (so current as of the release date)
* TEI provides:
  * “released” uses the currently released Guidelines
  * “bleeding edge” uses the development branch (often broken)

### Add-ons

* AKA "plugins" OR frameworks
  * a **plugin** is "a component that adds specific features to an existing application" (from the oXygen glossary [https://www.oxygenxml.com/doc/versions/19.1/ug-editor/glossary/plugin.html])
    * usually general-purpose and affect all XML files you might be editing
  * frameworks can be installed as add-ons
    * so long as you have a server that can host add-ons, you only have to distribute your update site URL, and oXygen will download and store all the resources when the add-on is installed
    * allows users to easily obtain updates
* installing add-ons
  * Help > Install new addons
  * select/add an update site to see all the add-ons available there
    * TEI release site: [http://www.tei-c.org/release/oxygen/updateSite.oxygen]
  * then choose an add-on to install
* managing add-ons
  * Help > Manage add-ons
    * select an add-on and you can check for updates or uninstall
  * Help > Check for add-ons updates
    * shortcut for finding updates

## Transformations/Querying

To run an XSL transformation or an XQuery in oXygen, you can define a "transformation scenario". These can be saved to the currently-open project or to your global settings.

### Transformation scenario types

* XSLT transformation
  * the "default" type if your current editor is an XSLT file
  * you provide a filepath to the XML to be transformed
    * if you have the file open, use the down caret to select it
    * you can also use the folder icon to select the file
  * oXygen provides a shortcut to the current file in "XSL URL"
* XML transformation with XSLT
  * one of two "default" types if your current editor is an XML file
    * useful when doing transformations _en masse_
  * oXygen provides a shortcut to the current file in "XML URL"
  * you provide a filepath to the XSLT to use in the transformation
* XQuery transformation
  * the "default" type if your current editor is an XQuery
  * you provide a filepath to the XML to be transformed, if there is one
    * you only need to provide an XML file if the XQuery contains `declare context item external;` somewhere at the top
  * oXygen provides a shortcut to the current file in "XQuery URL"
* XML transformation with XQUERY
  * one of two "default" types if your current editor is an XML file
    * useful when doing transformations _en masse_
  * oXygen provides a shortcut to the current file in "XML URL"
  * you provide a filepath to the XQuery to use in the transformation
    * the XQuery should have `declare context item external;` somewhere at the top, or it won't do anything with the input XML file

### XSLT/XQuery Processors

* Saxon HE ("Home Edition")
  * free, open-source version which gets the most stable updates (as opposed to the most cutting edge)
  * provides "the basic level of conformance defined by W3C"
  * perfectly serviceable for most XSLT and XQuery scenarios
* Saxon PE ("Professional Edition")
  * adds optional features from spec
  * adds extensions and extensibility
* Saxon EE ("Enterprise Edition")
  * Saxon at its most powerful
  * full conformance with specs
  * adds streaming (if turned on, makes it easier to process large documents)
  * adds XQuery updates
  * adds optimization of queries
* Saxon6.5.5
  * a version of Saxon from November 2005
  * the last Saxon release to fully implement the XSLT 1.0 spec (the others are backwards-compatible with XSLT 1.0, but use a 2.0/3.0 mindset)
  * **you should never have to use this**
* Xalan
  * implements XSLT 1.0
  * **you should never have to use this**

oXygen gives you access to all three current versions of Saxon (plus 6.5.5). Generally it doesn't matter which of the three you pick, though it's worth remembering that you will always be able to access HE even if you don't have access to oXygen. If you have to pick one to remember, make it HE.

If you connect oXygen to an XML database like eXist or BaseX, you also have the option of using their XQuery validators and processors.
