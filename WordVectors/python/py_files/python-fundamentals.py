#!/usr/bin/env python
# coding: utf-8

# # Introduction to Python

# Author: Avery Blankenship
# 
# Date: 9/6/23
# 
# ---
# 

# ## Using Jupyter Notebooks

# There are a few things worth noting about Jupyter Notebooks before proceeding with the rest of this tutorial. First, one of most prominent features of Jupyter Notebooks is that it seamlessly combines text and executable code. This feature makes Jupyter Notebooks an ideal environment in which to learn Python. Because Jupyter Notebooks are structured around text and chunks of code, you are able to run code in isolated sections. I recommend taking this approach as you proceed with the tutorial as it will allow you to test things out in bits and pieces in order to ensure that you really understand how the code is working before moving on.
# 
# In order to run a code snippet, click the box where the code is and then click the "Run" button on the toolbar at the top. Try running this code snippet below:

# In[ ]:


print("I am a code snippet")


# If everything is working like it should, you should see the phrase "I am a code snippet" appear just below the print statement. 
# 
# Anther option for running a code cell is to click within the cell and then hit Control/Command + Enter.
# 
# Some other buttons/features to note are: 
# 
# - The stop button on the toolbar halts whatever code is currently running. This may be useful if in cases where, for example, you mistakenly tell the code to iterate over the wrong data set. 
# - Right next to the stop button, is the restart button. This button will halt whatever code is currently running and then restart the kernel.
# - Next to the refresh button is the restart and run button. This button will both restart the kernel and run the entire notebook. 
# 
# You can save a Jupyter Notebook by navigating to the "File" menu on the toolbar and then to "Save". Alternatively, you can save by directly clicking the "Save" button on the toolbar, or hitting Control/Command + S.

# ## Working in Python

# It's worth noting some of the key features that distinguish Python from other programming languages. Unlike languages such as Java or C++, Python has a relatively forgiving syntax which is designed to be easy to learn. This means that some of the rigid requirements of other programming languages, for instance requiring that you declare variables before you can use them or wrap all code in curly braces `{}` or a semicolon `;`, is not required in Python. This flexibility makes Python an ideal beginner-friendly programming language.

# In[ ]:


print("hello world")


# For instance, look at the line of code above. Even if you don't know any Python, you can probably tell what the code does: it prints the phrase "hello world." You'll likely find that much of Python is just as readable as this "hello world" program. 

# This tutorial is going to assume that you may have some light exposure to code, but no substantial experience in Python. For this reason, there are a couple of terms and features which may be useful to define for you up front. First, it is important to note that when you are running Python code, even in Jupyter Notebooks, the computer executes one line at time, starting from the top and working its way down the file. The code will be executed one line at a time until it either hits an error or it reaches the end of the file. The same is true in Jupyter Notebooks with the exception that code cells are treated as somewhat distinct "files." This means that Jupyter Notebooks will stop running an individual code cell if it hits an error, but this error wouldn't prevent you from running subsequent code cells. It is important to understand this one-line-at-a-time execution for debugging purposes. If you are running a snippet of code and the output looks strange to you, you may want to debug the code by working through the file one line at a time in order to reproduce this strange output. Similarly, understanding that Python is executed from a top-to-bottom approach is important as you are declaring variables, functions, etc. 
# 
# The code only has access to the lines it has already encountered. In programming circles, this type of language is called an **interpreted** language. Other languages such as Java and C++ are **compiled languages** which means that they don't run a single line at a time, they **compile** all of the code, and then execute it. Because Python is an interpreted language, it tends to be a bit slower than something like C++ and Java, but it has the benefit of being easier to debug. Interpreted languages are what make this Jupyter Notebook possible. Rather than rerunning all of the code at once, interpreted languages allow you to run a line at a time and run code at your own pace.
# 
# Let's look at these lines of code for example:

# In[ ]:


x = 2
x = 4 + 1
x = x / 2
print (x)


# In[ ]:


x = 4 + 1
x = 2
x = x / 2
print (x)


# As you can see, because Python executes one line at a time, the output changes, depending on the order.
# 
# In the first example:
# * First, the value of the variable `x` is set to `2` 
# * Then, `x` is overwritten, and reset to have the value `4 + 1`
# * Finally, that value is divided by 2. 
# 
# in the first example,the variable `x` is being set to `2` in the first line, is being reset to `4 + 1` in line two and finally, that value is divided by 2. In the second example, `x` is set to `4 + 1`, is reset to `2` in line two, and then is divided by 2. Although both examples use the same formulas, because they are ordered differently, the final value of `x` differs. If you are writing code that uses a lot of variables, it can even be helpful to keep a list of your variables and what their current values are (or at least are supposed to be) at different key points in the code.
# 
# Note that I didn't need to tell the computer what type of variable `x` is, it decided for itself based on the information I provided it about `x` (in this case that the value of `x` is an integer). In programming circles, this tendency of Python to determine variable types for itself is called "duck typing." "Duck typing" is when a program assumes that if it looks like a duck and sounds like a duck, it is probably a duck—or in this case an integer. 
# 

# ## Other Environments

# Although this tutorial is going to take place in Jupyter Notebooks, it's still a good idea to know about other environments for working in Python. An 'environment' is some place on your computer where the Python interpreter as well as libraries and scripts are installed so that you can run Python code. 
# 
# Let's walk through two particularly popular Python environments: IDLE and Spyder.
# 
# [**IDLE**](https://docs.python.org/3/library/idle.html) (Integrated Development and Learning Environment) is an environment that you can download directly from Python's website. IDLE comes bundled with Python—if you have Python installed, you have IDLE! The IDLE interface is very simple. You write code in one window that resembles a text editor, and when you run the code, the output appears in a separate window. Because of IDLE's minimalist design, it can be a great environment for beginners. However, one downside to IDLE is that many libraries don't come pre-installed, so there is slightly more pre-work required for code that involves libraries. IDLE generally is a good place to get a handle on the basics *because* it requires you to do more of this sort of work, though once you become more familiar with Python, you will likely want to switch to a different environment that offers more features. 
# 
# [**Spyder**](https://docs.spyder-ide.org/current/installation.html), on the other hand, is an environment that comes as part of Anaconda, a data science platform that comes with many environments (such as Jupyter Notebooks) installed. The benefit of using Spyder, or Anaconda in general, is that Anaconda makes installing libraries very easy, and in fact many libraries come pre-installed. Spyder is particularly popular for machine learning, natural language processing, and other methodologies that involve working with lots of data or natural language. One reason for its popularity is that Spyder makes debugging code very simple by allowing you to run your code one line at a time. However, the tradeoff is that Spyder has many more buttons than IDLE so it can take some time getting used to navigating all of the settings. 
# 
# All of the code written in this tutorial can run in either of these environments, so if you want to do some fiddling on your own or just play around with the code in order to become more familiar with Python, try installing either IDLE or Spyder.
# 
# As I mentioned above, a very popular distribution of the Python and R programming languages is [**Anaconda**](https://docs.anaconda.com/). Anaconda is not quite the same thing as a programming environment because in addition to installing Python and R onto your machine, Anaconda comes with cloud storage (Anaconda Cloud), a navigation system to easily switch between platforms or environments (Anaconda Navigator), and its own package manager (Conda). The benefit of working in Anaconda, is that Anaconda is designed to make science or research computing very straightforward and protective. Essentially, by using the Anaconda Navigator and the Conda package manager, you are much less likely to install a library or package that could potentially damage your computer (as is a risk with using `pip` to install and manage packages). In a way, Anaconda is a way of using programming languages to run research-based or experimental code with bubblewrap around your machine. 
# 
# Another benefit of using Anaconda is that Anaconda comes with many popular environments as well as libraries and packages already installed! For instance, when you download Anaconda, you are also downloading Spyder, Jupyter Notebooks, and RStudio. Many of the libraries and packages we will be using in these tutorials come preinstalled with Anaconda. Because Anaconda uses their Conda package manager and the Anaconda Navigator, there is no need to navigate through the command line to perform basic installation tasks. Conda will even check if any of the packages you want to download conflict with packages you already have installed!
# 
# While you certainly can work in Python without using Anaconda, Anaconda is very friendly for beginners and may help to make learning Python a little less intimidating. 

# ## Variables

# Much of running code comprises manipulating data that is stored within a container called a **variable**. Just like in math, variables allow us to store some type of information for later use. Using variables can save you a lot of time since instead of having to type out long lines of code every time we need access to a calculation or a string, for example, we can just store the data within a variable. Variables are also how the computer keeps track of how data changes. The computer is only aware of and can only recall data that is stored in a variable. 
# 
# In Python, you don't need to tell the computer about your variables before you use them. In other languages, this is called *declaring* a variable. Instead, you can just start using your variables like empty boxes whenever you need one. For example, above, I didn't need to tell the computer about the variable `x`, I was able to just tell the computer what `x` *is*. In another language, for example JavaScript, you would need to specify that `x` was a variable of the type `integer` before being able to use it. 

# Variable names work the same way filenames work on a computer. A good variable name is concise, descriptive, and doesn't include any special characters or spaces. Ideally, any programmer should be able to open your code and understand what the purpose of a variable is based on its name alone. The only exception is when you are using a variable a single time to briefly hold a value before moving it, or in cases where the function call asks that the variable name be something specific. For example, many functions used for graphing like for users to refer to `axis` as `ax`. In most of these cases, you can still use the full word `axis` but you will likely notice in the documentation for that function, that the creators use the abbreviated variables. In any case, you should use variable names that are useful and make sense to you and try to avoid names that will only lead to confusion down the road.  Instead of spaces, many programmers make use of underscores or variations in capitalization (called camel case). 
# 
# Let's try to declare our own variable.

# In[ ]:


myVariable = 2
print(myVariable)


# This time, you should see the number 2 displayed.
# 
# Importantly, you can overwrite the contents of a variable by simply setting the variable equal to some new value. You don't need to delete or tell the computer to discard the old value. Think of the computer as having complete faith in whatever you tell it: if you tell the computer that `x = 2` then the computer is going to believe you, regardless of whatever value `x` may have held before. 

# In[ ]:


x = 2 

x = 4

print(x)


# As you can see, since Python interprets code one line at a time, the computer simply forgets that `x` was ever equal to the number 2 and will print the number 4 when you ask it to print the contents of `x`.

# ## Functions

# Next, we will discuss what a *function* is and how to make one. As stated above, a function is essentially a recipe for some task that you want the computer to complete. Functions allow you to store code for later recall. With a function, you only need to run a single line of code rather than pasting the contents of the function every time you need to access that code. When you import a library, you are essentially importing a bunch of functions which makes recalling them even easier.
# 
# We've already talked about how to import a function, but now let's briefly walk through how to make your own functions. Generally, functions follow the same formulation which includes a name, a set of parameters, and a definition. 
# 
# - **Name**. When you give your function a name, you are telling your computer how you would like your code to be referenced. You will use this name any time you want to call your function. 
# - **Parameters**. A parameter is the set of variables required for a function to run, defined in the actual function definition. The actual data that you provide a function are called arguments. For instance, recall that `print()` is a built in function. The parenthesis next to the name `print` is where you would place the arguments for the function. In this case, the parameter for the `print()` is either a variable or a literal statement. Since `print()` prints its arguments to the console, it accepts most variables and strings as a parameter argument. So for instance, if you wanted to print the words "hello world" you would call `print()` using `print("hello world")`. 
# - **Definition**. A function definition is the actual recipe for the function itself: it's the code that tells the computer what to do when you call the function. To define a function, you use the `def` call, a colon after the function's name, and indent one level for the definition.
# 
# In the code block below, let's make a simple function that will add two parameters, and then print the results. 

# In[ ]:


def add_function(parameter1, parameter2):
    result = parameter1 + parameter2
    print(result)


# Now, if we want to use our function, we just need to call it with the correct parameter arguments. Note: if there are any mistakes in the code within your function definition, those mistakes will only throw an error message once you actually use the function.

# In[ ]:


add_function(1, 12)


# The line of code above will execute the contents of `add_function()` so that we don't need to type out the code every time we need to use it. 
# 
# It is also useful to understand how variables are modified within a function. When you use a variable within a function, that variable *only* exists within the world of the function. This means that I can't suddenly start using the `result` variable in the rest of my code. The only way you can give the rest of the code access to a variable from within a function is to `return` it, meaning that you end your function definition by including a line like below:
# 
# ```python
# return results
# ```
# 
# This line tells the computer that you want the **local** variable `result` to become a **global** variable, meaning that all of the code can access it, not just the code within the function. Another important feature to note is that when you use a `return` statement at the end of a function, unless you store the contents of `return` within a variable, the computer can't access it. All data that you want to be able to access has to be stored in a variable of some type in order for the computer to know it exists. In the case of a `return` statement at the end of a function, you can set a variable equal to the function call, itself, and this will result in the variable holding the content of the `return` statement like below:
# 
# ```python
# variable = some_function(parameter)
# ```
# 
# Let's look at an example below.

# In[ ]:


x = 1

def change_x(parameter):
    x = 12
    return x

print("the variable x is equal to", x)


# You may be wondering why `x` is not equal to the value 12 when our function above is supposed to change `x` to 12 and then return that variable. Remember, the code is only aware of functions and their code once you actually use the function. Here, we have defined a function `change_x()` but we haven't actually called it, yet, so the code has yet to be executed. Let's try again, but this time let's call the function.

# In[ ]:


x = 1

def change_x(parameter):
    x = 12
    return x

x = change_x(x)

print("the variable x is equal to", x)


# You should now see the number 12 displayed since the variable `x` has been modified within the function, and we returned that version of `x` and overwrote the existing `x` with our new value.

# ## Libraries

# At this point, you may be wondering: what exactly is a library? Essentially, a library in Python is like a recipe book for a bunch of different functions. When you import a library, all you are asking Python to do is access the code within that library that will tell Python how to make certain functions work. For example, the `string` library includes a bunch of functions that make working with strings much easier. Above, we used the `os` library which makes working with operating system functions easier. In short, a library allows you to use functions that don't automatically come with Python.
# 
# A function that *does* automatically come with Python is called a *built in* function. A built in function is a function that will work even without importing libraries. For example, the `print()` function comes automatically with Python and you don't need to import anything to make it work. 
# 
# It's a good practice to keep all of your library imports at the top of your code. Because Python is *not* a compiled language, the code will always run from top to bottom. This means that Python has access to code in the order you write it. Keeping all of your import calls at the top of the code ensures that the computer will have steady access to those libraries throughout the code without you having to keep track of when a particular line would require a library to be imported.
# 
# In the code block below, you will see that we are using `import` to import the `string` library.

# In[ ]:


import string


# Another popular way to import a library, is to import it as a variable. Basically, this process is like giving the library a nickname. When you nickname a library, any time you need to access functions within that library, you just need to use the nickname instead of the entire name of the library every time.

# In[ ]:


import pandas as pd

dataframe = pd.DataFrame()
print(dataframe)


# Finally, another useful trick for importing libraries, is that if you only need a single function or set of functions from a library, you can just import that section of the library rather than the entire library. Importing only what you need ensures that you are being memory efficient and will lessen the burden on your computer. Saving memory becomes more and more important the more you work with larger and larger sets of data. In the example below, we import *only* the `DataFrame` function from the library `pandas` and then we also decide to nickname that function `df`. This means that when we want to make a new dataframe, we only need to use `df()` rather than `pd.DataFrame()` or `pandas.DataFrame()`. However, importing only the `DataFrame()` function means that the computer only has access to that specific `pandas` function.

# In[ ]:


from pandas import DataFrame as df

dataframe = df()
print(dataframe)


# Some functions come pre-installed with Python. This is not the same thing as a function being built in. A built in function is a function that you don't need to import. When a function is *installed* that means that Python has access to all of the code that makes up that library, but the library likely still needs to be imported to actually work. 
# 
# One way to make sure you are downloading a library safely, is to download the library through the [Python Package Index](https://pypi.org/project/pip/) (via pip) or through [Anaconda](https://anaconda.org/conda-forge) (via conda).
# 
# You can download libraries from all sorts of places, including Github. However, be careful when you are downloading a library to make sure it comes from a reputable source. If you are using Anaconda, one way to make sure you are downloading a library safely, is to download the library through Anaconda itself. If a library is in the Anaconda database, then you can be confident that it won't break your computer. You can read about how to use Anaconda's database to install libraries in [Anaconda's documentation](https://docs.anaconda.com/anaconda/user-guide/tasks/install-packages/). Generally, when you search for a function on Anaconda's website, Anaconda will provide you with the correct call to use in order to install it. 
# 
# If you are using pip to install a library, you may need to exercise slightly more caution because unlike Conda, pip does not separate packages and libraries into isolated environments. In Python, you can create something called an *environment* which is essentially a decorated house that will run the code you put in the house in a way that is separated from all your other code. Each environment is separate from other environments and each of these environments preserve a specific state of python (including the libraries that were installed and even the version of Python that was used).
# 
# Think of environments like a neighborhood of houses and some of your code lives in these houses. You can "decorate" your house with different libraries and packages, but the environment preserves the state that Python was in when you wrote the code. With Conda, packages are isolated into whatever the coding environment was set to when you installed the package whereas pip does not isolate packages or libraries because pip does not manage environments. Pip can "purchase" the decorations, but can't actually put them in the houses. With Conda, you can not only have separate houses but different kinds of decorations in those houses because Conda is both a library and environment manager. With pip, all the houses are decorated in the same way and you would need a separate environment manager to actually decorate.
# 
# This distinction may not actually matter to you depending on what kind of code you are running, but may also come in handy when installing more unstable packages or running risky code. The benefit of using pip, however, is that pip runs about six times fast than Conda and isn't as restrictive about what libraries and packages you can download, though it is not language agnostic like Conda.
# 

# ## Debugging in Python

# It is useful to know how to debug in Python before getting too deep into any code. As explained above, Python is an **interpreted** language which means that rather than compiling code before executing it, Python interprets code one line at a time. Python's status as an interpreted language makes debugging much easier because the code will simply stop running or print an error when it reaches the problem line. 
# 
# There are a couple of different ways that you can approach debugging in Python and some of these methods will also depend on the environment that you are using to code. 
# 
# ### Using Print Statements
# 
# Another approach to debugging is to place print statements throughout your code to keep track of what's running and what isn't. 
# 
# For an example of what this might look like in action, read through the code below. First, we define variables for `x` and `y` and then we ask whether `x` and `y` are equal with the **comparison operator** `==`.
# 
# Even if you've never seen code like this before, what do you think will happen when you run the code cell?
# 
# 
# 

# In[ ]:


x = 2
y = 1

if x == y:
    print("I made it here")
    print(x)
    print(y)
    
else:
    print("something is wrong")
    print(x)


# Now, try changing the value of `y` to 2 or 2.0 and run the code again. 
# 
# It is important to keep in mind that Python files or code snippets run until they hit an error. If there is an error in a loop, the code will sometimes run indefinitely. 

# ### Built in Debugger
# 
# Another way to debug your code is to use the built in debugger. The debugger works by allowing you to place what are called breakpoints at critical places in the code. The debugger will run until it reaches one of these breakpoints which can quickly help you identify the places where the code isn't working based on when the code fails between breakpoints. The output of the debugger tells us that there is a break point that has been placed in the code, as well as where that point is and then printing the code that has not been executed yet. For a tutorial on how to use the debugger, this [Tutorials Point tutorial](https://www.tutorialspoint.com/the-python-debugger-pdb) is a great introductory piece and so is this [RealPython tutorial](https://realpython.com/python-debugging-pdb/).
# 
# The debugger is ideally run in the Command Line. The Command Line is the text-based interface through which a user is allowed to control their computer. Anaconda, handily, comes with its own version of the Command Line called the Anaconda Prompt. When you run the debugger from the Command Line, the break point is automatically placed at the first line in your code. There are some great resources out there if you want to read more about [using the debugger in the Command Line](https://hub.packtpub.com/debugging-and-profiling-python-scripts-tutorial/).
# 

# ## Navigating to Your Working Directory

# Often, you will need to know what folders on your computer Python has access to. Folders are often referred to as **directories** and the folder that is automatically opened when Python runs is called your **current working directory**. Python will treat your current working directory as the starting point when you navigate to any files on your system. 
# 
# This means that if you open or close any files, you don't need to specify a full file path. Instead, you can use a **relative** path that starts from your current working directory. For example, if your working directory were your Documents folder, and you wanted to get to a file called "mydocument.txt" that was directly in that folder, you could reference that file by writing just: "mydocument.txt"
# 
# However, if your document were inside a folder called "myfolder" that was itself inside of your Documents folder, you would need: "myfolder/mydocument.txt"
# 
# This sounds a little complicated, but Python has a trick you can use. For any places where you are trying to fill in a file path, try hitting `tab` and that should show you a menu of files and folders you can browse.
# 
# Below is a code snippet that will allow you to get the file path for your current working directory. We are going to import the `os` library which will give us access to the `getcwd()` function. This function will return the full file path for your current working directory. 

# In[ ]:


import os 
os.getcwd()


# If you wanted to change your current working directory, you would use the `chdir()` function which comes with the `os` library. This function accepts a file path as its input.
# 
# `os.chdir('SOME FILE PATH')`

# if you are using a Windows computer, you may get a unicode error informing you that bytes can't be decoded. That is totally fine and normal! All you need to do is add an additional backslash to your file path so that each of the backslashes are escaped. It would look something like this:
# 
# `"C:\\users\\admin\\Desktop"`

# If you were to restart the Python shell or kernel, your current working directory would be changed back to the default. You can read more about working directories in this [`os` tutorial](https://data-flair.training/blogs/python-directory).

# ## Final Thoughts

# If any of this is still confusing to you and you are feeling lost, that is totally fine and normal! Just like spoken languages, you don't typically learn it all in one day. And also just like learning a new language, it's important to understand what your ultimate learning goals are: are you trying to become fluent or do you just want to be able to travel comfortably? Do you want to become a programmer or do you just want to know how to fix a few bugs and edit? The answer to that question will likely determine how intensely you immerse yourself as well as the community groups you form and join. 
# 
# Even seasoned Python pros often find themselves looking up the basics like how to define a function or what the name of a library is. One of the most valuable skills that you can have as a coder is to be willing to ask for help when you need it. The community around Python is very welcoming and active and you shouldn't feel shy about asking some more seasoned coders for advice or feedback—after all, most coding happens in groups!
# 
# If you want to learn more about Python, you should check out [W3Schools](https://www.w3schools.com/python/python_intro.asp) which offers a comprehensive tutorial for using Python as well as quick references. If you are looking for a community board for asking questions, [Stack Overflow](https://stackoverflow.com/questions/tagged/python) is the standard site used for most programming languages. 
