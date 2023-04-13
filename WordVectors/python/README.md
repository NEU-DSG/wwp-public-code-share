# Word2vec Python Walkthroughs with Gensim

These walkthroughs provide code and instructions for training and querying models using the Gensim instantiation of Word2Vec. The walkthroughs also cover fundamental concepts in Python.

## Walkthrough Files

This directory contains four Jupyter Notebook files, each of which contains a combination of prose and executable code cells:

* [Introduction to Python](python-fundamentals.ipynb) provides an overview of fundamental concepts in the programming language Python that are necessary for the subsequent notebooks. The notebook assumes that users have an understanding of basic programming concepts but perhaps not Python specific knowledge.
* [Introduction to Word Vectors in Python](word2vec-fundamentals.ipynb) provides an introductory framework for importing data, cleaning data, training a Word2Vec model, querying that model, and finally evaluating that model. The notebooks as they are currently written use a dataset of nineteenth-century American recipes which has been included with the directory. This sample dataset can be modified.
* [Exploratory Visualization With Word2Vec](word2vec-visualization.ipynb) provides a framework for exploratory visualization techniques using Word2Vec. The notebook is currently written to use a sample model provided with the directory, but this sample model can be swapped out with another.
* [Further Explorations of Word Vectors in Python](further-explorations.ipynb) elaborates on the Word2Vec notebooks above to provide possibilities for further analysis as well as explain the broader world of machine learning that Word2Vec is a part of.


## Downloading Jupyter Notebooks
The walkthroughs are written in Jupyter Notebook, an IDE with particularly useful pedagogical use given its ability to intermix prose and executable code. The code will work in other Python IDEs, but to execute the code as it is currently written, it is recommended that you download and install Jupyter Notebook. 

You can follow download instructions through Jupyter's [website](https://jupyter.org/install) or download Jupyter Notebook as part of an [Anaconda Distribution](https://docs.anaconda.com/anaconda/install/) (which comes with other IDEs installed in addition to Jupyter Notebook).

## Support Files

In addition to the four Jupyter Notebook files, the directory also contains three sub-directories. 

The "data" sub-directory contains two versions of the sample recipe dataset. The first, is a folder called "sample-data-recipes" which contains all of the recipes in plain text format. This is the folder that the walkthroughs primarily use. The second version of the dataset is formatted as a .csv file, "sample_csv_recipes.csv" which includes a recipes sampled from nineteenth-century OCR'd newspapers. It should be noted that the .csv data is much messier given that it was produced by applying OCR to historical documents. The .csv file is primarily present to provide a sample set for those wishing to try out the alternative data-importing workflow outlined in the introductory Word2Vec notebook.

The directory also includes a "models" sub-directory within which is a sample model ("test.model") and a sample .wordvectors file ("word2vec.wordvectors"). All models produced by the notebooks should be saved to this folder.

Finally, the directory includes an "output" sub-directory which is where the .csv files produced by the evaluation step in the introductory Word2Vec notebook are saved. The directory currently includes a sample file ("sample_word2vec_model_evaluation.csv") which contains the evaluation results produced by evaluating the "test.model" model in the "models" sub-directory.

## Credits and Thanks
These walkthroughs use the Gensim instantiation of Word2Vec, an algorithm developed by Mikolov et al. The walkthroughs were informed by related Women Writers Project walkthroughs developed using the R programming language as well as an initial draft of in Python by Felix Muzny at Northeastern University. 

The walkthroughs were developed as part of the Word Vectors for the Thoughtful Humanist series at Northeastern. Word Vectors for the Thoughtful Humanist has been made possible in part by a major grant from the National Endowment for the Humanities: Exploring the human endeavor. Any views, findings, conclusions, or recommendations expressed in this project, do not necessarily represent those of the National Endowment for the Humanities.

The walkthroughs are freely available on GitHub at <https://github.com/NEU-DSG/wwp-public-code-share/releases>.
