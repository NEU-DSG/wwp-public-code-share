Below are instructions for loading in and training models using the [R walkthroughs](https://github.com/NEU-DSG/wwp-public-code-share/releases/tag/WordVectors/2021-07-02) . There are detailed instructions in the walkthroughs—the instructions below provide an outline of key steps.

# 0. About the Commented Code Files

We have created a set of commented code files that provide both the actual R code you need to do things like train and query models, and also detailed comments so that you can understand what the code is doing and make modifications on your own. These files were originally designed for use in the "code walkthrough" portions of the Word Vectors for the Thoughtful Humanist" series of institutes, but some of them are also useful on their own.

## During the Institutes

During the WWP's institutes, we use six code walkthroughs. Because these institutes are taught using RStudio Server (rather than by installing RStudio on the participants' own computers), some of these walkthroughs include components that are specific to the RStudio Server environment, as noted below.

**Introduction to R and RStudio:** This walkthrough gives an introduction to the basic concepts of the R programming language and the RStudio programming environment. It can be used in both the RStudio Server environment and on your own computer.

**Word Vectors Starter Queries:** This walkthrough provides a framework for querying a model that has already been trained (it does not include the code for the model training process). It assumes that you are working in the RStudio Server environment, so it does not include code for loading in external code packages, since those are provided within the Server environment. We provide this walkthrough to support a session on querying early in the institute, before we've covered the model training process.

**Word Vectors Training, Querying, and Validation:** This walkthrough provides a full framework for the entire process of training, query, and validating a model. As with the Starter Queries walkthrough, it assumes you are working in the RStudio Server environment, so it does not include code for loading external packages, and it does include instructions for getting your output files out of RStudio Server and onto your own computer, and for loading your files into the RStudio Server environment.

**Word Vectors Installation, Training, Querying, and Validation:** This walkthrough covers the same functionality as the walkthrough above, but it assumes you are running the walkthrough on your own computer rather than in RStudio Server.

**Model Training &amp; Querying Template:** This walkthrough provides code for training and querying a model, without the preliminary steps of installing code packages, and with fewer comments (assuming that the user is already familiar with the process, from the other walkthroughs). It can be used in both the RStudio Server environment and on your own computer.

**Word Vectors Visualization:** This walkthrough provides more detailed code for visualizing an existing trained model, working through a set of example plots with the Women Writers Online collection. It can be used in both the RStudio Server environment and on your own computer.

You can find web-friendly versions of these notebooks at the [Women Writers Vector Toolkit](https://wwp.northeastern.edu/lab/wwvt/resources/walkthroughs/index.html) site.

site.

## Working on Your Own

If you want to train and work with models on your own computer, you can download the code walkthroughs from GitHub. Of the walkthroughs listed above, the following are the ones that are useful outside a workshop context:

**Introduction to R and RStudio:** This walkthrough gives an introduction to the basic concepts of the R programming language and the RStudio programming environment.

**Word Vectors Installation, Training, Querying, and Validation:** This "installation" walkthrough provides a full framework for the entire process of training, query, and validating a model on your own computer, together with detailed comments that explain the function of each code segment and how to modify it if necessary. This one is a good choice when you still want some guidance and reminders of what each piece of code does. Once you're familiar with the process, the "template" file (below) is a more streamlined version without the comments.

**Model Training &amp; Querying Template:** This walkthrough provides code for training and querying a model on your own computer, without the preliminary steps of installing code packages. Compared with the "Installation" walkthrough above, it omits the detailed comments (assuming that the user is already familiar with the process, from the other walkthroughs).

**Word Vectors Visualization:** This walkthrough provides more detailed code for visualizing an existing trained model, working through a set of example plots with the Women Writers Online collection. It can be used in both the RStudio Server environment and on your own computer.

# 1. Getting Set Up

## Downloading and Installing R and RStudio

If you are training a model on your own computer, the very first tasks are to download R and RStudio, and to download the [walkthrough folder](https://github.com/NEU-DSG/wwp-public-code-share/releases/tag/WordVectors/2021-07-02). You can download R from the CRAN (Comprehensive R Archive Network) repository: [https://cloud.r-project.org/](https://cloud.r-project.org/). To download RStudio see: [https://rstudio.com/products/rstudio/download/](https://rstudio.com/products/rstudio/download/).

## Installing R Packages

If this is the first time you are working with word2vec on your computer, there are a few initial steps to install the R packages you will need—this only needs to be done once.

- Open the WordVectors.Rproj file from the walkthrough folder you downloaded. This should automatically open in RStudio.
- Open the Word-Vectors-Installation-Training-Querying-and-Validation.Rmd file from the "Files" pane in the bottom-right of RStudio
- Run the code in the block starting at line 86 to install the necessary packages
- Run the code in the block starting at line 106 to load in the necessary packages, skipping line 117
- Run the code in the block starting at line 128 to install the `wordVectors` package using the `devtools` package
- Go back up to line 117 and run the code to load in the `wordVectors` package

You only need to install the packages once, but you will need to load them in at the start of each new session. In the sections below, the instructions assume that you are starting a new session but that the necessary packages have already been installed.

The instructions below reference the "template" RMD file (Model-Training-and-Querying-Template.Rmd), rather than the "installation" file (Word-Vectors-Installation-Training-Querying-and-Validation.Rmd). The installation file includes detailed comments that explain the code and how to run it, so please consult the installation file if you would like more explanation of any step. The steps outlined below will still be relevant if you are using different files, but the line numbers will differ.

# 2. At the start of any new session

These are the steps you will need to take any time you start a new session in RStudio.

- If you are working in RStudio Server, log into the class site
- Open the WordVectors.Rproj file
- Open the RMD walkthrough you want to use
- Check your working directory
- Load in the packages with the `library` function
- Load in a model or train a new one (see below)

# 3a. Training a new model (Working on your own)

- Put all your texts in a single folder, either with each saved as a .txt file or with all the texts in a single .txt file. Make sure not to use any spaces in the folder name, and do not put your texts in any subfolders.
- Copy or move the folder with your texts into the "data" folder inside the walkthrough folder that you downloaded
- Open the WordVectors.Rproj file from the walkthrough download
- Open the Model-Training-and-Querying-Template.Rmd file
- Run the code in the block starting at line 25 to confirm that your working directory is the WordVectors folder
- Run the code in the block starting at line 35 to load in the necessary packages
- Go to the block starting at line 51 and fill in the name of the folder with your texts. At line 54, delete the text that says name_of_your_folder and hit `tab` to navigate to your folder. Make sure not to delete "data/" or the surrounding quotation marks. Then run all the code in that block to read in your text files.
- Go to the block starting at line 76 and give your model a name by replacing the text that says your_file_name at line 79. Then run all the code in that block to create the variables you will use for training and querying models.
- Go to the block starting at line 90 and run all the code in order to train the model. See the "installation" file for information on what the parameters mean and how you might want to modify them.
- You can then use the sample queries that follow to engage with your new model

# 3b. Training a new model (RStudio Server)

- Put all your texts in a single folder, either with each saved as a .txt file or with all the texts in a single .txt file. Make sure not to use any spaces in the folder name, and do not put your texts in any subfolders.
- Compress the folder with your texts
  - on Macs: control-click and select "Compress"
  - on Windows: right-click on the folder, select "Send to," and then select "Compressed (zipped) folder"
- Go to our class RStudio Server instance
- Open the WordVectors.Rproj file from the WordVectors folder in the file browser pane on the bottom-right
- Click into the "data" folder from the file browser pane in the bottom-right and hit the "upload" button, then navigate to and upload the file with your compressed folder. **Make sure that you are in the data folder before you upload the file.**
- Open the Model-Training-and-Querying-Template.Rmd file
- Run the code in the block starting at line 25 to confirm that your working directory is the WordVectors folder
- Run the code in the block starting at line 35 to load in the necessary packages
- Go to the block starting at line 51 and fill in the name of the folder with your texts. At line 54, delete the text that says name_of_your_folder and hit "tab" to navigate to your folder. Make sure not to delete "data/" or the surrounding quotation marks. Then run all the code in that block to read in your text files.
- Go to the block starting at line 76 and give your model a name by replacing the text that says your_file_name at line 79. Then run all the code in that block to create the variables you will use for training and querying models.
- Go to the block starting at line 90 and run all the code in order to train the model. See the "installation" file for information on what the parameters mean and how you might want to modify them.
- You can then use the sample queries that follow to engage with your new model
- If you want to export any results from RStudio Server to your own computer:
  - in the Rmd walkthrough, run the code to create the export file and save it to your "output" folder
  - navigate to the export file in the file browser pane
  - click the checkbox to the left of the file name for your export file
  - go to the gear icon that says "More" near the top right of the file browser pane
  - under the dropdown menu: choose "Export," rename your file if you would like to, and hit "Download"
  - this will download the file to the default download location on your computer

# 4 a. Loading in an existing model (Working on your own)

- Open the WordVectors.Rproj file from the walkthrough folder you downloaded
- Open the Model-Training-and-Querying-Template.Rmd file from within RStudio
- Run the code in the block starting at line 25 to confirm that your working directory is the WordVectors folder
- Run the code in the block starting at line 35 to load in the necessary packages
- Go to the block starting at line 116 and fill in the model that you want to load in. Delete the text that says name_of_your_file.bin and hit "tab" to navigate to the file that you want. Make sure not to delete "data/" or the surrounding quotation marks.
- You can then use the sample queries that follow to engage with your selected model
- You can download the models used in the Toolkit [here](https://github.com/NEU-DSG/wwp-w2vonline/tree/main/data).

# 4 b. Loading in an existing model (RStudio Server)

- Go to our class RStudio Server instance
- Open the WordVectors.Rproj file from the WordVectors folder in the file browser on the bottom-right
- Open the WordVectors.Rproj file from the walkthrough folder you downloaded
- Open the Model-Training-and-Querying-Template.Rmd file from within RStudio
- Run the code in the block starting at line 25 to confirm that your working directory is the WordVectors folder
- Run the code in the block starting at line 35 to load in the necessary packages
- Go to the block starting at line 116 and fill in the model that you want to load in. Delete the text that says name_of_your_file.bin and hit `tab` to navigate to the file that you want. Make sure not to delete "data/" or the surrounding quotation marks.
- You can then use the sample queries that follow to engage with your selected model
- You can download the models used in the Toolkit [here](https://github.com/NEU-DSG/wwp-w2vonline/tree/main/data).
- If you want to upload a new model to RStudio Server
  - Click into the "data" folder from the file browser pane in the bottom-right and hit the "upload" button
  - Navigate to and upload the .bin file with the model you want to query
  - The model will then be in your "data" folder and you can follow the steps above to load it in and query it

# 5. Visualizing an existing model

- Open the WordVectors.Rproj file
- Open the Word-Vectors-Visualization.Rmd file from within RStudio
- Run the code in the block starting at line 25 to confirm that your working directory is the WordVectors folder
- Run the code in the block starting at line 34 to load in the necessary packages
- Go to the block starting at line 51 and either run the code at line 53 to read in the sample model, or fill in a different model of your own. Delete the text that says name_of_your_file.bin and hit `tab` to navigate to the file that you want. Make sure not to delete "data/" or the surrounding quotation marks. The first time you are using this file, you may find it helpful to keep the default model and queries, but you can then modify both to match your research interests.
- Run the code sections that follow to generate a set of plots visualizing query terms from the selected model.
- You can download the models used in the Toolkit [here](https://github.com/NEU-DSG/wwp-w2vonline/tree/main/data).

# 6. Troubleshooting

## Addressing error messages

At some point, you may encounter error messages! It's tempting to try to interpret them, and as you get more experienced it can be helpful to try to figure out exactly what went wrong. But you can often get past them and fix the problem by trying a few things (without necessarily understanding exactly what went wrong). Here's a checklist of things to try:

- If you're getting an error message during your very first session (for instance, you just downloaded RStudio onto a new computer and are getting set up), the problem may be that you haven't installed the code packages yet. Similarly, if you are having problems after a long period of not using RStudio, the packages might be out of date. Try opening the Word-Vectors-Installation.Rmd file and running the package installation code.
- If you're getting an error message at the start of a new working session (in other words, you've just opened or reopened the .rmd file), the problem may be that you haven't run all of the previous pieces of code in the file (including loading the code packages!). Remember that each of these walkthroughs is a sequence of commands, and each one depends on the ones before it. (For instance, the commands early in the sequence might define a variable that is used in a later command.) Try going back to the top and running each command in turn. You won't harm anything by re-running a command a second time. Another thing to check if you hit errors after you've just opened a session is that the WordVectors project is open. Look in the top-right corner, and if the drop-down says "Project(none)" then the project isn't open. You can open the project by going to "File" and "Open Project" or by selecting the "WordVectors" from the drop-down. The project might open in a new RStudio window, and that's not a problem—you can just switch over to the new window. Or, if you prefer, you can quit RStudio and then navigate to the WordVectors.Rproj file and re-open RStudio from there.
- If you're getting an error message in the middle of a session, and you just uploaded a new model, the problem could be that you haven't re-run the code that tells the system the name and location of your new model (or that you mis-typed the name of the model). Go back and make sure you've provided the correct filename and filepath for the new model and re-run that code.

## Command isn't completing

If you see that a command isn't completing and seems to be stuck, you may need to interrupt the command, restart R, or restart your whole RStudio application. Training a model can take a very long time (hours or longer), so you don't need to worry if that seems to be stuck—it's probably still running.

You can tell that a command is stuck if you don't see the command prompt (a greater-than sign, `>`) in the Console window on the lower left of the RStudio window, and if you're not seeing progress (for instance, no new lines of text appearing in the console reporting on progress.
 
First, try clicking the stop sign to stop the command.

If you don't see a stop sign, and want to restart without losing work and settings:

- Choose "Save" to save any changes you made to the RMD file
- Choose "Restart R" (in the "session" menu); this will restart R (and terminate any processes that might be stuck)
- You will need to reload the packages (the commands that look like this: library(tidyverse) etc.
- Your other settings and the other pieces of code you've run should still be active, but to be on the safe side, you could re-run those as well.

If that doesn't work, you can also quit RStudio (after saving your RMD file if you've made any changes).


