# Word2vec Walkthroughs

These walkthroughs provide code and instructions for training and querying models using the `wordVectors` R package developed by Ben Schmidt and Jian Li.

## Walkthrough Files
This directory contains six RMarkdown files, some of which are designed for RStudio Server or RStudio Desktop:

* `Introduction to R and RStudio` gives an introduction to the basic concepts of the R programming language and the RStudio programming environment. It can be used in both the RStudio Server environment and on your own computer.
* `Word Vectors Starter Queries` provides a framework for querying a model that has already been trained (it does not include the code for the model training process). It assumes that you are working in the RStudio Server environment, so it does not include code for loading in external code packages, since those are provided within the Server environment.
* `Word Vectors Training, Querying, and Validation` provides a full framework for the entire process of training, query, and validating a model. As with the Starter Queries walkthrough, it assumes you are working in the RStudio Server environment, so it does not include code for loading external packages, and it does include instructions for getting your output files out of RStudio Server and onto your own computer, and for loading your files into the RStudio Server environment. 
* `Word Vectors Installation, Training, Querying, and Validation` covers the same functionality as the walkthrough above, but it assumes you are running the walkthrough on your own computer rather than in RStudio Server.
* `Model Training and Querying Template` provides code for training and querying a model, without the preliminary steps of installing code packages, and with fewer comments (assuming that the user is already familiar with the process, from the other walkthroughs). It can be used in both the RStudio Server environment and on your own computer.
* `Word Vectors Visualization` provides more detailed code for visualizing an existing trained model, working through a set of example plots with the Women Writers Online collection. It can be used in both the RStudio Server environment and on your own computer.

## Downloading R and RStudio
Before you open these files, it is helpful to download R and RStudio. You can download R from the CRAN (Comprehensive R Archive Network) repository: [https://cloud.r-project.org/](https://cloud.r-project.org/). There are specific instructions for downloading to Linus, Mac OS X, and Windows machines.
To download RStudio see: [https://rstudio.com/products/rstudio/download/](https://rstudio.com/products/rstudio/download/).

## Support Files
The directory also contains a "data" folder with a small set of test texts. It should be noted that these are intended only to provide an example of data setup and a quick sample set for training—the corpus is too small to produce a valid model. There is also an "output" folder where any exports can be saved, with a sample file that shows the results of the basic model test included in this walkthrough.

Finally, the directory contains a project file, `WordVectors.Rproj`. The easiest way to get started with these walkthroughs is to download the whole folder and then open the project file in RStudio. From there, navigate to the "Files" panel and open either `Introduction-to-R-and-RStudio`, if you want a quick introduction to R and RStudio, or `Word-Vectors-Installation` if you want to get right to training and querying models. The `Installation` file includes all the instructions necessary to install and load required packages, read in text files, and train a model. 

## Credits and Thanks
These walkthroughs use the `wordVectors` package developed by Ben Schmidt and Jian Li, itself based on the original `word2vec` code developed by Mikolov et al. The walkthroughs were also informed by workshop materials shared by Schmidt, as well as by an exercise created by Thanasis Kinias and Ryan Cordell for the "Humanities Data Analysis" course, and a later version used in Elizabeth Maddock Dillon and Sarah Connell's "Literature and Digital Diversity" class, both at Northeastern University.

The walkthroughs were developed as part of the Word Vectors for the Thoughtful Humanist series at Northeastern. Word Vectors for the Thoughtful Humanist has been made possible in part by a major grant from the National Endowment for the Humanities: Exploring the human endeavor. Any views, findings, conclusions, or recommendations expressed in this project, do not necessarily represent those of the National Endowment for the Humanities.

The walkthroughs are freely available on GitHub at <https://github.com/NEU-DSG/wwp-public-code-share/releases>.
