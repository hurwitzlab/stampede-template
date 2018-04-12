# Stampede2 Template

Here I will try to document how I create an app to run on the Stampede2 
cluster at TACC. This is by no means a definitive solution, it just seems to
work for me.

To begin, you will need accounts with Cyverse and TACC:

* http://cyverse.org
* https://portal.tacc.utexas.edu

It's not necessary to have the same username, but it is convenient.

In order to test your application, you will need to be added to the 
"iPlant-Collabs" allocation (what account to charge for the time your jobs
use on Stampede2). It's best to get on the Agave Slack channel
and talk to someone like Matt Vaughn or John Fonner. 

# Directories

I typically have these directories in each Github repo for my apps:

* scripts: code I write that I want to call in my app
* singularity: files to build the Singularity container
* stampede: files needed to create and kick off the app

Let's look at each in more detail.

## scripts

These are the Python/Perl/R programs I write that I will need to have
available inside the Singularity container. I tend to write "install.r" and
"requirements.txt" files to make it easier to install all the dependencies
for R and Python, respectively.

## singularity

Usually there are just two files here:

* image.def: Singularity recipe for building the image
* Makefile: commands to build the image

The "image.def" file contains all the directives like the base OS, the 
packages to install, the custom software to build, etc. In a weirdly circular
fashion, the Singularity image almost always clones the Github repo into the
image so that the "scripts" directory exists with the programs I'll call. 
With the Makefile, you can just `make img`.

## stampede(2)

Typically there are:

* app.json: JSON file to describe the app, inputs, and parameters
* template.sh: template file used to kick off the app
* test.sh: required but not used by Agave that I can tell
* run.sh: my usual way to run pipeline or just pass arguments
* Makefile: commonly used commands to save me typing
* MANIFEST: the list of the files I actually want uploaded

### app.json

The "app.json" file can be very tricky to create. TACC has created an 
interface to assist in getting this right, and I made my own, too:

* https://togo.agaveapi.co/app/#/apps/new
* http://test.hurwitzlab.org (The Appetizer)

The Agave ToGo interface requires a user to login first, and so one
advantage mine has (IMHO) is that it does not. The idea behind The 
Appetizer is to crowd-source the creation of new apps. If we can get 
users to help describe all the command-line options to some tool they
wish to integrate, then it saves us that much time.

You can copy and existing "app.json" from another app and edit it by
hand or paste it into the "Manual Edit" mode of the "JSON" tab in The
Appetizer. "Inputs" are assets (files/data) provided by the user which
must be copied to the compute node before the job begins. "Parameters" 
are options that are indicated, e.g., p-value or k-mer size, etc. Read
the "Help" tab on The Appetizer for more information.

### template.sh

This file will contain placeholders for each of the input/parameter 
`id`s that you define in the "app.json." These will be expanded at run
time into literal values passed from Agave. E.g., if you defined a "FILE"
input to have a "-f " prepended, then if the user provides "myinput.txt"
as the `FILE` argument, `${FILE}` will be turned into `-f myinput.txt`.
If you change anything in the "app.json," be sure to update "template.sh" 
so that the argument is represented in the "template.sh" file.

The template can pass the users arguments to any program you like. I tend 
to always write a "run.sh" script that is my main entry point. I use bash
because it has no dependencies and is simple but powerful enough for most
apps. You could instead call a Python program that exists in your Singularity
container, but I wouldn't attempt using Python directly on the compute node
as you couldn't be sure you have the right version and any dependencies you
might need, esp. if the app is made public and therefore runs under a 
different user.

### test.sh

I don't know why this is required, but it is. I often will indicate some
test data I have and will `sbatch` this file to ensure my pipeline works.

### run.sh

As I said, you don't have to use bash as the main entry point, but it's 
often sufficient. I have many examples where I write entire pipelines in 
bash (fizkin) and others where I merely pass all the arguments to some 
more capable program (graftM).

### Makefile

To test and build an app, I will do the same steps repeatedly, so I 
tend to put them here so I can, e.g., `make clean` to get rid of previous
runs, `make app` to submit the "app.json," `make up` to upload the assets
into the execution system.

### MANIFEST

The only files required to exist in the execution system are the "template"
and "test" files you indicate in the "app.json." After that, you need to also
include the Singularity image and any other programs that are referenced,
e.g., "template.sh" might call "run.sh." I have a program called 
"copy_from_manifest.py" that looks for the "MANIFEST" and only uploads those
files into the proper "applications" directory. FWIW, I also have a simple
bash program called "upload-file.sh" that deletes a file before uploading it
as I have had problems with Agave actually merging my new and old files into
and unusable mishmash.

# Author

Ken Youens-Clark <kyclark@email.arizona.edu>
