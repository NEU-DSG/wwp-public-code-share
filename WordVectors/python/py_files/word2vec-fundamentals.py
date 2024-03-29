#!/usr/bin/env python
# coding: utf-8

# # Introduction to Word Vectors in Python
# 
# Author: Avery Blankenship
# 
# Date: 9/6/23
# 
# ---
# 
# This Jupyter Notebook is designed to walk you through the basics of creating a word embedding model using one of the most popular natural language processing libraries, Gensim. This notebook uses Python 3 and assumes very basic understanding of Python and code more generally. For a brief introduction to core Python concepts, please see our [Python Fundamentals notebook](python-fundamentals.ipynb).
# 
# ## What are word embedding models useful for?
# 
# In addition to allowing you to ask really interesting questions of your textual data (for instance, what word is most similar to "king"), word embeddings have other uses in natural language processing. For instance, a word embedding model can be used for natural language processing tasks such as text classification. Because word embeddings capture the semantic use of a word, many natural language processing tasks become much easier with a model trained on word vectors. Word embedding models can also help us understand how language works in a set of texts. For instance, what if you wanted to know what words are most often used in the same contexts as "women" and "girls" in magazines aimed at men or women? Word embedding models would be an excellent methodological choice. 
# 
# In general, if you want to ask questions about how language is used—and in particular about the relationships between words—in a collection of texts, word embeddings are a great tool to consider. 
# 
# 
# ## How do I navigate this Jupyter Notebook?
# 
# This notebook is designed to be read from top-to-bottom. The notebook contains the core concepts that you need to get started with Word2Vec. The notebook uses a combination of text and code cells. The code cells contain real code that can be run in the notebook directly. In order to run a code cell, select the cell and then click the "run" button in the toolbar at the top. Typically, the code will be explained line-by-line and then the code, in its entirety, will be located in a single block at the end of each section.

# ## Word Embeddings Using Gensim
# 
# One of the first things that we need to do is make sure that all of the libraries that we need are installed. For this tutorial, we will be using the following libraries:
# 
# - **re** The re library gives us access to regular expressions which makes cleaning data much easier
# - **os** The os library allows us to access operating-system based information
# - **string**  The string library gives us access to a wide variety of string functions. Since we are working with text data, this is useful
# - **glob** The glob library allows you to access files based on their filetype. This will be useful to loading a set of models into memory
# - **Path** The Path library gives us access to files in other directories besides our current working directory
# - **gensim** Gensim is the library which contains the particular instance of Word2Vec that we are using 
# - **Word2Vec** We will be accessing this particular flavor of Word2Vec through Gensim. Word2Vec is what will convert our text data into vectors
# - **pandas** The pandas library allows us to work with dataframes, it makes sorting and organizing data much faster
# 
# 
# In order to install these libraries, you should refer back to the "Libraries" portion of the introduction to Python notebook. It is a good coding practice to have all of your imports at the top of your code, so we are going to go ahead and load everything that we need for the entire tutorial here. There are comments next to each library explaining what each is for. 

# In[ ]:


# A good practice in programming is to place your import statements at the top of your code,
# and to keep them together

import re                                   # for regular expressions
import os                                   # to look up operating system-based info
import string                               # to do fancy things with strings
import glob                                 # to locate a specific file type
from pathlib import Path                    # to access files in other directories
import gensim                               # to access Word2Vec
from gensim.models import Word2Vec          # to access Gensim's flavor of Word2Vec
import pandas as pd                         # to sort and organize data


# ## Loading Your Data 
# 
# 
# ### Loading Texts from a Folder 
# 
# Next, we need to load our data into Python. It is a good idea to place your dataset somewhere it's easy to navigate to. For instance, you could place your data in a folder in your Documents folder or in the same repository as your code file. In either case, you will need to know the **file path** for the folder with your data. Then, we are going to tell the computer to iterate through that folder, pull the text from each file, and store it in a dictionary. This code is written to process a folder with plain text files (`.txt`). These files can be anywhere within this folder, including in sub-folders. 
# 
# A few important things to note:
# 
# 1. When you are inputting your filepath, you should use the **entire** file path. For example, on a Windows computer, that filepath might look something like: `C:/users/admin/Documents/MY_FOLDER`. On a Mac, the filepath might be: `/Users/admin/Documents/MY_FOLDER`. 
# 
# 2. You can use **tab completion** to fill in your file paths. Within the quotation marks (don't delete these!), hit the `tab` key and it will bring up the folders and files at your specific location. You can enter `../` to go up a directory. Each time you enter `../` it will go up one folder level in your computer, and you can then use `tab` to check where you are. Once you get **up** to, say, your "Documents" folder, you can then use `tab` to go **down** into the folder with your files. Entering the name of the folder you want after you hit `tab` will narrow your results to make the navigation a bit more efficient. Even if you are not used to filling in file paths, you can use this combination of `tab` and `../` to navigate to the folder with the files that you want to use.
# 
# 3. You can use a file path to a folder full of different types of files, but this code is only going to look for **.txt** files. If you want to work with different file types, you'll have to change the `endswith(.txt)` call. However, keep in mind that these files should always contain some form of plain text. For example, a Word document or a PDF won't work with this code. 
# 
# If you are working on a Windows computer and are getting an encoding error when you try to run the code below, replace this code:
# 
# ```python
# for filename in filenames:
#     with open(filename) as afile:
#         print(filename)
#         data.append(afile.read()) # read the file and then add it to the list
#         afile.close() # close the file when you're done
# ```
# 
# With 
# 
# ```python
# for filename in filenames:
#     with open(filename, encoding="utf-8") as afile:
#         print(filename)
#         data.append(afile.read()) # read the file and then add it to the list
#         afile.close() # close the file when you're done
# ```
# 
# You may also need to escape the backslashes in the filepath. All this means, is that instead of the filepath looking like `C:\user\admin\`, it will instead look like `C:\\user\\admin\\`

# ## The Code
# 
# Lets walk through what the code is doing before we run it. As the comments indicate, the code begins by reading the file path that you provided. The "r" in front of the file path tells the computer "hey, read whatever is at this file path location." Then, we initiate two empty lists, one called `filenames` and one called `data`. 
# 
# `filenames` will be used to store the name of each file as the code is traversing (or walking through) the folder. `data` will hold all of the textual data from each .txt file.
# 
# The first set of `for` loops tells the computer "find all of the files that end with `.txt` in this folder and save their filenames to our `filenames` list. The reason there are two `for` loops here is that this code will traverse through subfolders. So, you could provide a file path which points to a folder with other folders nested at varying levels within that main folder and the code will peek into each of these folders and pull out any file that ends with `.txt`
# 
# The second code chunk takes that list of relevant filenames and tells the computer "open each file in this filename list, and dump whatever is in that file into our `data` list." As the computer is working through the files, it will open a file, read it, and then close it. Closing the file once it has been read is an important step for saving memory. Otherwise, you could have over a hundred text files open. Remember computers are actually pretty simple—they only do what you tell them to and nothing else.
# 

# When you run the code block below, you should see a list of loaded files printed as the output under the code cell. If you don't see that list, then check to make sure that `dirpath` and `file_type` are set correctly

# In[ ]:


dirpath = r'./data/sample-data-recipes/' # get file path (you can change this)
file_type = ".txt" # if your data is not in a plain text format, you can change this
filenames = []
data = []

 # this for loop will run through folders and subfolders looking for a specific file type
for root, dirs, files in os.walk(dirpath, topdown=False):
   # look through all the files in the given directory
   for name in files:
       if (root + os.sep + name).endswith(file_type): 
           filenames.append(os.path.join(root, name))
   # look through all the directories
   for name in dirs:
       if (root + os.sep + name).endswith(file_type): 
           filenames.append(os.path.join(root, name))

# this for loop then goes through the list of files, reads them, and then adds the text to a list
for filename in filenames:
    with open(filename, encoding='utf-8') as afile:
        print(filename)
        data.append(afile.read()) # read the file and then add it to the list
        afile.close() # close the file when you're done


# ### OPTIONAL: Loading Data from a Spreadsheet
# 
# If you have already loaded in text files in from a folder, you can skip this step. This step is optional for those who would prefer to work with text data in a spreadsheet rather than a folder of text files. 
# 
# Gensim is pretty versatile in that it doesn't particularly care **where** your text data comes from, as long as it is formatted as machine readable. Lets take, for example, a researcher who instead of individual text files, has a spreadsheet where one column records where the text is sourced from and one column contains the actual text that the researcher is interested in. Converting a spreadsheet like this to plain text and feeding it into Gensim is fairly straightforward. 
# 
# Begin by saving your spreadsheet in a CSV format. CSV (comma separated values) is machine readable unlike an Excel file and so our code will be able to work with the spreadsheet data. Once you have your CSV file, run the code below. 
# 
# This code begins by using the list variable `col_list` to hold the names of the columns we want to use from our CSV file, and we access the columns by their index key (for example, the column name or the column number) using square brackets: []. In the example below, I am using the columns "cluster" and "text" from the CSV. If you had a CSV with columns such as "id," "title," "author," and "text," and you only wanted to keep the "id" column and the "text" column, then you would write the `col_list` variable so it looks like this: 
# 
# ```python
#     col_list = ["id", "text"]
# ```
# 
# The second line in the code block is using the `pandas` library to read the CSV into a dataframe. `pandas` is a useful library here because not only do dataframes preserve the structure of a CSV file with columns and rows, but the `pandas` library comes with built-in functions that make processing CSV files quick. 

# In[ ]:


# columns you want to use, change to whatever your column headings are
col_list = ["text"] 

# update the filepath to the location of your CSV
df = pd.read_csv(r'./data/sample_csv_recipes.csv', usecols= col_list)


# ## Cleaning the Data ##

# Now that we have our data in our `data` variable (if you are using the optional CSV code, the data will be in the `df` variable), it's time to do something with it. When we use textual data to train a model, the model builds what is called a "vocabulary." The vocabulary is all of the words that the model has been introduced to in the training process. This means that the model only knows about words that you have shown it. If your data includes misspellings or inconsistencies in capitalization, the model won't understand that these are mistakes. Think of the model as having complete trust in you—if you give it a bunch of words that are misspelled, the model will trust that you know what you're doing and understand those misspelled words to be "correct." These errors will then make asking the model questions about its vocabulary difficult. 
# 
# An important next step after collecting your data is cleaning it. When we say "clean" what we mean is to remove some of the "noise" and inconsistencies in our data that may impact how accurately the model understands our data. For example, if you are working with text data that was created through OCR (optical character recognition) the computer-generated transcription may contain errors and inconsistencies in spelling. These errors and inconsistencies can even make our word embedding models inaccurate. One way to minimize the impact of these inconsistencies is to change what our text looks like before training a model with it. 
# 
# OCR errors aren't the only kind of "noise." Even inconsistencies in capitalization, punctuation, and the inclusion of what we call "stop words" or common words such as *in*, *and*, *but*, *over*, etc. can impact how well your model understands your data. Computers don't actually understand human language, so your model won't understand that "Apple" and "apple" are the same word unless you make it extremely obvious (by making both words lowercase, for example). Your computer also doesn't know that you probably want to ignore common stopwords so that you don't get words like "and," "but," and "or," taking up space for other, more interesting words in your analysis. No matter what, you will have to clean your data in some way, but you should be careful to make informed decisions about how and why you are cleaning your data before proceeding.
# 
# However, not all noise is bad noise. Some researchers, for example Cordell (2017) and Rawson and Muñoz (2019) advocate for more embracing of noise, emphasizing that textual noise can also be useful for some research. For this reason, "the cleaner the better" isn't necessarily the best approach depending on the types of questions you are asking of your data. 
# 
# At this point in the tutorial, it might be useful to take a step back and ask yourself:
# 
# 1. What do you want to know about your data?
# 2. Can your questions be answered using the data in its current state?
# 
# As you clean your data, it is important to take careful notes on what, exactly, you decided to do with this noise. These notes may come in handy as you train more models since they can help you remember how you cleaned your data initially.  
# 
# For this walkthrough, we are going to do some basic cleaning using regular expressions. Some of the corrections/changes we are going to make to the data are: 
# 
# 1. Tokenize the data. 
# 2. Making all of the words lowercase. We do this so that "Apple" and "apple" are treated the same word.
# 3. Removing punctuation. We are removing punctuation because, again, we don't want something like "'Apple'" and "Apple." to be treated as distinct words
# 4. Remove any numbers from the data since we're only interested in words
# 
# We are going to start by writing a function that will perform our cleaning tasks. This way, if we want to clean other data later on, it is easy to pass that data into this function.
# 
# ### The Code ###
# 
# The first thing we do is to tokenize our data. Tokenizing means we are separating the words in the data so that they get fed to the model individually rather than as sentences or paragraphs. Word embedding models work with individual words, so we use the `.split()` function to take a list that may look like this: 
# 
# ```python
# ["this is a string"]
# ```
# 
# into a list that looks like this:
# 
# ```python
# ["this", "is", "a", "string"]
# ```
# 
# The process of splitting a text into its individual words is called **tokenizing** and the individual words are called **tokens**. We will use the variable `tokens` to hold our tokenized data.
# 
# Then, we're going to make all of the words in our `tokens` list lowercase. We accomplish this using the built-in `.lower()` function and what is called **list comprehension**. List comprehension allows us to create a new list using what the computer understands about our old list. In the code block below, we run: 
# 
# ```python
#     t.lower() for t in tokens
# ```
# 
# This abbreviated `for` loop uses list comprehension to iterate through each item in `tokens` and applies the lower-casing function to each item `t` within the list `tokens`. We store the resulting list in the variable `tokens` which will overwrite the old `tokens` list.
# 
# Then, using the `re` library, which gives us access to regular expressions, we use list comprehension to iterate through each of the items in our new `tokens` list and substitute all instances of punctuation with an empty string, `''`,  which effectively removes the punctuation. We store this edited list in the `tokens` variable which will overwrite the old `tokens` variable just like before. We are using the `string.punctuation` constant that comes with the `string` library. You can read more about the constant in the [documentation](https://docs.python.org/3/library/string.html), including what marks are considered punctuation. 
# 
# Finally, we remove any items from our list that are not alphabetical characters (for instance, numbers and special characters) using list comprehension and the `isalpha()` function. The `isalpha()` function considers alphabetic characters to be those that the Unicode character database defines as "Letter." We overwrite the `tokens` variable one last time with our final version of the tokenized data and then return `tokens` which will give the rest of the code access to the tokenized text. You can read more about `isalpha()` in the [documentation](https://docs.python.org/3/library/stdtypes.html).
# 
# In the code block below, we define a function called `clean_text()` which accepts a list of texts, called `text` in the definition, as a parameter. By storing the code for cleaning our data within the function definition for `clean_text()`, we make the work that `clean_text()` represents available for use at a later point. The code within the function definition will only be executed once you call `clean_text()` with a list of texts as the parameter.

# In[ ]:


def clean_text(text):
    
    # Cleans the given text using regular expressions to split and lower-cased versions to create
    # a list of tokens for each text.
    # The function accepts a list of texts and returns a list of of lists of tokens


    # lower case
    tokens = text.split()
    tokens = [t.lower() for t in tokens]
    
    # remove punctuation
    re_punc = re.compile('[%s]' % re.escape(string.punctuation))
    tokens = [re_punc.sub('', token) for token in tokens] 
    
    # only include tokens that aren't numbers
    tokens = [token for token in tokens if token.isalpha()]
    return tokens


# Next, we are going to apply the function to our data. This code begins by initializing an empty list called `data_clean` which will hold the cleaned text. Then, using a `for` loop, the code walks through our `data` list from earlier and calls the `clean_text()` function on each item in that list and then adds the cleaned text to our `data_clean` list.

# In[ ]:


# clean text from folder of text files, stored in the data variable
data_clean = []
for x in data:
    data_clean.append(clean_text(x))


# It can be useful to just check that `data_clean` didn't miss any entries from `data`. You can do this by running a few `print()` statements to compare `data_clean` and `data`

# In[ ]:


# Check that the length of data and the length of data_clean are the same. Both numbers printed should be the same

print(len(data))
print(len(data_clean))


# You can also confirm that the transformation went as expected by checking the first and last items in both variables, as in the code cells below (note the differences in the results):

# In[ ]:


# check that the first item in data and the first item in data_clean are the same.
# both print statements should print the same word, with the data cleaning function applied in the second one

print(data[0].split()[0])
print(data_clean[0][0])


# In[ ]:


# check that the last item in data_clean and the last item in data are the same
# both print statements should print the same word, with the data cleaning function applied in the second one

print(data[0].split()[-1])
print(data_clean[0][-1])


# ### OPTIONAL: Apply `clean_text()` to a Dataframe
# 
# In order to apply `clean_text` to a dataframe, such as the dataframe that we stored our CSV data in earlier, all you have to do is run the code below.
# 
# This code tells the computer to go to the column titled `text` and apply the `clean_text()` function to each entry in that column. What is useful about working with text in a dataframe such as this, is that the dataframe will maintain columns and rows even when you are manipulating much of the data within. This structure can be useful for keeping your data formatted in a particular way or even for remembering which text your data was pulled from.

# In[ ]:


# clean text from dataframe

df['text'] = df['text'].apply(clean_text)


# ## Training the Model ##
# 
# Now we are going to move on to training our model. Word2Vec allows you to control a lot of how the training process works through parameters. Some of the parameters that may be of particular interest are:
# 
# 
# 
# - **Sentences** The `sentences` parameter is where you tell Word2Vec what data to train the model with. In our case, we are going to set this attribute to our cleaned textual data
# 
# 
# - **Min_count** (minimum count) The `min_count` parameter sets how many times a word has to appear in the dictionary in order for it to 'count' as a word in the model. The default value for mincount is 5. You will likely want to change this value depending on the size of your corpus.
# 
# 
# - **Window** The `window` parameter lets you set the size of the "window" that is sliding along the text. The default is 5, which means that the window will look at five words total at a time: 2 words before the target word, the target word, and then 2 words after the target word. The window attribute is important because word embedding models take the approach that you can tell the context of the word based on the company it keeps. The larger the window, the more words you are including in that calculation of context. Essentially, the window size impacts how far apart words are allowed to be and still be treated as relevant context.
# 
# 
# - **Workers** The `workers` parameter represents how many "worker" threads you want processing your text at a time. The default setting for this parameter is 3. This parameter is optional.
# 
# 
# - **Epochs** Like `workers`, the `epoch` parameter is an optional parameter. Basically, the number of epochs correlates to how many iterations over the text you want the model to be trained on. There is no rule for what number of epochs will work best. Generally, the more epochs you have the better, but sometimes too many epochs can actually decrease the quality of the model. You may wish to try a few settings with this parameter in order (for instance, 5, 10, and 100) to determine which will work best for your data.
# 
# 
# - **Sg** ("skip-gram") The `sg` parameter tells the computer what training algorithm to use. The options are CBOW (continuous bag of words) or skip-gram. In order to select CBOW, you set sg to the value 0 and in order to select skip-gram, you set the sg value to 1. The best choice of training algorithm really depends on what your data looks like.
# 
# 
# There are several other settings that you can adjust, but the ones above are the most crucial to understand. You can read about the additional attributes and their default settings at Gensim's creator [Radim Rehurek's website](https://radimrehurek.com/gensim/models/word2vec.html).

# ### The Code ###
# 
# In the code below, we start by initializing our model and saving it under the variable `model`. As you can see, we are using some of the parameters from above: `sentences`, `window`, `min_count`, and `workers`. The values of each of these parameters, save for the sentences parameter will likely have to be adjusted several times. There isn't a setting for each of these attributes that works for all cases—it really depends on what your text looks like. We recommend running this training call several times with varying settings in order to figure out what works best. It is also important to keep note of the settings for each time you train a model. The model will be different every time you train it, so keeping track of the changes you make each time will be very useful. 
# 
# In the second line, we save our model as `word2vec.model`. As you'll note, the file type that the model gets saved as in Python is a `.model` file as opposed to the `.bin` file you might be familiar with if you work in R. It is important to save the model each time you run the code because otherwise, the model will disappear with each run. It can be useful to give your model a better name than what we have above. For example, you might save the model with a distinctive name based on the dataset and parameters that will make recalling which model it is easier. 
# 
# The code below saves the model file to the "models" folder which is included with these notebooks. If you want to save your model to a specific folder you should provide the file path followed by the model name like so:
# 
# ```python
#     model.save("C:\users\admin\Documents\word2vec.model")
# ```
# 
# If you run the `save` call this way, the model will be saved as "word2vec.model" in the Documents folder.  

# In[ ]:


# train the model
model = Word2Vec(sentences=data_clean, window=5, min_count=3, workers=4, epochs=5, sg=1)

# save the model
model.save("./models/word2vec.model")


# To access the model once its been saved, you can run the code below. 
# 
# The code below loads a model file called "word2vec" and saves it in the variable `model`. Note that this code will look for a file called `word2vec.model` in the models folder. If you saved your model in a different folder or with a different name, you should provide the full file path followed by the model name (the same way you saved the model). If you wanted to load more than one model, then all you would need to do is save your second model under a new variable. For instance, instead of `model` you might use `model2`. You can load any number of models that you want as long as they each have a unique variable.

# In[ ]:


# load the model 

model = Word2Vec.load("./models/word2vec.model")


# ## Word2Vec Functions ##
# 
# Word2Vec has a number of built-in functions that are quite powerful. These functions allow us to ask the model questions about how it understands the text that we have provided it.
# 
# Let's walk through each of these function calls in order to understand what is happening in the code. 
# 
# The first step you always want to take when working with models, is to make sure that your model is loaded and stored within a variable for later use. We have already loaded our model above, but if you haven't already loaded your model, you should do so before proceeding.

# Now that we have our model loaded into the `model` variable, we can use it to start making some function calls. The way that you call functions with Word2Vec, is to preface each function call with `model.wv.` Here, `wv` stands for "word vectors." Essentially by calling `model.wv`, what we are really doing is telling the computer "hey, crack open this model and apply this function only to the word vectors inside."
# 
# The examples below demonstrate each of these function calls, using our demo model, which was trained on a set of recipes, with a set of terms chosen to illustrate what word embeddings can reveal about this corpus. 
# 
# For your own model, you'll want to change each of these function calls to better reflect the vocabulary that your model would have been exposed to. 
# 
# One important thing to remember is that the results you get from each of these function calls do not reflect words that are, say, _definitionally_ similar, but rather words that are used in the same **contexts**. This is an important distinction to keep in mind because while some of the words you'll get in your results are likely to be synonyms or to have similar definitions, you may have a few words in there that seem confusing. And, in fact, antonyms are often used in context with each other! Word embeddings guess the context of a word based on the words that often appear around it. Having a weird word appear in your results does not indicate necessarily that something is wrong with your model or corpus but rather may reflect that those words are used in the same way in your corpus. You should be careful to be as precise as possible when interpreting your results so that they aren't misunderstood. It always helps to go back to your corpus and get a better sense of how the language is actually used in your texts. 
# 
# ### The Code ###
# 
# First, if you want to check if a word is present in your vocabulary, you can use the `if` statement formulation below. Checking to see if a word is present in your vocabulary before running any other functions can be a useful first step.
# 

# In[ ]:


# set the word that we are checking for
word = "milk"

# if that word is in our vocabulary
if word in model.wv.key_to_index:
    
    # print a statement to let us know
    print("The word %s is in your model vocabulary" % word)

# otherwise, let us know that it isn't
else:
    print("%s is not in your model vocabulary" % word)


# **Most_similar**―this function allows you to retrieve words that similar to chosen word. In this case, I am asking for the top ten words in my corpus that are contextually similar to the word "milk." If you want a longer list, change the number assigned to `topn` to the number of items you want in your list. You can replace "milk" with any other term you want to investigate. 

# In[ ]:


# returns a list with the top ten words used in similar contexts to the word "milk"
model.wv.most_similar('milk', topn=10)


# You can also provide the `most_similar` function with slightly more specific information about your word(s) of interest. In the code block below, you'll notice that one word is tied to the `positive` parameter and the other is associated with `negative.` We'll talk more about what this means below but, in short, because vectors are numerical representations of words, you are able to perform mathematical equations with them such as adding words together or subtracting them. This call to `most_similar` will return a list of words that are most contextually similar to "recipe" but not the word "milk."
# 
# If you get an error message, go up and use the code above to make sure that the words you are searching are used in your corpus.
# 

# In[ ]:


# returns the top ten most similar words to "recipe" that are dissimilar from "milk"
model.wv.most_similar(positive = ["recipe"], negative=["milk"], topn=10)


# In[ ]:


# returns the top ten most similar words to both "recipe" and "milk"
model.wv.most_similar(positive = ["recipe", "milk"], topn=10)


# **Similarity**―this function will return a cosine similarity score for the two words you provide it. We'll get into cosine similarity below, but for now just know that the higher the cosine similarity, the more similar those words are
# 

# In[ ]:


# returns a cosine similarity score for the two words you provide
model.wv.similarity("milk", "cream")


# **Predict_output_word**―this function will predict the next word likely to appear in a set with the other words you provide. For instance, you could provide the function with a list of words that are essentially a sentence: `["I", "love", "pies"]` and the function would predict the words most likely to appear in this same sequence of context words. This function works by _inferring_ the vector of an unseen word. The output you get from this function is a set of words where the probability distribution of the center word given the context is calculated.

# In[ ]:


# returns a prediction for the other words in a set containing the words "flour," "eggs," and "cream"
model.predict_output_word([ "flour", "eggs", "cream"])


# 
# The last call that is useful to know, is the `model.wv` call. By typing `model.wv`, you get the vocabulary list for your model. You can also apply the `len()` function in order to see how long your vocabulary is. This is important information as it can lead you to decide that you should train your model on more data in order to expand this vocabulary and thus receive more nuanced results.

# In[ ]:


# displays the number of words in your model's vocabulary
print(len(model.wv))


# ### Cosine Similarity ###
# 
# The way that word embedding models understand words is through their numerical representation. A word **vector** is a numerical value that represents the positioning of a word in some multi-dimensional space. Because word vectors are located in this multi-dimensional space, just like we could perform basic math on words in the corpus, we can perform slightly more complicated math. 
# 
# A "vector" is not simply a point in space, but a point in space that has both _magnitude_ and _direction_. This means that vectors are less isolated points and more lines that trace a path from some origin point to that vector's designated position in what is called **vector space**.
# 
# Since a vector is really a line, that means when you are comparing two vectors from the same corpus, you are comparing two lines each of which shares an origin point. Since those two lines are already connected at the origin point, in order to figure out how similar those words are, all we need to do is to connect their designated position in vector space with an additional line. And what shape does that then form? A triangle. How far apart these two vectors are in vector space is calculated using the cosine of this new line, which is determined by subtracting the adjacent line by the hypotenuse.
# 
# You can calculate the cosine of an angle by completing the following trigonometric calculation: 
# 
#     cos(a) = b/c where b is vector 1 and c is vector 2
# 
# The larger this number is, the closer those two vectors are in vector space and thus, the more similar they are. Generally, a cosine similarity score above 0.5 tends to indicate a degree of similarity that would be considered significant. 
# 
# In order to get a cosine similarity for two words, you can use the `similarity()` function like below.

# In[ ]:


# returns a cosine similarity score for the two words you provide
model.wv.similarity("milk", "cream")


# ### Vector Math ###
# 
# Because word vectors represent natural language numerically, this means that it is possible to perform mathematical equations with them. For example, say you wanted to know what words in your corpus reflect this equation:
# 
#     king - man = ?
# 
# As humans, we can predict that the top word which would result from this equation would be "queen" or "princess" or even "dowager." However, because computers don't understand natural language, the computer will perform the equation by subtracting the vector for "man" from the vector for "king." What may result is a list of words that you may not expect, but reveals interesting patterns in how those words are used in your corpus.
# 
# Vector math also allows you to make your function queries much more precise. Let's say for example that you wanted to ask your corpus the following question: "how do people in nineteenth-century novels use the word 'bread' when they aren't referring to food?" 
#  
# The equation that you might use to ask your corpus of nineteenth-century novels that exact question might be:
# 
#     bread - food = ?
# 
# Or to be even more precise, what if you wanted to ask "how do people talk about bread in kitchens when they aren't referring to food?" That equation may look like:
# 
#     bread + kitchen - food = ?
# 
# In Python, the syntax for making these sorts of calls, is to use the "positive" attribute in place of the plus sign and the "negative" attribute in place of the minus sign. So, the above equation would look like this in Python:
# 

# In[ ]:


# returns return a list of 10 words that are most similar in context to bread + kitchen
# with the concept of "food" removed.
model.wv.most_similar(positive = ["bread", "kitchen"], negative = ["food"], topn=10)


# ## Evaluating a Model ##
# 
# Now that we have a working model and have explored some of its functionality, it is important to evaluate the model. When I say _evaluate_ what I mean is: Does the model respond well to the queries it should? Is the model making obvious mistakes?
# 
# In order to evaluate our model, we are going to present it with a series of words that are clearly similar and which should be present in most corpuses. Then, we will calculate the cosine similarity for each of these pairs of words, and save the results in a .csv file. This way, we will be able to review each of the cosine similarities and determine if the model is making obvious mistakes. 

# ### The Code ###
# 
# We're going to start by declaring a few variables. First, we declare the variable `dirpath` which will hold the file path to your model. This file path can be a folder where you are saving your `.model` files or even your current working directory. This variable tells the computer to only pay attention to files that end with `.model`, so your model doesn't necessarily need to be isolated in its own folder. 

# In[ ]:


dirpath = Path(r"./models/").glob('*.model') #current directory plus only files that end in 'model' 
files = dirpath
model_list = [] # a list to hold the actual models
model_filenames = []  # the filepath for the models so we know where they came from


# Then, we set the variable `files` equal to our file path. Next, we declare two empty lists, `model_list` and `model_filenames`. `model_list` will hold the actual models themselves, and `model_filenames` will hold the filename of the model so that we know which model is producing which results. This way, you can run this code on a folder with many models and get evaluation information for each of them. 
# 
# This for loop traverses through the `files` variable which holds all of the files from our file path that end with `.model`. Then, for each of these files, the filename is converted to a string and added to our `file_path` list. Then, the model itself is loaded using `Word2Vec.load()`, and it is added to our list of models.
# 
# If the code is working, you should see a list of filenames printed as the for loop runs. If this does not happen, double check the directory path you set for `dirpath`.

# In[ ]:


#this for loop looks for files that end with ".model" loads them, and then adds those to a list
for filename in files:
    # turn the filename into a string and save it to "file_path"
    file_path = str(filename)
    print(file_path)
    # load the model with the file_path
    model = Word2Vec.load(file_path)
    # add the model to our mode_list
    model_list.append(model)
    # add the filepath to the model_filenames list
    model_filenames.append(file_path)


# We are going to be using a list of tuples, which in this case just means pairings of words stored in a single variable, to query our models. If these words have some clear similarities and typically shared contexts. If the recipe model is working like it should, the cosine similarities for these words should be relatively high.
# 
# Please note that the words have to be present in the vocabulary of all of the models you are testing in order for the code to work. This is because the function will essentially grab the cosine similarities for each word pair and if either of the words in the pair doesn't exist in the model, the function will produce an error. 
# 
# Below, you will find the function we used above for checking if a word is in our vocabulary. It is a good idea to check whether or not each of the words you wil use to evaluate your models exists in their vocabularies before running the rest of the code. 

# In[ ]:


# set the word that we are checking for
word = "milk"

# if that word is in our vocabulary
if word in model.wv.key_to_index:
    
    # print a statement to let us know
    print("The word %s is in your model vocabulary" % word)

# otherwise, let us know that it isn't
else:
    print("%s is not in your model vocabulary" % word)


# Below, we declare a variable, `test_words`, which will contain a list of our word pairs. If you are using the recipe data set, then each of these words should be present in the vocabulary.

# In[ ]:


#test word pairs that we are going to use to evaluate the models
test_words = [("stir", "whisk"),
             ("cream", "milk"),
             ("cake", "muffin"),
             ("jam", "jelly"),
             ("reserve", "save"),
             ("bake", "cook")]


# If you are using a different model, for example a model trained on novels or some other corpus which is less likely to have a limited and subject-specific vocabulary, your list of tuples might look like the following:

# ```python
# #test word pairs that we are going to use to evaluate the models
# test_words = [("away", "off"),
#             ("before", "after"),            
#             ("children", "parents"),
#             ("come", "go"),
#             ("day", "night"),
#             ("first", "second"),
#             ("good", "bad"),
#             ("last", "first"),
#             ("kind", "sort"),
#             ("leave", "quit"),
#             ("life", "death"),
#             ("girl", "boy"),
#             ("little", "small")]
# ```

# Now, we're going to start feeding our list of tuples into a `for` loop which will open each model one at a time and get the similarity score for each tuple in the list. We initialize a dataframe called `evaluation results` which contains the columns "Model," "Test Words," and "Cosine Similarity." With these columns, we'll be able to keep track of which model is producing which cosine similarities and for which tuples. The nested `for` loop moves in this way until each model has calculated the cosine similarity score for each tuple. Then, the results are appended one at a time a temporary dataframe and finally added to our `evaluation_results` dataframe. 
# 
# Using the pandas function `to_csv()`, we save the `evaluation_results` dataframe as a `.csv` file titled `word2vec_model_evaluation`. This `.csv` file will contain the results for each model. 
# 
# This evaluation method will allow you to determine which of your models is performing the best. The results of this evaluation may also indicate that your corpus should be varied slightly or should include more data. 

# In[ ]:


# these for loops will go through each list, the test word list and the models list, 
# and will run all the words through each model
# then the results will be added to a dataframe

# since NumPy 19.0, sometimes working with arrays of conflicting dimensions will throw a deprecation warning
# this warning does not impact the code or the results, so we're going to filter it out
# you can also specify "dtype=object" on the resulting array
# np.warnings.filterwarnings('ignore', category=np.VisibleDeprecationWarning)

# create an empty dataframe with the column headings we need
evaluation_results = pd.DataFrame(columns=['Model', 'Test Words', 'Cosine Similarity'], dtype=object)

# iterate though the model_list
for i in range(len(model_list)):
    
    # for each model in model_list, test the tuple pairs
    for x in range(len(test_words)):
        
        # calculate the similarity score for each tuple
        similarity_score = model_list[i].wv.similarity(*test_words[x])
        
        # create a temporary dataframe with the test results
        df = [model_filenames[i], test_words[x], similarity_score]
        
        # add the temporary dataframe to our final dataframe
        evaluation_results.loc[x] = df

# save the evaluation_results dataframe as a .csv called "word2vec_model_evaluation.csv" in the "data" folder
# if you want the .csv saved somewhere specific, include the filepath in the .to_csv() call
evaluation_results.to_csv('./output/word2vec_model_evaluation.csv')


# Since Word2Vec is an **unsupervised** algorithm—meaning the model draws its own conclusions about the data you provide—evaluation is an important step in testing the validity of the model. However, there is no clear-cut way to evaluate a model. While the method described above will help you determine if the model is making obvious mistakes, there are much more precise and detailed methods for conducting a model evaluation. For example, a popular method for evaluating a Word2Vec model is using the built in `evaluate_word_analogies()` function to evaluate syntactic analogies. You can also evaluate word pairs using the built in function `evaluate_word_pairs()` which comes with a default dataset of word pairs. You can read more about evaluating a model on [Gensim's documentation website](https://radimrehurek.com/gensim/auto_examples/tutorials/run_word2vec.html#evaluating).
# 
# Check out the next notebook on [visualizing word embedding data](word2vec-visualization.ipynb).

# 
# _This walkthrough was written on June 25, 2022 using Python 3.8.3, Gensim 4.2.0, and Scikit-learn 0.23.1_
