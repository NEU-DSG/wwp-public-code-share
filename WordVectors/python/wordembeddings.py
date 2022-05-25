# -*- coding: utf-8 -*-
"""
Created on Fri May  6 12:40:48 2022

@author: avery
"""



import re  # for regular expressions
import os  # to look up operating system-based info
import string  # to do fancy things with strings
import matplotlib.pyplot as plt # we'll use this for visualization
import glob # lets you locate a specific file type
from pathlib import Path 
import gensim
from gensim.models import Word2Vec # this is how we actually get access to Word2Vec
import pandas as pd
from gensim.models import KeyedVectors
from sklearn.decomposition import PCA
from matplotlib import pyplot
from sklearn import cluster #for k-means clustering
from sklearn import metrics #for k-means clustering

#### Folder to list

dirpath = Path(r'C:\Users\avery\Desktop\Recipe Dataset').glob('*.txt')  #get file path


files = dirpath
data = []

for filename in files:
    with open(filename) as afile:
        data.append(afile.read()) #read the file and then add it to the list
        afile.close() #close the file when you're done



###### CSV to dataframe



col_list = ["cluster", "text"] # columns you want to use

df = pd.read_csv(r'C:\Users\avery\Documents\part-00000-2e89f125-3669-4233-af16-409691708da0-c000.csv', usecols= col_list)


##### clean text
def clean_text(text):
    '''
    Cleans the given text using regular
    expressions to split and lower-cased versions to create
    a list of tokens for each text.
    Parameters:
        list_of_texts: list of str 
    Return: list of lists of tokens, one list per text
    '''
    re_punc = re.compile('[%s]' % re.escape(string.punctuation))

    # lower case
    tokens = text.split()
    tokens = [t.lower() for t in tokens]
    # remove punctuation
    tokens = [re_punc.sub('', token) for token in tokens] 
    # only include tokens that aren't numbers
    tokens = [token for token in tokens if token.isalpha()]
    return tokens

#clean text from folder of text files
data_clean = []
for x in data:
    data_clean.append(clean_text(x))

print(len(data))
print(len(data_clean))
print(data[1])
print(data_clean[1])
print(data_clean[len(data_clean)-1])
print(data[len(data)-1])

#clean text from dataframe
df['text'] = df['text'].apply(clean_text)

##################### TRAINING

model = Word2Vec(sentences=data_clean, window=5, min_count=3, workers=4)
model.save("word2vectest.model")

#sentences --> a list of lists of tokens. 
# min_count is how many times a word has to appear in the dictionary in order for it to 'count' the default value for min_count is 5. you will likely want to change this value depending on this size of your corpus
#window --> default is 5, Maximum distance between the current and predicted word within a sentence. i think this means "how different are the words allowed to be"1
# workers default is 3 (int, optional) – Use these many worker threads to train the model. 
# epochs (int, optional) – Number of iterations (epochs) over the corpus.
# sg: The training algorithm, either CBOW(0) or skip-gram (1). The default training algorithm is CBOW.
# https://radimrehurek.com/gensim/models/word2vec.html

################# saving space

#there are two ways that you can load and use the model. You can load it like this:

model = Word2Vec.load("word2vectest.model")


#or, you can load just the vectors and their keys. The reason you might want to do this is that it saves memory
#instead of using the whole model, this way you can just pull in the parts that you need (in this case the vectors)

word_vectors = model.wv
word_vectors.save("word2vec.wordvectors")
wv = KeyedVectors.load("word2vec.wordvectors", mmap='r') #by doing this, you don't have to load the full model every time

#what we've done above is create a new file (of type wordvectors), saved that file so that it can be loaded
#then, we loaded the wordvectors file (and told the computer to read all of those vectors) instead of the entire model
#If you want to continue training the model, you'll need the entire model but if you're just querying you can just use the keyvectors


##################### functions

model = Word2Vec.load("word2vectest.model")
sims = model.wv.most_similar('recipe', topn=10)
model.wv.similarity("milk", "cream") #how similar two words are
model.predict_output_word([ "flour", "eggs", "cream"])  #predict the other words in the sentence given these words
print(len(model.wv.vocab)) #number of words in the vocabulary


######################  k-means clustering

VOCAB = model[model.wv.vocab]
NUM_CLUSTERS = 3
kmeans = cluster.KMeans(n_clusters=NUM_CLUSTERS, max_iter=40).fit(VOCAB) #default is  clusters, 300 iterations

# edited from https://dylancastillo.co/nlp-snippets-cluster-documents-using-word2vec/#cluster-documents-using-mini-batches-k-means

labels = kmeans.labels_
centroids = kmeans.cluster_centers_
clusters_df = pd.DataFrame()
for i in range(NUM_CLUSTERS):
    most_representative = wv.most_similar(positive=[centroids[i]], topn=15)
    temp_df={'Cluster Number': i, 'Words in Cluster': most_representative}
    clusters_df = clusters_df.append(temp_df, ignore_index = True)
    print(f"Cluster {i}: {most_representative}")

################## Visualization


X = model[model.wv.vocab]  #get all the vectors
pca = PCA(n_components=2)
result = pca.fit_transform(X)
# create a scatter plot of the projection
pyplot.scatter(result[:, 0], result[:, 1])
words = list(model.wv.vocab)
for i, word in enumerate(words):
	pyplot.annotate(word, xy=(result[i, 0], result[i, 1]))
pyplot.show()