#!/usr/bin/env python
# coding: utf-8

# # Further Explorations of Word Vectors in Python
# 
# Author: Avery Blankenship
# 
# Date: 9/6/23
# 
# ---
# 
# This notebook builds off of the core notebook and analysis notebook and assumes that you have completed both before proceeding to this one. 
# 
# This notebook features a mix of more in-depth code and as well as broader theoretical knowledge that applies to Word2Vec as well as other machine learning problems. This notebook will provide you with some of the jargon and code snippets you may need to continue working with Word2Vec on your own

# ## Libraries Relevant for This Notebook

# In[ ]:


# A good practice in programming is to place your import statements at the top of your code, and to keep them together

import re                                   # for regular expressions
import os                                   # to look up operating system-based info
import string                               # to do fancy things with strings
import glob                                 # to locate a specific file type
from pathlib import Path                    # to access files in other directories
import gensim                               # to access Word2Vec
from gensim.models import Word2Vec          # to access Gensim's flavor of Word2Vec
import pandas as pd                         # to sort and organize data


# ## Further Explorations with Word2Vec and Gensim

# ### What Algorithm Should I Use?

# The notebooks thus far have all used the Word2Vec algorithm as implemented in Gensim, but there are actually other libraries and algorithms that you could consider for further work. 
# 
# Although there are many algorithms out there that work with word vectors, they all have their pros and cons. The two most popular word embedding algorithms are Word2Vec (which we have used in the prior notebooks) and GloVe. **GloVe** is an unsupervised learning algorithm designed by Stanford University. GloVe comes with a few pre-trained models which makes exploring some of the functionality of word embedding models quick and straightforward. Word2Vec and GloVe approach word embedding models differently. While Word2Vec uses the training data provided to create a neural network through the Skip-Gram or Continuous Bag of Words methods, GloVe focuses more on word co-occurrence based on probability. In short, Word2Vec predicts and GloVe counts. 
# 
# There are two libraries in Python that come with Word2Vec (the prior notebooks used Gensim):

# **Gensim** is a popular natural language processing library that is usually used for topic modeling. Gensim comes with the popular Word2Vec algorithm
# 
# **Spacy** is also a popular natural language processing library that is designed to be very fast. Spacy also uses Word2Vec style word embeddings, but tends to be slightly faster than Gensim. Spacy also comes with pre-trained models built in which is incredibly useful if you are wanting to get familiar with querying a model before building your own. 

# For these notebooks, we chose to use Word2Vec in Gensim because of the ease of use and speed. The built-in functions that come with Gensims flavor of Word2Vec make it a very beginner-friendly way to implement word vectors
# 
# Gensim is a very memory-efficient way to work with word embedding models. Not only does Gensim come with some cool algorithms that you can apply to a downstream task such as topic modeling, but Gensim also allows you to process large amounts of text without storing them into memory. Developed by Radim Řehůřek, Gensim is one of the most popular libraries for training word embedding models in Python. Its popularity is an important feature for these notebooks because that means there is a vast amount of community support for the library, making troubleshooting very easy. 
# 
# However, if you want some quick, out of the box models to work with to test things out, then GloVe may be worth trying out. The variety of algorithms and libraries out there offers a wide degree of choice and depending on what type of corpus you're working with, one might be better than the other. Understanding *why* you are using a specific algorithm and library can help you in troubleshooting as well as ensure that you're taking advantage of their best features.

# ### How to Be More Memory Efficient

# #### Loading Model Vectors
# 
# Even though Gensim is memory efficient, you can still use code that will lessen the burden of the model on your computer. One way to make your code more memory efficient is to load only the vectors themselves, rather than the entire model, when you are just planning on querying the model. Typically, models include all of the word vectors plus everything else that makes it a model. Vectors are just a portion of the entire model. By only loading the vectors, you don't have to load the entire model into memory, which can lessen the computational burden on your computer. The code below explains how to load the vectors from a Gensim model.
# 
# If you are looking to retrain your model, introduce new texts, evaluate the model, or anything that requires communication with the model, loading only the vectors will prevent you from doing that. However, if you only want to get lists of the most similar phrases, do vector math, or any task that is just limited to the vectors-as-is, then loading only the vectors can help your computer out.
# 
# #### The Code
# 
# The first thing that we want to do is actually pull the vectors out of the model. Then, we'll save those vectors as a new file just like the `.model` file so that we can call those vectors later. In this code, we initiate a new variable called `word_vectors` which will hold `model.wv.` `Model.wv` represents the word vectors within the model itself. Then, we save the word vectors that we have pulled out of the model as a `.wordvectors` file called `word2vec`. Finally, we initialize a variable called `wv` (short for 'word vector') and use the `KeyedVectors()` function to load the `.wordvectors` file and read it in. 

# In[ ]:


from gensim.models import KeyedVectors


# make sure that your model is loaded
model = Word2Vec.load("./models/test.model")

# declare a variable to hold the vectors
word_vectors = model.wv

# save those vectors to a new file so that we can use them later
word_vectors.save("./models/word2vec.wordvectors")

# now load those vectors
# you can now query the model by using "wv"
wv = KeyedVectors.load("./models/word2vec.wordvectors", mmap='r')


# You can now just use `wv.` to query the model rather than `model.wv.` `wv` is capable of performing all of the querying functions as `model.wv` can

# In[ ]:


# gives the word most similar to 'recipe'
wv.most_similar('recipe', topn=10)

# gives a cosine similarity for the words 'milk' and 'cream'
wv.similarity("milk", "cream")


# ### Resuming Training

# Working with word embedding models is typically an iterative process where you train a model, evaluate it, and then train the model again. Thankfully, Gensim provides the functionality for introducing new data to an existing model. 
# 
# The code below is formatted to read in a list of sentences that are hard-coded, however, if you have a folder of texts or a spreadsheet, you would just use the methods outlined in the core notebook which I won't re-hash here. Essentially, the entire process is the same as before, except instead of declaring a new model we just use the `train()` function that we have built in. 
# 
# #### The Code
# 
# After loading in the libraries we need, the code below begins by loading the current version of our model into memory by using `Word2Vec.load()`. Next, I have declared a list variable with a few sentences from a cupcake recipe in it as strings. If you are using more extensive data, then this is where you would repeat the step of loading in from a folder or spreadsheet from the core notebook. 
# 
# Then, I have the `clean_text()` defined. This function is exactly the same as the `clean_text()` function from the core notebook. I apply the `clean_text()` function to my list in the same way I did in the core notebook. Up until this point, all of these steps are borrowing from the core notebook. 
# 
# Now, we get to the bit that differs from the core notebook. Now that we have a list of tokens, we build the vocabulary for our model by calling `model.build_vocab()`. We are building the vocabulary using the new data and using the `update=True` parameter to let our model know that we are updating the vocabulary in our existing model.
# 
# Finally, we call the built in function `train()` to retrain the model. Whereas in the core notebook, we used `model= Word2Vec()` to train a new model, by using `model.train()` we tell the model to train using these additional items rather than replacing the vocabulary that the model has already built. If you were to call `model=Word2Vec` instead, you would be overwriting the existing model to only contain the vocabulary of the new data.

# In[ ]:


import gensim                      # for Word2Vec
from gensim.models import Word2Vec # for Word2Vec
import re                          # for regular expressions
import string                      # for string comprehension

# load our current model
model = Word2Vec.load(r"./models/test.model")

# declare a variable with our new sentences/words
# you can use the folder/spreadsheet method from the core notebook if you have more data
more_sentences = [
    "Cup cake is about as good as pound cake, and is cheaper.", 
     "One cup of butter, two cups of sugar, three cups of flour,", 
     "and four eggs, well beat together, and baked in pans or cups.", 
     "Bake twenty minutes, and no more."
]

# we're going to use out clean_text() function from the core notebook
def clean_text(text):
    re_punc = re.compile('[%s]' % re.escape(string.punctuation))

    # lower case
    tokens = text.split()
    tokens = [t.lower() for t in tokens]
    # remove punctuation
    tokens = [re_punc.sub('', token) for token in tokens] 
    # only include tokens that aren't numbers
    tokens = [token for token in tokens if token.isalpha()]
    return tokens

# declare an empty list to hold our clean text
data_clean = []

# iterate through the new data and apply the data_clean() to each item
for x in more_sentences:
    data_clean.append(clean_text(x))

# build our model vocab and tell the model that we are updating the vocab
model.build_vocab(data_clean, update=True)

# tell the model to re-train with the new data
model.train(data_clean, total_examples=model.corpus_count, epochs=model.epochs)


# You can add additional data and retrain a model as many times as you want. Something to keep in mind, however, is that you may want to save your model under a different name than the name of the previous model. This way, you'll still have access to the old model in case something goes wrong in the re-training process. To do so, you would do the following:

# In[ ]:


# save the model as a retrained model with the date that it was retrained 
# you can save your newly trained model under whatever name makes the most sense to you
model.save("./models/word2vec_retrained_08012022.model")


# ### Using Pre-Trained Models

# Gensim also provides the functionality to load an existing model into memory. Using pre-trained models can be incredibly useful if you know of a model that someone else has already trained that suits your needs. For example, the Google News Dataset is freely available to use and is already trained on roughly three million words.
# 
# #### The Code
# 
# In the code below, we begin by loading the `gensim.downloader` as `download`. Then we declare a variable `wv` and use it to store our call to download the Google dataset. To query the model, you can use all of the queries and analysis functions introduced in the core and analysis notebooks by calling `wv`. Keep in might that the Google model is very large and may take a while to download.

# In[ ]:


import gensim.downloader as download
wv = download.load('word2vec-google-news-300')


# If you get a warning that says *IOPub data rate exceeded*, try running the code below in the anaconda prompt, terminal, or command prompt. This warning occurs when you are trying to send too much data to the Jupyter servers, so the server throws an error. You are unlikely to run into this warning in other IDEs.

# In[ ]:


jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10


# Another method for using pretrained models, is to load them using the built in `load_word2vec_format()` that comes with Word2Vec. This function accepts as input a binary file. 

# ### What to Do With Your Model

# In addition to some of the cool questions you can use to query your model, like analyzing the similarities between two words or using vector math to analyze groups of words, there are a few other interesting ways that you can use your model.
# 
# As we explored a bit in the core notebook, the Gensim implementation of Word2Vec has a built in function that allows the model to suggest words that may belong to a grouping of words you provide it with. However, there are also a few extensions of Word2Vec that allow you to accomplish more extensive classification and prediction. 
# 
# Doc2Vec is a Word2Vec extension that allows you to generate vectors for variable-length input. This means that with Doc2Vec, you can train a model on entire sentences or even entire documents. A Doc2Vec model has the ability to infer a vector for an unseen document which can be useful for classification tasks. Similarly, Top2Vec is an extension that borrows from both Word2Vec and Doc2Vec in order to generate topic clusters based on the vectors generated for a document based on their location in semantic space.  While both Doc2Vec and Top2Vec are more complex than Word2Vec, the training process very closely resembles the process for using Word2Vec and in some instances, is the same. If you're interested in building a Doc2Vec model, check out the [Doc2Vec documentation](https://radimrehurek.com/gensim/models/doc2vec.html) and notice the similarities between the code for Word2Vec.

# ## The Wider World of Machine Learning

# #### Supervised vs. Unsupervised vs. Semi-Supervised Algorithms

# Whenever you are training a model, the way that you approach training can impact what your results mean and even the type of results you get from querying your model. Since models are generated based on the model learning about the data and the information you provide it with, the way your model understands the data greatly depends on the type of data you give it. Training methods for models fall in one of three categories:
# 
# #### Supervised
# 
# Supervised learning means that the model is learning based on data that is labeled. This training method is called "supervised" because the model isn't left to learn on its own, but is instead provided with the "answers," which it can use to correct itself. For example, say you wanted to train a model that classifies novels as either horror or romance. The type of data you would need to provide the model is the content of the novel plus a genre label. Once the model finishes training, it will be able to predict that a novel is either horror or romance based on what it has learned about the novels and labels you have provided it. 
# 
# While supervised learning can be incredibly useful for classification problems, it is also a type of learning that is easy to introduce bias into. For example, if you were training a model designed to classify movie scripts as either happy or sad, the model will not objectively sort these scripts but will instead sort them based off the understanding of happy or sad that you have given it based on the data labels. Since the labels are determined based on your personal judgment, there are many opportunities for the model to classify data in ways that are not necessarily representative. It is important to keep this distinction in mind when you are presenting the results of your training method since it influences how others interpret your work. 
# 
# #### Unsupervised
# 
# Unsupervised learning means that the model has learned about the data you have provided on its own. Using algorithms that cluster, match, and otherwise analyze the unlabeled data, the model will present you with the results it has generated based on this analysis. While it is slightly harder for the results to be skewed with an unsupervised model, it is important to note that on the basis of having created the data set, there is already some degree of bias that has been introduced. For example, let's say that you have created a corpus of children's books and you want the model to cluster together similar words. Since you can't have possibly provided the model with every children's book ever written, by virtue of not including every book, the model will understand children's books to be whatever set you have given it. 
# 
# Unsupervised learning is ideal for clustering tasks since clusters are not determined by labels. However, since the clusters do not have access to labeled data, the model is unable to categorize the clusters based on, for example, genres or types.
# 
# #### Semi-Supervised
# 
# Semi-supervised learning is a method that is somewhere in between supervised and unsupervised learning. While supervised learning uses data labeled by the researcher and unsupervised learning uses data that is unlabeled, semi-supervised learning uses data with labels that are generated by the computer. Word2Vec, for example, is a semi-supervised algorithm, for example, since the input of the algorithm does not require labeled data, but labels are generated by the model, itself, based on features it notices. The "labels" are largely determined in Word2Vec by the neural networks (CBOW or skip-gram) which classifies words based on examples (words with a shared context). 

# ### What is a Downstream Task?

# Another neat way to use your Word2Vec (or Doc2Vec) model, is for downstream tasks. A downstream task is a task which accepts the output from a prior task as input. For example, if you wanted to use the vectors generated by Doc2Vec to classify unseen documents, you could train a new model to classify documents based on the Doc2Vec model and labels you generate. Downstream tasks are supervised, so at some point you would need to generate some type of label for your data using either computer-generated labels or your own. Essentially, the process uses the initial training stage (for example Doc2Vec) to allow the model to learn more general information about your data and you use this more general model to produce more specific results. This type of analysis is incredibly useful for sentiment analysis or to conduct named entity recognition. A good place to begin learning about downstream tasks, is though [Jay Alammar's blog post](http://jalammar.github.io/illustrated-bert/) on the topic.

# ## Next Steps

# If you want to learn more about some of the cool stuff word embedding models can be used for, check out [Word2Vec's documentation](https://radimrehurek.com/gensim/models/word2vec.html). You can also check out the [Word2Vec tag on Stack Overflow](https://stackoverflow.com/questions/tagged/word2vec) to see what some of the more recent discussion around Word2Vec is. Finally, you can also visit the [Gensim documentation](https://radimrehurek.com/gensim/auto_examples/index.html) site to learn more about Gensim's specific implementation of Word2Vec.
