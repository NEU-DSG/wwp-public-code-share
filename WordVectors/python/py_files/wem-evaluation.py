#!/usr/bin/env python
# coding: utf-8

# # Evaluation Guide for Word Embedding Models

# _Written By Avery Blankenship_

# One of the more opaque aspects of working with word embedding models is figuring out how to tell if the model is actually working. Let's say you've trained a word embedding model on a set of early modern texts and you query the model a couple of times for words most similar to some keywords you are interested in. When you query the model using the terms you've selected, the words that are returned by the model as the most similar all make sense to you and align with your own understanding of the corpus that was used to train the model. Surely that must mean that the model works and behaves just the way you want it to, right? Not necessarily. 
# 
# Querying the model at random with a handful of terms doesn't really tell us how well the model performs broadly, but only demonstrates the model's performance with those particular query terms—it also doesn't tell us anything about how important those query terms are to the model's vocabulary. You could query the model using terms that you would anticipate to be fairly representative of the corpus only to discover that those terms actually play a minimal role or may not even be in the model's vocabulary in the first place.
# 
# To more effectively evaluate the model's performance, you would need for there to be many more query terms *and* for the terms to represent, broadly, some phenomenon that you are attempting to capture with the model. For this reason, testing your model's performance using a formalized evaluation method can help you better determine how well the model works across a broad spectrum of query terms and related concepts in a systemized way.
# 
# The evaluation method described in this notebook is a modification of a standard evaluation task which has been adjusted to better suit the evaluation of models trained on pre-twentieth century texts. The goals of this notebook are to:
# 
# - Outline the general process of model evaluation
# - Introduce some of the more standard methods of model evaluation that you are likely to come across in word embedding documentation and scholarly work on word embedding models
# - Walk through a modified evaluation task that has been developed by the WWP
# - Explain how to adapt the WWP evaluation method to your own corpus
# 
# To be clear, there is no single right or wrong way to evaluate word embedding models, which is one of the many reasons why evaluation is such a difficult and often confusing part of the model building process. Word embedding models are difficult to evaluate because *language* is difficult to evaluate and thus what is presented in this notebook is not the most authoritative or most correct way to evaluate models, but is rather one potential method for model evaluation among many.
# 
# For a longer and more theoretically-contextualized discussion of model evaluation, see “[Word Vector Model Evaluation](https://www.wwp.northeastern.edu/outreach/seminars/_current/handouts/word_vectors/evaluation.html)” by Avery Blankenship.

# ## What is Model Evaluation?

# So what do we mean, exactly, when we say we're going to "evaluate" a model? As the name implies, model evaluation is just a fancy way of asking "does the model work like it's supposed to?" In general, the evaluation process follows some series of benchmarks which you set, and if the model meets these benchmarks, then the model is considered to have "passed" the evaluation process. As you can guess, because this process is intentionally flexible, there are a number of ways that you can approach evaluating whether or not the model performs the way it is supposed to. In any case, following some type of formalized process is an important step in building and using word embedding models, and this evaluation can affect how the model performs (and how you understand that performance) significantly. 
# 
# Because word embedding models are trained using an unsupervised method (meaning they learn and model the behavior of whateaver corpus you provide them on their own), we can't crack open the hood and look inside. For this reason, evaluation is best thought of not as a definitive answer for whether or not a model performs well and more like our best, most informed, guess about what might *show* us that behavior. Instead of opening up the hood and looking inside, we do our best to recreate what's inside having only seen the individual parts—but not how they're assembled. Using some kind of evaluation *process* provides a roadmap for glimpsing what's under the hood and overall provides some structure for determining whether or not a model behaves as expected. 
# 
# In short, model evaluation is a stage in the model building process where you test whether or not the model performs as expected and an evaluation process is the method for doing so. 

# ## Methods of Evaluation

# There are two primary methods which are typically used to evaluate word embedding models. These methods were proposed alongside the release of Word2Vec by Mikolov et al. 2013 and are also described in the Word2Vec [documention](https://radimrehurek.com/gensim/models/word2vec.html). We are going to be using an adapted version of one of these methods, but it is useful to know how both work in order to better understand the Word2Vec documentation and to understand how other researchers may evaluate their models. 
# 
# The first method, what we'll refer to as the *survey task*, involves generating word pairs that you would anticipate to be related in some way and then querying both the model and a group of people to see how alike the cosine similarities assigned by both groups are to one another. You begin by selecting a set of word pairings that are either strongly related or even completely unrelated—the goal here is that the cosine similarities generated by either option won't fall in the mid-range and thus be less conclusive. A group of survey-takers assign a cosine similarity to those word pairs (for example, a closely related pair of words might have 0.9 as a similarity). The survey results are then averaged and compared to the cosine similarities that the model generates given the same set of word pairings. 
# 
# There are a number of potential problems when it comes to using this method to evaluate models trained on pre-twentieth-century texts. Namely, that if the corpus represents text across a broad timeline, language can change—sometimes even dramatically—and differ from modern uses of the same word or phrases. The meanings of words when presented to a modern reader may not be in line with the way that same words were used in the texts used to train the model. This is a potential issue that can be accounted for in selecting the word pairs for testing to begin with, but there is a large potential for error and the method requires that the survey-takers share an understanding of the model’s vocabulary. There is also little documentation to support how large this group of survey takers should be in order to produce meaningful results and since the survey takers would be assigning similarity scores based on personal assessment, these scores may have little to do with the cosine similarities produced by the model.
# 
# The second method of model evaluation, and what we will be modifying in this notebook, is colloquially referred to as the *analogy task* by computer scientists and computational linguists. Note that the task isn’t necessarily restricted to solving analogies and is more about attempting to connect and compare words in a corpus. This method tests words which share a close relationship (which can *sometimes* involve analogies, hence the name) and evaluates how well the model understands these relationships based on their closeness in vector space. 
# 
# The words are given to the model in sets (for example, `London is to England as Paris is to ?`) and the model is then asked to “solve” the analogy task by choosing the most appropriate word to fill in the blank. The model accomplishes this task by assuming that words `a`, `b`, `c`, and `d` share a relationship with one another and thus will be close to one another in vector space such that `a-b = c-d`. The model “solves” this equation for `d` by using the vectors for each word. That is, solving the equation for `d` provides the vector for the missing word. For instance, if we know that `a` and `b` are closely related to one another and that `a`, `b`, `c`, and `d` belong to the same cluster of vectors, then we can determine what word `d` *could* be by locating a word in vector space that is a similar distance from word `c` as word `b` is to `a`. Importantly, the model isn't definitively determining what `d` is, but more so making an educated guess.
# 
# This method of evaluation introduces slightly more complexity than a single set of word pairings (for example, “milk, cream” or “breakfast, dinner”). However, a major limitation of the method is that it assumes that words can have only one relationship to other words. For example, “sofa” might have a relationship to “living room,” but it is also highly likely that it has the same relationship, or may be just as close in vector space, to “den” or “sitting room” or “parlor.” If “living room,” “den,” “sitting room,” and “parlor” are all acceptable words to stand in for word `d`, then how can we ensure that any of these words can pass the evaluation task?
# 

# ### The BATS Analogy Task

# In order to account for the fact that words can, and often do, have similar relationships with more than one word, the research team Vecto has proposed a modification of the analogy test called the [BATS](https://vecto.space/projects/BATS/) method. The BATS method addresses two major issues in the typical analogy task. By far, the most popular data set for conducting the analogy task is the [Google Analogy Test Set](https://aclweb.org/aclwiki/Google_analogy_test_set_(State_of_the_art)) which was developed by Mikolov et al. (2013), the same group to develop Word2Vec. The Google set is broadly used to evaluate word embedding model performance and is also the recommended testing set described in the [Gensim](https://radimrehurek.com/gensim/) documentation. 
# 
# The first major issue with the Google data set is that it is highly unbalanced. Of the 19,544 question pairs within the set, 56.72% of the pairs are country capitals. As you can imagine, the Google data set doesn't make for an appealing testing set for those who study pre-twentieth-century texts as many of these capitals, and even countries, didn't *exist* yet. Based on the content distribution alone, the Google set is poorly equipped to evaluate a model trained on these earlier texts. The BATS method provides much more balanced data across a broader range of categories than the Google set.
# 
# The second major issue with the Google data set is that it uses a *one ring to rule them all* approach to language. The data set assumes that words share a 1:1 relationship when in fact, any given word can have many relationships to many words. Human language is inherently relational—it's the basis for using word embedding models to study language in the first place—so reducing this relational nature to a very linear path (`a is to b as c is to d`) doesn't capture much of the complexity of language. An evaluation task designed only to account for these linear relationships is similarity limited. Particularly for analyzing works of literature, the ability to handle complexity is crucial. The BATS method proposes a data structure that allows words to share relationships with multiple words.
# 
# Nevertheless, the word pairings provided by the BATS team for the purposes of plug-and-play evaluation may not match actual language usage in the corpus you are working with. For this reason, the Women Writers Project has developed a set of word pairings modeled on the BATS data set that are intended to more closely represent language usage in pre-twentieth century English-language print texts. While these sets of words are not perfect and do not reflect all possible language usage across such a wide timeline, the method described here can provide a framework if you are interested in creating your own set of word pairs with which to test a model—or even sets of models. The methods we used for compiling these word pairings and using them in an evaluation task are described in this notebook.

# ## Model Evaluation Walkthrough

# ### Building Word Pairs to Test

# The words used in the WWP’s testing set were obtained by training a WEM on the [Women Writers Online](https://www.wwp.northeastern.edu/wwo/), [Visualizing English Print Early Modern 1080](https://graphics.cs.wisc.edu/WP/vep/vep-early-modern-1080/), [ECCO–TCP](https://textcreationpartnership.org/tcp-texts/ecco-tcp-eighteenth-century-collections-online/), [Victorian Women Writers Project](https://webapp1.dlib.indiana.edu/vwwp/welcome.do;jsessionid=78A4F695BB5C7A7B07CF00185F7D9D27), [DocSouth's North American Slave Narratives](https://docsouth.unc.edu/neh/), and the [Wright American Fiction](https://webapp1.dlib.indiana.edu/TEIgeneral/welcome.do?brand=wright) texts. The corpora were selected both because of the lack of OCR noise (most of the texts are transcribed) and for their wide representation of genres across the timeframe of interest. The resulting model was made up of all text from each of these collections. In addition to training a word embedding model on the text, we also counted the top one thousand most frequently used words across the entire corpus, not including stopwords. These one thousand words were chosen so that we could make sure to select words for evaluation which are significantly present in the model’s corpus.
# 
# Below is the code that was used to develop this list of words and to train the word embedding model.
# 
# First, we import the necessary libraries and packages:

# In[ ]:


# =============================================================================
# LIBRARY AND PACKAGE IMPORTS 
# =============================================================================

import re                                   # for regular expressions
import os                                   # to look up operating system-based info
import string                               # to do fancy things with strings
import glob                                 # to locate a specific file type
from pathlib import Path                    # to access files in other directories   
import pandas as pd                         # to sort and organize data
import nltk                                 # to access stop words
from collections import Counter             # for word counts
from nltk.corpus import stopwords           # import set of stop words
from nltk.tokenize import word_tokenize     # lets us tokenize
import csv                                  # lets us read and write CSVs


# If you don't already have the nltk sets of stopwords and punctuation downloaded on your computer, you can do so by running the code below:

# In[ ]:


nltk.download('stopwords')                  
nltk.download('punkt')


# The code below loops through a directory of plain text files, extracts the text from each file, cleans the text (removes stopwords, punctuation, numbers, etc.), and then counts the most frequently occurring words. While we generated a list of the top one thousand most common words, the code below will generate the top thirty most common words and the top thirty least common words in your corpus to give you a basic starting point. You can change this number to whatever number you would like (as long as the number doesn't exceed the number of words in your corpus). 
# 
# Importantly, this version of our source texts (stopwords removed) is *not* what was used to train the word embedding model. This code is *only* for generating word counts in the corpus (which is why the stopword were removed here). For training the word embedding model, you would want the stopwords to remain, since stopwords help to identify the relationships between words in a sentence. For more information on training word embedding models, please see the WWP's [Word2Vec Fundamentals](https://github.com/NEU-DSG/wwp-public-code-share/blob/main/WordVectors/python/word2vec-fundamentals.ipynb) walkthrough.
# 
# To run the code below, make sure to change the filepaths for both the input folder and the destination for the CSV with your word counts. 

# In[ ]:


# =============================================================================
# LOOP THROUGH FOLDER OF CORPORA TO GET LIST OF FILENAMES AND PATHS
# =============================================================================

dirpath = r'FILE PATH TO FOLDER OF CORPORA' # get file path for corpora (you should change this)


file_type = ".txt" # if your data is not in a plain text format, you can change this
filenames = []  # this variable will hold the locations of each file

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


# =============================================================================
# LOOP TO OPEN ONE FILE AT A TIME, CLEAN TEXT, AND COUNT WORDS
# =============================================================================

temp_count = ["test_word"]   # initiate a list to aggregate word counts in
counted_words = Counter(temp_count) # count this iniital list



# this for loop then goes through the list of files, reads them, cleans those words and removes stop words, and then counts frequencies
# crawls through the data one file at a time to preserve memory
for filename in filenames:
    
    with open(filename, encoding='utf-8') as afile: # open the first file in the set of corpora
        data = afile.read()
    
        print("opening " + filename) # print statement to let you know the file was successfully opened
        stop_words = set(stopwords.words('english')) # setting the stopwords we want to remove
        
        # this function cleans the text and removes stop words
        def clean_text(text):       
            # lower case
            tokens = text.split()
            tokens = [t.lower() for t in tokens]
    
            # remove punctuation
            re_punc = re.compile('[%s]' % re.escape(string.punctuation))
            tokens = [re_punc.sub('', token) for token in tokens]
    
            # only include tokens that aren't numbers
            tokens = [token for token in tokens if token.isalpha()]
            
            # remove stop words
            tokens = [w for w in tokens if not w in stop_words]
            
            # return the cleaned text
            return tokens
        
        
        # run the function on our current file
        data_clean = clean_text(data)
        print(filename + " has been cleaned")  # print statement letting you know that the file was successfully cleaned
        
        new_count = Counter(data_clean) # count the word frequencies in the current file
        counted_words.update(new_count) # update our aggregated count with the new file
        
        # get the top thirty most common words in the aggregated set
        top_words = counted_words.most_common(30)
        
        # get the least common thirty words in the aggregated set
        least_common = counted_words.most_common()[:-30-1:-1]
        
        # open a csv file where we can save our word counts
        # the csv file will update every time the code loops through a new file in case python runs into memory issues
        # update the line below with the file path where you want your CSV to go
        with open(r'~FILE PATH TO PUT CSV FILE IN~/CSV_FILE_NAME.CSV', 'w', encoding='utf-8') as counted_file:
            c = csv.writer(counted_file)
            # write the word counts to the csv with the headers Top 30 Words and 30 Least Common
            c.writerows([['Top 30 Words', '30 Least Common'], [top_words, least_common]])
                        
            print("CSV File Updated") # print statement to let you know that the csv file was successfully updated
       
        # we want to also save the cleaned text to a text file for later
        text_file = open("all_text_clean.txt", "a", encoding="utf-8")
        n = text_file.write(str(data_clean))
        print(filename + " saved to .txt file") # print statement to let you know that the text has been saved to a .txt file
        text_file.close() # close the text file
            
        # close the file we have open currently
        # this is important for saving memory
        afile.close()


# Alternatively, if your corpus text is formatted as a csv file, you can use the code below to accomplish the same thing. Feel free to skip this block if you are not working with a csv file. Update both file paths before you run the code. 

# In[ ]:


# =============================================================================
# 
#  TO OPEN TEXT FILE OF CLEANED TEXT AND CSV FILE OF COUNTS
# =============================================================================

open the file with the cleaned text saved to it
    filename = r"FILE PATH TO TEXT FILE OF CLEANED TEXT"
    with open(filename, encoding ='utf-8') as afile:
        cleaned_text = afile.read()


filename = r"FILE PATH TO CSV FILE"
with open(filename, newline='') as csvfile:
    word_counts = csv.reader(csvfile, delimiter=',')


counted_words = Counter(data_file)
top_words = counted_words.most_common(30) # 30 most common
least_common = counted_words.most_common()[:-30-1:-1] # 30 least common


# Once the top one thousand most commonly used words were obtained from our multi-collection corpus, the terms were reviewed by WWP staff in order to select words we considered to be significant within the context of the corpus or to represent concepts we considered to be important to the time period. Specific place names were, for the most part, not included in the final set of words primarily because we wanted the set of testing words to be generalizable and useful across a broad spectrum of pre-twentieth century texts rather than couched in specific geographic locations. Of course, these choices reflect the WWP team’s perspectives, but we focused our efforts on thinking broadly and were able to bring in period-specific expertise from many years of working with pre-Victorian women’s texts.  
# 
# The final number of words used for generating pairings was 500. In order to get a starting sense of which word pairings might be the most generative, we queried a word embedding model that we trained on the combined corpus for the most similar words to each of the 500 words. We then reviewed the most similar words generated by the model and selected words which we thought to accurately represent a close relationship to one another. In some cases, we supplemented the word pairings with other words we thought significantly represented some concept or idea, using the most similar words generated by the model as a guide. 
# 
# We chose to follow this workflow for two reasons. First, by selecting words which we already knew the model thought had close relationships, we could more accurately test how the evaluation code itself performed, especially when supplemented with additional words we identified. Second, these are words which we knew were widely represented within the model’s vocabulary. It would be less useful to evaluate words which are uncommonly present in the model’s vocabulary since the purpose of this evaluation is to test how well the model understands the language of the corpus it is trained on. Cosine similarity scores are the primary mode described here for evaluating the model’s understanding of concepts because distances between embedded word vectors are semantically meaningful. 
# 
# If you wish to generate your own word pairings, ideally you would train a model on a corpus that is not the same as the corpus and model you are ultimately attempting to evaluate to help develop those pairings. Why not use the same corpus? For example, let’s say you select the word “king” as a testing word and you query your model to see which words might make a good pair with your testing word. You determine that since the model gives the word “power” a high cosine similarity score with the word “king,” you should test these words as a pair. You run the evaluation code on this word pairing to discover that the cosine similarity of these words is high, which means the model is successfully understanding the connection between the two, right? Not necessarily. If you only select word pairings based on the top most frequently used words and words which share a high cosine similarity score with these words, you aren’t actually testing your model in a true sense—you can’t test the model if you pull all the “answers” to the test from the model itself. For this reason, we recommend either training a model with a different selection of comparable texts in order to generate your own word pairings or following a similar methodology of producing a related corpus so that your evaluation is more accurate.
# 
# The selected word pairings in the BATS analogy test are formatted in the following manner: 
# 
# ```
# : rooms
# sofa	living-room/parlor/sitting-room
# table	kitchen/dining-room
# ```
# 
# The first line `: rooms` describes the category for this particular set of words. Each line that follows contains a single query word followed by a tab and then the set of words which are acceptable pairs for the query word. These word pairings are saved in a plain text, machine-readable format (.txt). You don't have to necessarily categorize every pairing you come up with into their own text file, and indeed the WWP list of word pairings is itself a single file. However, categorizing the pairings may help you both isolate specific phenomena you want to evaluate as well as to represent different kinds of relationships a particular word may have. For example, the word "sofa" may be related to rooms in the house, but may also be related to other furniture. This approach may also help you to organize your own process of determining word pairings to test
# 
# It is also possible to combine this set of word pairings with some of the pairings developed by the BATS team. In particular, the morphological pairings developed by the team may be of use in addition to the WWP’s pairings, which represent semantic relationships. If the grammar of your corpus is unique, you may also wish to develop your own sets based on this grammatical structure.

# ### Running the Evaluation Code

# The code used for conducting the actual evaluation of the model is adapted from the [IceBATS](http://embeddings.arnastofnun.is/#About) project, a team of researchers who have worked to develop an Icelandic version of the BATS analogy test and have also released the relevant code for conducting this analysis. The IceBATS code accepts plain text files with a testing word/query word, followed by the acceptable pairings for the testing word. 
# 
# We made very slight modifications to the [evaluation code](https://github.com/stofnun-arna-magnussonar/ordgreypingar_embeddings/blob/main/word2vec/test_analogies.py) released by the IceBATS team to only allow the multiple answers, BATS format for word pairing testing rather than allowing both the multiple answer format as well as the A:B as C:D format. Primarily, we made this decision based on the determination that single-answer analogy testing has many of the limitations listed above and we wanted to prioritize only one type of evaluation as a result. For those interested in the single answer, `A:B as C:D` analogy testing, the built-in [evaluation function](https://radimrehurek.com/gensim/auto_examples/tutorials/run_word2vec.html#evaluating) that comes with Word2Vec is capable of evaluating models based on this formatting without any additional code necessary. For those interested in testing other word embedding algorithms, the IceBATS team has also released alternate versions of the evaluation code which can be accessed on the team’s [Github repository](https://github.com/stofnun-arna-magnussonar/ordgreypingar_embeddings/tree/main).
# 
# When the evaluation code is run, both the number of words in the testing set which were not in the model’s vocabulary as well as the final accuracy score for the model are provided. Because the code allows for words which are not part of the model’s vocabulary to be included in the evaluation (that is, the evaluation doesn’t stop when the code hits a word not in the vocabulary), this means that you don’t necessarily need to verify and validate each word that you decide to include in the word pairings for testing, although this might be a step of some interest to you depending on the evaluation goals of the research project as well as the number of words that the evaluation code determines are not in the vocabulary. 
# 
# It is important to note that the code below requires that rather than providing the entire word embedding model, instead just the vectors are given to the function. By using only the vectors and not the entire model, the code is much more memory efficient and faster. For a guide to saving the vectors from a word embedding model, please see the WWP's [Further Explorations](https://github.com/NEU-DSG/wwp-public-code-share/blob/main/WordVectors/python/further-explorations.ipynb) tutorial for word embedding models.
# 
# The code below evaluates a sample model trained on the corpus of [Women Writers Online](https://www.wwp.northeastern.edu/wwo/texts/titleURLs.html) texts; to evaluate your own model flie, update the `model_path` variable.

# In[4]:


"""
  Copyright [2021] [Stofnun Árna Magnússonar í íslenskum fræðum]
  
  Github located at: https://github.com/stofnun-arna-magnussonar/ordgreypingar_embeddings/blob/main/README.md

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
   
   *******************************
   Changes to the code were made to remove the b and c variables and their accompanying dependencies
   The current version of the code accepts analogies formatted with a root word and multiple answers
   to the analogy question
   *******************************
   
   
"""
# Make sure to update the two file paths below
import itertools as it
from gensim.models import Word2Vec
from gensim.models import KeyedVectors
from progress.bar import IncrementalBar
import sys

# The path to the full word vector model, in this case a model trained on the Women Writers Online corpus
model_path = r"models/wwo-demo.model"
# The path to the tab-separated text file with word pairs for testing
analogies = r"testing/analogies_test.txt"
# The path to use for the saved word vectors files
vectors = r"models/wwo-demo.wv"

# Load the word vector model and save its vectors separately
model = Word2Vec.load(model_path)
model.wv.save(vectors)


# Define a function for evaluating word vectors
def evaluate_word_analogies_mod(analogies, vectors):

    print('Starting analogy evaluations using %s. Loading model...' % analogies)
    language_model = KeyedVectors.load(vectors)

    ok_keys = language_model.index_to_key 

    ok_vocab = {k.upper(): language_model.get_index(k) for k in reversed(ok_keys)} # the vocabulary of the model
    oov = 0
    quadruplets_no = 0

    sections, section = [], None

    with open(analogies, encoding='utf8') as analogs:
        filebar = IncrementalBar('Performing analogy evaluations', max = 24510)
        for line in analogs:
            if line.startswith(': '): # the subcategories are separated here
                name_section = line.split(':')[1]
                if section:
                    sections.append(section)
                section = {'section': line.lstrip(': ').strip(), 'correct': [], 'incorrect': []}
            
            else:    
                a, expected = [word.upper() for word in line.split()] # convert all words to uppercase to avoid case variations

                a = [a]
                
                expected = expected.split('/')

                combo = list(it.product(a, expected)) # all possible quadruple combinations 
                quadruplets_no += 1 
                filebar.next()
                sys.stdout.flush()
                not_ok = 0 # the quadruple contains an OOV word
                right = False
                for i in combo:
                    a, expected = i
                    if len(a) > 0 and len(expected) > 0: # don't include quadruples containing an empty string
                        if a not in ok_vocab or expected not in ok_vocab:
                            not_ok += 1
                        else:
                            original_key_to_index = language_model.key_to_index
                            language_model.key_to_index = ok_vocab
                            predicted = None

                            sims = language_model.most_similar(positive=[a], topn=15, restrict_vocab=3000000000) # the restrict_vocab is an arbitrary high number
                            language_model.key_to_index = original_key_to_index
                            for element in sims:
                                predicted = element[0].upper() 
                                if predicted in ok_vocab:
                                    if predicted == expected:
                                        right = True
                
                    if right:
                        break
                if len(combo) == not_ok: # if the number of possible combinations is the same as the quadruples containing OOV words, the question is void
                    oov += 1   
                    # print(line.rstrip()) # if desired, print out the analogy questions containing OOV words
                if right:
                    section['correct'].append((a, expected))
                else:
                    section['incorrect'].append((a, expected))
        
        if section:
            sections.append(section)
            
    total = 0
    total_correct = 0
    filebar.finish()
    for section in sections:
        correct, incorrect = len(section['correct']), len(section['incorrect'])
        if correct + incorrect == 0: # avoid dividing by zero
            score = 0
        else:
            score = correct / (correct + incorrect)
        
        subcat_score = list(section.items())[0], score, correct,"/",(correct + incorrect)
        print(subcat_score)
        
        total += (correct+incorrect)
        total_correct += correct    
    
    oov_ratio = oov/ quadruplets_no         
    print('Out Of Vocabulary rate: ', oov_ratio)

    total_score = total_correct/total
    print('Total category score: ', total_score)

    return total_score


if __name__ == "__main__":
    pass


# In[ ]:


# Run this code to use the model evaluation function you just defined
evaluate_word_analogies_mod(analogies, vectors)


# ## Final Thoughts

# Model evaluation remains one aspect of WEM research that researchers can’t quite hammer down into a definitive method. There are a number of approaches to evaluating the ability of a model to understand the vocabulary of a corpus and much of the process of evaluating a model depends greatly on what you consider “understand the vocabulary” to mean. For some projects, “understand” can mean more a structural, grammatical understanding. For others, “understand” may mean a clear and consistent scoring of concepts or specific terminology. Depending on what your evaluation needs are, evaluation methods and tasks should be modified to best answer the types of questions you are interested in answering.
# 
# Evaluation of word embedding models is an important, though often intimidating, part of the word embedding model building process. There is no “right” or “wrong” way to evaluate models, as model evaluation should be tailored to suit the goals of the research project. For many projects, the goal of evaluation is to test how well the model understands the language of the corpus. For other projects, the goal of evaluation may be to test how well the model understands the grammatical structure of a corpus’s text. Another goal of evaluation may be to test how well the model replicates bias in the corpus. No matter what the end goal of evaluation may be for your particular project, evaluation helps us take a step back from our models in order to ask both the models and ourselves how well some phenomenon is captured by our word embeddings. 
