#!/usr/bin/env python
# coding: utf-8

# # Exploratory Visualization With Word2Vec #
# 
# Author: Avery Blankenship
# 
# Date: 9/6/23
# 
# ---
# 
# This notebook picks up where the core notebook left off to discuss analytical methods for working with word embedding models. In this notebook, we will be covering k-means clustering, Principal Component Analysis (PCA) and T-Distributed Stochastic Neighbor Embedding (tSNE). This notebook assumes that you have already trained a model using Word2Vec as described in the [Word2Vec Fundamentals](word2vec-fundamentals.ipynb).
# 
# While in the fundamentals notebook, we covered some of the ways you can query a model and how those queries can help you answer interesting research questions. Using some slightly more complicated analytical methods, however, allows you to get a better sense of the model as a whole. These analytical methods can help you target your research questions.

# ## Some Notes on Future Warnings
# 
# You may notice as you proceed through this tutorial that some of the code produces what is called a **future warning**. Future warnings that pop up when a package or library will be updated at some point and thus the syntax of the code will change. If you read the warning, you'll notice that the warning is typically suggesting an alternative syntax to replace the code that triggered the warning. Future warnings occur when the code will update _in the future_, meaning that the update hasn't occurred yet. Thus, some of the suggested alternatives may not work yet. Feel free to ignore future warnings in these cases. The only errors you should actually pay attention to are errors that indicate that there is a legitimate syntax error. As of January 2023, the code below still functions with only a few future warnings. However, given the speed with which Python updates and changes, this may not be the case a year from now. Please keep this in mind as you proceed and make sure to read the errors or warnings that are thrown.

# We're going to start by importing all of our libraries as well as our model.

# In[ ]:


import re                                               # for regular expressions
import os                                               # to look up operating system-based info
import string                                           # to do fancy things with strings
import glob                                             # to locate a specific file type
from pathlib import Path                                # to access files in other directories
import gensim                                           # to access Word2Vec
from gensim.models import Word2Vec                      # to access Gensim's flavor of Word2Vec
import pandas as pd                                     # to sort and organize data
from sklearn.decomposition import PCA                   # to import PCA algorithm
from matplotlib import pyplot                           # to visualize our data as graphs
from sklearn import cluster                             # to use k-means clustering
from sklearn import metrics                             # to use k-means clustering
from sklearn.manifold import TSNE                       # to generate a tsne plot
import numpy as np                                      # to do fancy things with numbers
import plotly.graph_objs as go                          # to visualize PCA
import matplotlib.pyplot as plt                         # to visualize plots
from mpl_toolkits.mplot3d import Axes3D                 # to visualize 3D plots

model = Word2Vec.load(r"./models/test.model")


# these are the height and width sizing that we will use for our figures
# you may want to adjust these numbers to better fit your screen
figure_height = 8
figure_width = 6


# # K-means Clustering
# 
# Cosine similarity is not the only way to calculate the distance between two vectors. Another method for performing this calculation is through k-means clustering. K-means clustering uses Euclidean distance rather than cosine similarity in order to determine how close two vectors are in vector space. 
# 
# How do these two methods for measuring distance work? For cosine similarity: imagine that you have drawn a line connecting two points in vector space. Since both of these points are also connected to the origin point of the plot, by drawing a line to connect the two points, you've created a triangle. To calculate the cosine similarity of two points, the cosine of this new connecting line is calculated. In contrast, Euclidean distance calculates the _length_ of the line connecting the two points. As a result, whereas vectors tend to be more similar when the cosine of the two is larger, for Euclidean distance, a smaller number indicates a shorter line connecting the two vectors. The smaller the number is, the more similar two words are.
# 
# **Clustering** is a technique popular in machine learning techniques. The act of clustering essentially means that the data points in a model, in our case individual words, are grouped together into neighborhoods or communities. The neighborhoods are determined based on similarity, so words that are more similar are grouped in the same neighborhood and are not in the same neighborhood as dissimilar words. K-means clustering uses euclidean distance to determine what these neighborhoods are by clustering around a central word that the algorithm has chosen. Based on this word, the words that are most similar given their euclidean distance are clustered, or grouped, together. However, it is important to keep in mind that "similarity" in a word embedding model does not mean that words share similar meaning. Antonyms are just as likely to be included in your clusters because of a similarity in usage.
# 
# With this in mind, k-means clustering begins by choosing a set of random points in vector space, called **centroids**, and seeing what vectors tend to be clustered together in those random locations. By calculating the Euclidean distance, the algorithm determines which points are closest to the centroids (which of them have the smallest Euclidean distances) while maintaining larger distances from other centroids. The algorithm tries to maintain some distance between clusters in order to ensure that they are distinct. 
# 
# K-means is called "k-means" because some number of clusters (k) are used to calculate vector distance by taking the mean of all vectors within those clusters by adding the squared Euclidean distance between of all of the vectors within the cluster and the centroid.
# 
# Essentially, k-means clustering is calculating the distances between vectors in a way that is nearly the opposite of how built-in functions such as the similarity function calculate the same thing. 
# 
# When working with word embedding models, k-means clustering can be useful in order to get a sense of what words tend to occupy the same general space. The centroids will be placed in vector space randomly, but since a crucial part of the k-means algorithm requires that vectors be distant from neighboring clusters, this ensures that there will likely be very minimal overlap between your sampling of random clusters. 
# 
# In this walkthrough, we are going to use the k-means algorithm that comes with the popular scikit-learn library in Python.
# 
# This code was adapted from Dylan Castillo’s [“How to Cluster Documents Using Word2Vec and K-means”.](https://dylancastillo.co/nlp-snippets-cluster-documents-using-word2vec/#cluster-documents-using-mini-batches-k-means)
# 
# 

# ### The Code ###
# 
# We're going to start off by just declaring a few variables. The first variable `vocab`, is going to hold our model's vocabulary. In Gensim 4.0, you retrieve the model's vocabulary by calling `model.wv.key_to_index`. In older versions of Gensim, you replace `key_to_index` with `vocab`. 
# 
# Finally, we declare a variable `kmeans` that will hold the call to scikit-learn's k-means algorithm. As you can see, this algorithm initializes with some number of clusters, some number of iterations, and then is fitted to the vocabulary of your model. Like the code for training a model, these are settings that you will likely wish to play around with. You can visit scikit-learn's [documentation](https://scikit-learn.org/stable/modules/generated/sklearn.cluster.KMeans.html) to read more about additional settings that may be of use to you. 
# 
# In the actual call to the k-means algorithm, there are a few parameters which you can change. 
# 
# __n_clusters__ -- this parameter represents the number of clusters (or centroids) you want to have. By default, this value is 8 though you can change the number to whatever you want. Keep in mind that for a smaller vocabulary, a smaller number of clusters might generate more useful data than a large number. The code below has 3 clusters.
# 
# __max_iter__ -- this parameter represents the number of iterations you want the algorithm to complete in a single run. By default this parameter is set to 300, though you can change this number to whatever you like. The code below uses 40 iterations since the recipe model is relatively small.
# 
# There are a few additional optional parameters, though the two above are the move important. You can read about other parameters in the documentation. 

# In[ ]:


# vocab will hold our model's vocabulary
vocab = model.wv[model.wv.key_to_index]

# change this if you want more clusters
num_clusters = 3

# declare kmeans to hold the call to scikit-learn's k-means algorithm
# by default, the algorithm sets the number of clusters to 8 and the max iterations to 300
# you can change the number of clusters or the number of max iterations 
kmeans = cluster.KMeans(n_clusters=num_clusters, max_iter=40).fit(vocab) 


# Next, we'll declare a set of variables related to the clusters themselves. The `centroids` variable will hold the center points around which the clusters are arranged. You can imagine these centroids as points on a map that we have thrown random darts at. The centroids are generated by the k-means algorithm as it runs. The way that we get access to these centroids is by using the `cluster_centers_` variable that the algorithm generates. This is somewhat similar to the way you call `model.wv` to get access to a model's word vectors.
# 
# Finally, we declare the `clusters_df` dataframe which will be used to store the words within our clusters. Storing these clusters in a dataframe will allow us to preserve distinctions between clusters using columns and rows, and will make saving the results to a `.csv` file easier.

# In[ ]:


# set the centroids variable to the k-means cluster centers
centroids = kmeans.cluster_centers_

# declare an empty dataframe
clusters_df = pd.DataFrame()


# Now, using a `for` loop, we are going to visit each of the clusters and gather some of the words within them. This `for` loop starts at the first cluster and will iterate through each of the clusters, stopping once it has finished with the last one.
# 
# As the `for` loop reaches a cluster, it calculates the most representative words within that cluster by using the `most_similar` function. The function is calculating the words that are most similar to the centroid of that cluster and returns the top 15 words. Those words are stored within a variable, `most_representative`.
# 
# Then, we declare a temporary dataframe, called `temp_df` that will store the ID of the current cluster and the words associated with that cluster. Saving both the cluster ID as well as the words allows us to remember which words came from which cluster and will make interpreting the results much easier later.
# 
# Next, the temporary dataframe is appended to our `clusters_df` dataframe and the cluster ID and list of words are printed to the console.

# In[ ]:


# iterate through each of the clusters
for i in range(num_clusters):
    
    # calculate the top fifteen most similar words within the current cluster
    most_representative = model.wv.most_similar(positive=[centroids[i]], topn=15)
    
    # store the cluster number and the most representative words in a temporary dataframe
    temp_df = pd.DataFrame({'Cluster Number': i, 'Words in Cluster': most_representative})
    
    # add the items in the temporary dataframe to our bigger clusters dataframe which will hold all the clusters
    clusters_df = pd.concat([clusters_df, temp_df], ignore_index = True)
    
    # print the cluster id and the most representative words to the console
    print(f"Cluster {i}: {most_representative}")


# In order to make our results a little easier to read and viewable later, we can save the dataframe to a `.csv` by using the built-in pandas function `.to_csv()`. This function will preserve the columns and rows within our `clusters_df` dataframe and can be opened in any editor that can work with spreadsheets such as Excel or Google Sheets. Currently, the results are saved as `sample_clusters.csv`, though you can change this filename to something more meaningful (and should do so, in your own research!).
# 
# The code block below saves the results to your current working directory, but if you want your results saved somewhere more specific, include the filepath with the call to `.to_csv()`

# In[ ]:


# this will output the clusters into a CSV located in your current directory. 
# if you want the file to save somewhere else, just include that filepath in the csv name 
# (for example, "C:/Users/avery/Documents/sample_clusters.csv")
clusters_df.to_csv("./data/sample_clusters.csv")  


# ### Interpreting the Results ###
# 
# K-means clustering is a good way to identify patterns in your model that you may not have been aware of. Because of this, k-means clustering is a useful first step in your analysis—it can help you explore your data, and the algorithm scales up to large datasets well. Since word2Vec is an unsupervised algorithm, it can be difficult to determine how the algorithm has grouped words together without an exploratory phase. 
# 
# However, when using k-means clustering, you should be aware that the results of the clustering may be impacted by a few factors. For example, rather than ignoring outliers, or uncommon occurrences of words that aren't necessarily representative, the k-means clustering algorithm includes outliers with all of the rest of the data. For this reason, an outlier case in your model may drag other words into a cluster in a way that is not genuinely significant. Additionally, since you need to manually select the number of clusters as well as the number of iterations, it may take a few tries to generate useful data. 

# # Principal Component Analysis 
# 
# Another useful form of model analysis is PCA (principal component analysis). For a much more detailed breakdown of PCA, check out The Datasitters Club's [write up on PCA](https://datasittersclub.github.io/site/dsc10.html).
# 
# Briefly, PCA is a dimensionality reduction algorithm. PCA is called PCA because it attempts to reduce a dataset to its **principal components**. Just as k-means differed in its mathematical approach from cosine similarities, PCA also takes a different approach to dealing with vectors. Rather than calculate the length of a line or the cosine of an angle, PCA determines the principal components of a dataset by using _linear algebra_. The algorithm uses linear algebra to combine items within a dataset in order to produce new items that contain most of the information from the old items, or their "principal components".
# 
# Whereas k-means and cosine similarity try to capture similarity or closeness, PCA is more concerned with capturing the largest amount of variance in a dataset. It does this by using **eigenvectors** to determine what the degree of variance is among items in a dataset. The PCA algorithm will continue to calculate these eigenvectors while trying to maintain the most variance between components as possible and discarding items that are less significantly variable. The items that we decide to keep are called **feature vectors**. These feature vectors are then plotted and represent the essential features of the dataset while reducing some of that dataset's bulk. Probably the best way to think of these components is as a sifter dug into sand to filter out shells and rocks. Since there is so much sand, we don't necessarily care about including the sand in a description of what you were able to find with the sifter. We do care, however, about the unique shells and rocks, and those items can tell us more about the features of the beach than any individual grain of sand. 
# 
# For the code, we are going to use scikit-learn's built-in PCA algorithm. 

# ### The Code ###
# 
# First, we declare the variable `labels` which will hold the vocabulary of our model, formatted as a list. We'll use this variable later when we are labeling the points on our PCA plot.

# In[ ]:


# declare label list to hold our model vocabulary
# the model vocabulary will be used to label the points plotted
labels = list(model.wv.key_to_index)


# The next thing that we do is declare a variable `vectors` which will hold all of the vectors in our model. PCA is going to try and sift through all of the sand in our vectors in order to pull out the seashells and rocks that we're interested in, so we have to feed it all of the vectors to make this task possible. Next, we declare a variable `pca` which will hold the PCA call from scikit-learn. The `PCA()` function takes one parameter, `n_components`, which is the number of components you want the plot to represent. We have set `n_components` to 2 which will generate a 2D plot.
# 
# Finally, we fit the PCA function to our particular model's vectors and let it start sifting. In this case, **fit** means that we adjust the PCA model so that it more accurately produces the type of results that our word embedding model does. Since we are really working with two distinct models here, our original word embedding model and the PCA model that was trained using the word embedding model, fitting ensures that the models are comparable enough to produce similar results. If our word embedding model is a t-shirt, fitting means that the PCA model fit in that t-shirt. If your model doesn't fit well--if the PCA model can't fit in the word embedding model's t-shirt, then the second model (in this case the PCA model) cannot accurately predict or understand the complex relationships between variables (in this case words).

# In[ ]:


# define a variable `vectors` which will hold the vectors within our model
vectors = model.wv[model.wv.key_to_index]
    
# define a variable `pca` which will hold the call to the PCA algorithm
# the number of components is set to 2
pca = PCA(n_components=2)
    
# declare a variable `result` which holds the outcome of the algorithm
result = pca.fit_transform(vectors)


# After calculating the principal components of our model's vectors, we want to do something with them. We're going to plot our 2D components on a graph which will allow us to see the shape of the model. Since this is a two-dimensional graph, we need to define the x and y axes. We do this by assigning each of these axes a component, as produced by our `result` variable from above. 
# 
# Now that we have our x and y axes, we can plot them. We start by declaring a variable `figure` which will represent our plot. We set the size of our particular figure to `(8, 6)`, but you should feel free to play around with the sizing on your own. Different sizes may work better with your data depending on its size. Then, we declare a variable, `axis`. The `axis` variable will allow us to label each axis as well as access individual points on the plot, making labeling much easier.
# 
# We use the `axis` variable to tell the computer that we want a 2D graph, and that we want to produce a scatter plot using the values associated with the x and y axes, each of which contains one of our principal components. 
# 
# The `for` loop which follows is how we are going to label our points. Using the built-in function `.text()`, we tell the computer to visit each point on the plot and assign the corresponding label from our `labels` list to that point. We've set the font to be italic & blue, and the font size to 10, but these values can be adjusted to your liking. You can also comment out the `for` loop if you want to look at the PCA graph without the labels. 
# 
# Finally, we label the x and y axes. For this walkthrough, we have simply labeled them "x axis" and "y axis" though these can also be changed. 
# 
# We end the function by telling the computer to show us the resulting plot by using the built-in `.show()` function. 
# 
# For now, the figure size is set to a height of 8 and a width of 6. For smaller screens, a smaller figure size may be best.

# In[ ]:


# create a scatter plot of the projection

# set the points for the x_axis by grabbing all the items in column one of the `results` variable
x_axis = result[:,0]

# set the points for the y_axis by grabbing all the items in column two of the `results` variable
y_axis = result[:,1]


# create a new figure of size (8, 6)
figure = plt.figure(figsize=(figure_height, figure_width)) # you can change this size

# create a variable for the axes and let the computer know we want a 2D plot
# the "111" here tells the `add_subplot()` function to generate a 1 X 1 plot
axis = figure.add_subplot(111)

# scatterplot the points by using the `x_axis` variable as X and the `y_axis` variable as Y
axis.scatter(x_axis, y_axis)

# iterate through our labels list
for i in range(len(labels)):
        
    # assign labels to the points and make those labels italic, black, and size 10
    axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
    fontsize = 10, color ="black")  # you can change these values
        
# label the x axis
axis.set_xlabel('x axis') # you can change this

# label the y axis
axis.set_ylabel('y axis') # you can change this
   
# visualize the plot
plt.show()


# 
# While this code is pretty handy, if you want to change the model that is being analyzed, you would need to rerun all of your code. Having to rerun all of your code to reflect a single-line change, however, is not only inconvenient, but it is also not very memory efficient and will introduce unnecessary strain to your computer. 
# 
# In order to make rerunning the PCA code easier, we're going to surround the code above with a function definition. 
# 
# We are going to keep the bulk of the PCA code within a function that we will call `pca()`. Keeping the PCA code within a function ensures that we don't have to rerun the code if we want to apply PCA analysis to more than one dataset. Function definitions should be placed before any calls to use that function in the code. In order to define a function in python, you follow the format below (using however many parameters you want the function to act upon):
#     
# ```python
# def function_name(parameter 1, parameter2):
#     some code
#  
# ```
# Then, you can call the function just like we've called built-in functions in previous code by first writing the function name and then the parameters in parentheses: `function_name(parameter)`. In our case, we are going to define `pca()` as a function that accepts a model as its only parameter. This way, if you want to run the `pca()` function on a different model, you would just need to call `pca()` on your model of choice.
# 
# Before we define our function, we are going to declare the variable `labels`. We declare the `labels` variable outside of the PCA function for two reasons. First, by keeping `labels` outside of the function definition, we don't have to change anything about the PCA function if we want to change what the labels are. Second, it's a good practice to keep variables that aren't directly contributing to functionality of the function outside of its definition. 

# In[ ]:


labels = list(model.wv.key_to_index)
def pca(model):
    vectors = model.wv[model.wv.key_to_index]  # get all the vectors
    pca = PCA(n_components=2)
    result = pca.fit_transform(vectors)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    figure = plt.figure(figsize=(figure_height, figure_width))
    axis = figure.add_subplot(111)
    axis.scatter(x_axis, y_axis)
    for i in range(len(labels)):
        axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
        fontsize = 10, color ="blue")
    axis.set_xlabel('x axis')
    axis.set_ylabel('y axis')

    
    plt.show()

# here, we're actually calling the function
pca(model) 


# What you will likely notice, is that this graph is impossible to read. Since we are asking the computer to label every point in the model, there are so many labels that we can't actually read any of them. This graph would become even more crowded with a larger model. One of the key points, here, is that visualizations are not always relevatory. Sometimes, visualizations actually confuse you _more_ than illuminate features about the data. An important lesson here, is that not all types of visualizations are going to be well suited for your data. In this case, labeling all of the points probably isn't a great idea since we have so many of them. 
# 
# As you can see, labeling every point on the PCA plot can make reading the labels quite difficult. Instead of labeling every point, we might want to plot all of our points and visualize a random number of them. In order to accomplish this, we are going to use the python library `random`. We are going to insert the code below into our `pca()` function to replace the `for` loop we previously used to label. 
# 
# First, we import `random` and then set the random number generator by using the built-in function `.seed()`. The code `.seed(0)` tells the computer to set the random number generator to begin at the number 0. `random.seed()` defaults to using a constantly changing number, the current system time. That means that the numbers that the RNG produces will be different every time. If we set it to an integer (like 0), the "random" numbers that the generator selects will be the same every time. We're going to set the seed number to 0 for the purposes of showing the same datapoints on each graph we produce below, but we will end the section with a flavor of the PCA graph that truly produces random results on every run of the algorithm.
# 
# Next, we declare a variable `all_indices` which will hold the indices for all vectors in our model. `all_indices` will be what we actually take a random sample from. We then declare a variable `selected_indices` which will hold our random sampling. In this instance, I am taking a random sample of 25, though this number can be changed. 
# 
# Finally, we use a `for` loop to iterate through `selected_indices` and assign a label to the points in the corresponding locations. Putting this new code together, it is going to look like the sample code below and will be added to our existing PCA function.

# ```python
# # import random library
# import random
# 
# # initiate random number generator
# random.seed(0)
# 
# # grab all of the indices for our model vocabulary
# all_indices = list(range(len(labels)))
# 
# # take a random sample of 25 indices
# selected_indices = random.sample(all_indices, 25) # you can change this
# 
# # iterate through our random sample
# for i in selected_indices:
#         
#     # label the corresponding random points
#     axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
#     fontsize = 14, color ="black") # change the font and font color to make the text more visible
#     
# ```

# The entire `pca_2d()` function with a random sample of 25 items labeled is below:

# In[ ]:


labels = list(model.wv.key_to_index)
def pca_2d(model):
    vectors = model.wv[model.wv.key_to_index]  # get all the vectors
    pca = PCA(n_components=2)
    result = pca.fit_transform(vectors)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    figure = plt.figure(figsize=(figure_height, figure_width))
    axis = figure.add_subplot(111)
    axis.scatter(x_axis, y_axis)

    import random
    random.seed(0)
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
        fontsize = 8, color ="black")

    
    plt.show()

# call the function
pca_2d(model)


# PCA plots can also be represented three-dimensionally which can often provide a different view of your model vocabulary. With the PCA plot represented three-dimensionally, you can get a better sense of the shape of the plot and where words are located in that space. The code is nearly the same as the two-dimensional plot above. The key difference between the two is that instead of plotting an X and Y axis, we are going to plot a X, Y, and Z axis. The Z axis will represent the third dimension that we are adding to our plot.
# 
# Everything is nearly the same but you'll notice that in addition to defining the `x_axis` and `y_axis` variables, we are also going to define a variable `z_axis` which will pull vectors from the third column in our `result` variable. We also have set the number of components to 3 since this is a 3D graph.
# 
# An example of what this code might look like is below

# ```python
# # define a variable X which will hold the vectors within our model
# vectors = model.wv[model.wv.key_to_index]
#     
# # define a variable pca which will hold the call to the PCA algorithm
# # the number of components is set to 3
# pca = PCA(n_components=3)
#     
# # declare a variable result which holds the outcome of the algorithm
# result = pca.fit_transform(vectors)
# 
# # define x axis
# x_axis = result[:,0]
# 
# # define y axis
# y_axis = result[:,1]
# 
# # define z axis
# z_axis = result[:,2]
# ```

# Then, when we define our `ax` variable, we are going to tell the computer that we want a three-dimensional projection of our PCA plot. We do so by including `projection="3d"` in the `ax` definition like in the sample below.
# 
# ```python
# axis_3d = figure.add_subplot(111, projection='3d')
# ```

# Next, we're going to label a random sample of 25 points like we did above. This way, it's much easier to read the plot. We're going to use the random generator like in the above section, but we are going to add a Z axis to the label `for` loop. The sample below is an example of what that might look like:
# 
# ```python
# import random
# random.seed(0)
# all_indices = list(range(len(labels)))
# selected_indices = random.sample(all_indices, 25) # you can change this
# for i in selected_indices:
#     axis_3d.text(x_axis[i], y_axis[i], z_axis[i], labels[i], style ='italic', # I added the z_axis here
#     fontsize = 10, color ="blue")
# ```   

# Finally, we are going to label the z axis just like we labeled the x and y axes. Like before, these labels can be adjusted to better suit your corpus or data. 
# 
# ```python
# axis_3d.set_xlabel('x axis')
# axis_3d.set_ylabel('y axis')
# axis_3d.set_zlabel('z axis') # here is the z axis
# ```

# The entire function definition is listed below. You can call this function just like the others by typing `pca_3d(model)`. The new version of the PCA function includes all of the sample code pieces we discussed above mixed in with our old PCA code.

# For the sake of having both the 2d and 3d versions of the scatter plot handy, I've renamed the functions above so that `pca_2d(model)` will show you the 2d version of the scatter plot and `pca_3d(model)` will show you the 3d version. The code for these functions are below:

# In[ ]:


labels = list(model.wv.key_to_index)
def pca_2d(model):
    vectors = model.wv[model.wv.key_to_index]  # get all the vectors
    pca = PCA(n_components=2)
    result = pca.fit_transform(vectors)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    figure = plt.figure(figsize=(figure_height, figure_width))
    axis = figure.add_subplot(111)
    axis.scatter(x_axis, y_axis)

    import random
    random.seed(0)
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
        fontsize = 8, color ="black")

    
    plt.show()

# call the function
pca_2d(model)


# In[ ]:


get_ipython().run_line_magic('matplotlib', 'notebook')
labels = list(model.wv.key_to_index)
def pca_3d(model):
    vectors = model.wv[model.wv.key_to_index]  #get all the vectors
    pca = PCA(n_components=3)
    result = pca.fit_transform(vectors)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    z_axis = result[:,2]
    figure = plt.figure(figsize=(figure_height, figure_width))
    axis_3d = figure.add_subplot(111, projection='3d')
    axis_3d.scatter(x_axis, y_axis, z_axis)
    import random
    random.seed(0)
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        axis_3d.text(x_axis[i], y_axis[i], z_axis[i], labels[i], style ='italic',
        fontsize = 14, color ="black")
    axis_3d.set_xlabel('x axis')
    axis_3d.set_ylabel('y axis')
    axis_3d.set_zlabel('z axis')

    
    plt.show()
    
# call the function
pca_3d(model)


# If you want to give running the `pca` in a way that will generate 25 new random points on every run, use the `pca_random(_)` function below. All I have changed is not setting the random seed.

# In[ ]:


labels = list(model.wv.key_to_index)
def pca_random(model):
    vectors = model.wv[model.wv.key_to_index]  # get all the vectors
    pca = PCA(n_components=2)
    result = pca.fit_transform(vectors)
    # create a scatter plot of the projection
    x_axis = result[:,0]
    y_axis = result[:,1]
    figure = plt.figure(figsize=(figure_height, figure_width))
    axis = figure.add_subplot(111)
    axis.scatter(x_axis, y_axis)

    import random
    random.seed() # Here I got rid of the 0 that was setting the seed before
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        axis.text(x_axis[i], y_axis[i], labels[i], style ='italic',
        fontsize = 8, color ="black")

    
    plt.show()

# call the function
pca_random(model)


# ### Interpreting PCA Results ###
# 
# A couple of things to keep in mind while you explore your new visualization are:
# 
# 1. PCA results are usually discussed in terms of component scores. Component scores represent how significant a particular component is to the data. A high component score means that that particular component is highly influential
# 
# 2. It can be useful to look at the components themselves and explore what types of words tend to be gathered by that component.
# 
# PCA can generally help you get a sense of how your data is shaped. However, PCA is not particularly useful for determining what individual clusters of words might be. In order to determine that, you should turn to tSNE analysis, which is particularly useful for getting a sense of how your data is grouped whereas PCA more so captures a sense of the data as a whole.

# # tSNE Analysis ##
# 
# The final form of mathematical analysis that we will cover in this tutorial is tSNE analysis. T-distributed Stochastic Neighbourhood Embedding (tSNE) is a dimensionality reduction algorithm similar to PCA. However, while PCA is more concerned with preserving variance in a data set, tSNE cares more about things that are close together. Essentially, tSNE is a type of analysis that allows you to visualize all of the words in your corpus according to their relationships with other words. Imagine that tSNE is visualizing your corpus as a neighborhood where some words live next door to one another and other words might live across the street or on a different street altogether. Another important difference between tSNE and PCA, is that the results of tSNE analysis vary with each run. This is because tSNE is a probabilistic technique. tSNE is also always working in a two-dimensional space whereas PCA can work with many dimensions. 
# 
# However, while tSNE does differ in important ways from PCA, a researcher might find tSNE's ability to represent the shape of data more effectively more appealing than PCA. Whereas PCA tends to mix data together and represent it as a singular grouping, tSNE often produces visualizations of clusters in a data set. This ability to represent these groupings can be helpful from an exploratory perspective as it allows researchers to see the variance in their data. While generally, it is recommended to start with PCA, following up a PCA graph with a tSNE analysis can help produce a more full picture of a word embedding model. 
# 
# tSNE, like our other methods of analysis, uses a different type of math in order to calculate the distances between vectors. While PCA uses eigenvectors and linear algebra to calculate distance, tSNE uses t-distributions, a technique from statistics. The algorithm begins by calculating the Euclidean distance and then calculates a probability distribution across these distances using t-distributions. The goal of the algorithm is to keep similar words close together in tSNE's two-dimensional space while maximizing the distance between words that are not similar.
# 
# Like with PCA, we are going to store our tSNE code in a function in order to make applying it to our model easier. The code for this tSNE function is adapted from the code from [this tutorial](https://www.kaggle.com/jeffd23/visualizing-word-vectors-with-t-sne).
# 
# tSNE works a little bit slower than PCA, so the code below may be slightly slower to display the visualization.

# ### The Code ###

# We begin by declaring two lists, `tokens` and `labels`. We'll use these lists to keep track of the vectors and their labels for each item in the model. 

# In[ ]:


# two empty lists that we will use to hold some data later
labels = []
tokens = []


# After those two lists are declared, we proceed to an `if` statement and a `for` loop. The `if` statement asks whether we have a focus word by checking if the `focus_word` variable is equal to `None` or not. If the `focus_word` is _not_ set to `None`, the function proceeds to calculate the top `n` (`n` is set to 50 in the function definition) most similar words to that focus word. The code then proceeds to add these 50 neighbors to the labels and tokens lists. 
# 
# If there is no focus word, the code cycles through the model's vocabulary and adds the words in the model to the labels and tokens lists respectively. 
# 
# This initial `if` statement allows you to perform tSNE analysis around a particular word or to focus on a particular area of the vector space. As we have walked through, if there is a focus word, then what gets added to the labels and tokens lists are the 50 nearest neighbors to that particular word. This approach limits the tSNE analysis to that particular word. If there is no focus word, then the tSNE analysis is performed on the entire model.

# In[ ]:


# we'll set focus_word to none for now
focus_word = None

# this if statement is for when there is a focus word
if focus_word is not None:
    
    # add the focus_word vector to the tokens list
    tokens.append(model.wv[focus_word])
    
    # add the focus word to the labels list
    labels.append(focus_word)
    
    # define a variable neighbors which holds the top 'n' most similar words to the focus word
    neighbors = model.wv.most_similar(focus_word, topn = n)
    
    # cycle through the neighbors variable
    for neighbor in neighbors:
            
        # add the vector for each neighbor to the tokens list
        tokens.append(model.wv[neighbor[0]])
            
    # add each word to the labels list
    labels.append(neighbor[0])

# if there is no focus word
else:
    
    # traverse through the model vocabulary
    for word in model.wv.key_to_index:
        
        # add each word vector to the tokens list
        tokens.append(model.wv[word])
        
        # add each word to the labels list
        labels.append(word)


# Next, like in the PCA example, we declare a variable, `tsne_model`, to hold the function call to scikit-learn's tSNE algorithm. scikit-learn's tSNE function accepts a number of parameters which can impact how the algorithm traverses through your data: 
# 
# 1. **n_components** -- This parameter corresponds to how many dimensions the analysis should work in. The default is 2. 
# 
# 2. **Perplexity** -- This parameter relates to the nearest neighbors in the analysis. It basically tries to guess how many neighbors a particular vector will have in order to balance the attention given to each vector. Scikit-learn suggests using numbers between 5 and 50
# 
# 3. **init** -- This parameter allows you to suggest how the components will be calculated, either 'random' or by 'pca'
# 
# 4. **n_iter** -- This parameter represents the number of times the algorithm should traverse through the data before producing the plot
# 
# 5. **random_state** -- This parameter helps to prevent different results being produced with different runs of the algorithm
# 
# There are a number of additional optional parameters which you can view in [scikit-learn's tSNE documentation](https://scikit-learn.org/stable/modules/generated/sklearn.manifold.TSNE.html).

# In[ ]:



# declare a variable, tsne_model, to hold the instance of the tSNE algorithm
tsne_model = TSNE(perplexity=40, n_components=2, init='pca', n_iter=2500, random_state=23)

# declare a variable, new_values, to hold the vectors from the tSNe analysis
new_values = tsne_model.fit_transform(tokens)


# The rest of the code formats the vectors in `new_values` so that they can be plotted on a scatter plot. Then, the labels list is used to label each point. 

# In[ ]:



# define the x axis
x = [value[0] for value in new_values]

# define the y axis
y = [value[1] for value in new_values]
     
# set the size of the scatter plot
plt.figure(figsize=(figure_height, figure_width)) 
    
# begin to plot each point and label it
for i in range(len(x)):
    plt.scatter(x[i],y[i])
    plt.annotate(labels[i],
                     xy=(x[i], y[i]),
                     xytext=(5, 2),
                     textcoords='offset points',
                     ha='right',
                     va='bottom')
# show the plot        
plt.show()


# Just like in the PCA example, it would be much more efficient to have our tSNE analysis within a function definition so that we can run the code on different models and focus words without having to rerun all of the code. 
# 
# We begin by defining a function, `tsne_all_points()`, which accepts a model, a focus word, and a number of words as parameters and plots all of the data points in the model. As you can see, `focus_word` is set to `none` by default and the number of words is set to 50. These parameters can be adjusted to suit your needs. For instance, if you want the tSNE plot to be focused around a particular word, you can change `focus_word` to the word you are interested in. The definition looks like this:
# ```python
#     def tsne(model, focus_word = None, n = 50):
#    ```
# Just like the PCA analysis, you call the tSNE function by using `tsne_all_points(model)`. If you wanted to set a focus_word, you can follow this model: `tsne_all_points(model, focus_word="milk")`
# 
# All of the rest of the code is the same as above, just indented one line in to indicate that it is part of the function. When running the code below, you may trigger a future warning, but feel free to ignore it.

# In[ ]:


def tsne_all_points(model, focus_word = None, n = 50):
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
        
    plt.figure(figsize=(figure_height, figure_width)) 
    for i in range(len(x)):
        plt.scatter(x[i],y[i])
        plt.annotate(labels[i],
                      xy=(x[i], y[i]),
                      xytext=(5, 2),
                      textcoords='offset points',
                      ha='right',
                      va='bottom')

    plt.show()
    
# call the function
tsne_all_points(model)


# Because word embedding models contain quite a few words, labeling every point can make it difficult to analyze the plot. If you want to instead label just a few points, you can reformat your code like below by calling the random number generator like we did with the PCA function (that code snippet is just below)
# 
#  ```python
#     # only label a random set of 25 points
#     import random
#     random.seed(0)
#     all_indices = list(range(len(labels)))
#     selected_indices = random.sample(all_indices, 25) # you can change this
#     for i in selected_indices:
#         plt.annotate(labels[i],
#                       xy=(x[i], y[i]),
#                       xytext=(5, 2),
#                       textcoords='offset points',
#                       ha='right',
#                       va='bottom')
#     
#   ```  

# In[ ]:


def tsne_some_points(model, focus_word = None, n = 50):
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
        
    plt.figure(figsize=(figure_height, figure_width)) 
    for i in range(len(x)):
        plt.scatter(x[i],y[i])
        
    # only label a random set of 25 points
    import random
    random.seed(0) 
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        plt.annotate(labels[i],
                      xy=(x[i], y[i]),
                      xytext=(5, 2),
                      textcoords='offset points',
                      ha='right',
                      va='bottom')
    plt.show()
    
tsne_some_points(model)


# And just like in the PCA example, below is a flavor of the tSNE code that will produce true random values every time you run it

# In[ ]:


def tsne_random(model, focus_word = None, n = 50):
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
        
    plt.figure(figsize=(figure_height, figure_width)) 
    for i in range(len(x)):
        plt.scatter(x[i],y[i])
        
    # only label a random set of 25 points
    import random
    random.seed() 
    all_indices = list(range(len(labels)))
    selected_indices = random.sample(all_indices, 25) # you can change this
    for i in selected_indices:
        plt.annotate(labels[i],
                      xy=(x[i], y[i]),
                      xytext=(5, 2),
                      textcoords='offset points',
                      ha='right',
                      va='bottom')
    plt.show()
    
tsne_random(model)


# ### Interpreting tSNE ###
# 
# There are a few important things to note about interpreting the results of a tSNE analysis. 
# 
# 1. tSNE is not deterministic, so your results may vary across runs of the same algorithm with the same settings. 
# 
# 2. tSNE tries to average cluster sizes, so clusters may appear to be the same size in a visualization of the analysis when in actuality, they can vary quite a bit in size. This means that you cannot determine the size of a cluster based on tSNE alone
# 
# 3. The distances between clusters may be meaningless. In addition, if you add new data to the corpus (for example if you retrain your word embedding model), you must also increase the perplexity in the tSNE analysis
# 
# The bottom line is tSNE will try to "clean up" its visualizations, so something that appears significant in the visualization may actually just be a result of this cleaning up. In order to get the most out of tSNE analysis, try running it multiple times and changing the hyperparameters. This will likely give you a more accurate picture of your data. 

# # Conclusion #
# 
# As you can see, word embedding models are fairly versatile and powerful. Not only do these models enable you to capture the semantic significance of words in any particular corpus, but when analysis techniques are applied such as k-means clustering, PCA, or tSNE, it becomes much for evident how useful word embedding models are for representing the complexities of natural language. 
# 
# While this walkthrough focused on a localized implementation of model analysis in Python, there are a number of tools online that are particularly useful for analyzing word embedding models. One tool in particular that is very useful is the [Tensorflow Projector](https://projector.tensorflow.org/). 
# 
# The Tensorflow Projector allows you to upload your model and produce interactive PCA and tSNE plots for your model. If you are interested in digging more deeply into the individual words reflected in tSNE or PCA, then the Projector is a great place to explore as its interactive features operate relatively quickly, even with large amounts of data. 
# 
# We also encourage you to continue learning about word embedding models through some of the great communities located in places such as StackOverflow. Mutual aid is an essential feature of the coding community, and you should feel comfortable participating in that community, even as a beginner programmer. As we hope this walkthrough has demonstrated, the best work in programming happens when programmers work together. 
# 
# And finally, while this walkthrough is focused on Word2Vec, we also want to point to the newer [Doc2Vec](https://radimrehurek.com/gensim/models/doc2vec.html) which can be implemented almost exactly how this walkthrough implements Word2Vec. Doc2Vec is a word embedding algorithm that produces vectors for sentences or entire documents by using something called "paragraph embeddings." If you are interested in training a model based on documents rather than individual words, we encourage you to check out Doc2Vec which comes preinstalled with Gensim. 
# 
# 
# _This walkthrough was written on July 29th, 2022 using Python 3.8.3, Gensim 4.2.0, and Scikit-learn 0.23.1_
