# -*- coding: utf-8 -*-
"""
Created on Fri May  6 12:40:48 2022

@author: avery
"""



import re  # for regular expressions
import os  # to look up operating system-based info
import string  # to do fancy things with strings
import matplotlib.pyplot as plt # we'll use this for visualization
from mpl_toolkits.mplot3d import Axes3D
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
from sklearn.manifold import TSNE #for tsne plot
import numpy as np #for PCA
import plotly.graph_objs as go #for PCA

#### Folder to list

dirpath = r'C:\Users\avery\Desktop\Recipe Dataset' #get file path (you can change this)

filenames = []
data = []

for root, dirs, files in os.walk(dirpath, topdown=False): #this for loop will run through folders and subfolders looking for a specific file type
   for name in files:
       if (root + os.sep + name).endswith(".txt"): #if you are wanting a different file type, change this to a different ending
           filenames.append(os.path.join(root, name))
   for name in dirs:
       if (root + os.sep + name).endswith(".txt"): #if you are wanting a different file type, change this to a different ending
           filenames.append(os.path.join(root, name))


for filename in filenames: #this for loop then goes through the list of files, reads them, and then adds the text to a list
    with open(filename) as afile:
        data.append(afile.read()) #read the file and then add it to the list
        afile.close() #close the file when you're done



###### CSV to dataframe



col_list = ["cluster", "text"] # columns you want to use, can change to whatever

df = pd.read_csv(r'C:\Users\avery\Documents\part-00000-2e89f125-3669-4233-af16-409691708da0-c000.csv', usecols= col_list)


################ clean text and tokenize
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

# these print statements makes sure that the original data and the clean data are the same length (nothing was left out and skipped)
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

#for more, check out the documentation here: https://radimrehurek.com/gensim/models/keyedvectors.html#what-can-i-do-with-word-vectors

model = Word2Vec.load("word2vectest.model")
model.wv.most_similar('recipe', topn=10)
model.wv.similarity("milk", "cream") #how similar two words are
model.predict_output_word([ "flour", "eggs", "cream"])  #predict the other words in the sentence given these words
print(len(model.wv)) #number of words in the vocabulary
model.wv.most_similar(positive = ["recipe"], negative=["cream"], topn=10)
model.wv.most_similar(positive = ["recipe", "milk"], topn=10)




######################  k-means clustering

VOCAB = model.wv[model.wv.key_to_index]
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

clusters_df.to_csv("random_clusters.csv")  #this will output the random sampling of clusters into a CSV located in your current directory. If you want the file to save somewhere else, just include that filepath in the csv name (so C:/Users/avery/Desktop/random_clusters.csv for example)


################## PCA

# based on this tutorial https://machinelearningmastery.com/develop-word-embeddings-python-gensim/ and the plt documentation

def pca(model):
    X = model.wv[model.wv.key_to_index]  #get all the vectors
    pca = PCA(n_components=3)
    result = pca.fit_transform(X)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    z_axis = result[:,2]
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x_axis, y_axis, z_axis)
    ax.set_xlabel('x axis')
    ax.set_ylabel('y axis')
    ax.set_zlabel('z axis')
    
    plt.show()

#pca(model)

####################  TSNE

# This code is heavily based off of code from
# https://www.kaggle.com/jeffd23/visualizing-word-vectors-with-t-sne

def tsne_plot(model, focus_word = None, n = 50):
    "Creates and TSNE model and plots it"
    labels = []
    tokens = []

    if focus_word is not None:
        tokens.append(model.wv[focus_word])
        labels.append(focus_word)
        neighbors = model.wv.most_similar(focus_word, topn = n)
        for neighbor in neighbors:
            tokens.append(model.wv[neighbor[0]])
            labels.append(neighbor[0])
    else:
        for word in model.wv.key_to_index:
            tokens.append(model.wv[word])
            labels.append(word)
    
    tsne_model = TSNE(perplexity=40, n_components=2, init='pca', n_iter=2500, random_state=23)
    new_values = tsne_model.fit_transform(tokens)

    x = [value[0] for value in new_values]
    y = [value[1] for value in new_values]
        
    plt.figure(figsize=(16, 16)) 
    for i in range(len(x)):
        plt.scatter(x[i],y[i])
        plt.annotate(labels[i],
                     xy=(x[i], y[i]),
                     xytext=(5, 2),
                     textcoords='offset points',
                     ha='right',
                     va='bottom')
    plt.show()
    
#tsne_plot(model)
    
##########################    Evaluating

dirpath = Path(r"C:\\Users\\avery\\.spyder-py3\\models\\wordvector models").glob('*.model') #current directory plus only files that end in 'model' 
files = dirpath
model_list = [] # a list to hold the actual models
model_filenames = []  # the filepath for the models so we know where they came from

#this for loop looks for files that end with ".model" loads them, and then adds those to a lsit
for filename in files:
    file_path = str(filename)
    model = Word2Vec.load(file_path)
    model_list.append(model)
    model_filenames.append(file_path)
 
#test word pairs that we are going to use to evaluate the models
test_words = [("away", "off"),
            ("before", "after"),
            ("cause", "effects"),
            ("children", "parents"),
            ("come", "go"),
            ("day", "night"),
            ("first", "second"),
            ("good", "bad"),
            ("last", "first"),
            ("kind", "sort"),
            ("leave", "quit"),
            ("life", "death"),
            ("girl", "boy"),
            ("little", "small")]

#these for loops will go through each list, the test word list and the models list, and will run all the words through each model
#then the results will be added to a dataframe
evaluation_results = pd.DataFrame(columns=['Model', 'Test Words', 'Cosine Similarity'])
for i in range(len(model_list)):
    for x in range(len(test_words)):
        similarity_score = model_list[i].wv.similarity(*test_words[x])
        df = [model_filenames[i], test_words[x], similarity_score]
        evaluation_results.loc[i] = df
        
# evaluation_results.to_csv('word2vec_model_evaluation.csv') #dump the results into a csv