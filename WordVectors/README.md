# Word2vec Walkthroughs

These walkthroughs provide code and instructions for training and querying models using the `wordVectors` R package developed by Ben Schmidt and Jian Li.

## Walkthrough Files
This directory contains two RMarkdown files: `introduction_word2vec.Rmd` includes detailed instructions and comments; it is designed to cover the full process from installing packages to testing models for those who have a basic familiarity with R but no previous experience with `word2vec`. `template_word2vec.Rmd` includes code for training and querying models with more minimal instruction; it is designed to make these processes convenient for those who are familiar with the basics. 

## Support Files
The directory also contains a "data" folder with a small set of test texts. It should be noted that these are intended only to provide an example of data setup and a quick sample set for training—the corpus is too small to produce a valid model. There is also an "output" folder where any exports can be saved, with a sample file that shows the results of the basic model test included in this walkthrough.

Finally, the directory contains a project file, `WordVectors.rProj`. The easiest way to get started with these walkthroughs is to download the whole folder and then open the project file in RStudio. From there, navigate to the "Files" panel and open `introduction_word2vec.Rmd`. That file includes all the instructions necessary to install and load required packages, read in text files, and train a model. 

## Credits and Thanks
These walkthroughs use the `wordVectors` package developed by Ben Schmidt and Jian Li, itself based on the original `word2vec` code developed by Mikolov et al. The walkthroughs were also informed by workshop materials shared by Schmidt, as well as by an exercise created by Thanasis Kinias and Ryan Cordell for the "Humanities Data Analysis" course, and a later version used in Elizabeth Maddock Dillon and Sarah Connell's "Literature and Digital Diversity" class, both at Northeastern University.

The walkthroughs were developed as part of the Word Vectors for the Thoughtful Humanist series at Northeastern. Word Vectors for the Thoughtful Humanist has been made possible in part by a major grant from the National Endowment for the Humanities: Exploring the human endeavor. Any views, findings, conclusions, or recommendations expressed in this project, do not necessarily represent those of the National Endowment for the Humanities.

