# Stampede Template

If you look in the "stampede" dir, you'll find there is a "00-controller.sh"
script that is meant to drive the whole pipeline.  You have to figure out which
steps are the blocks, that is, the parts that have to be completed entirely
before the next step can happen.  Each blocking step becomes an "01-foo.sh,"
"02-bar.sh" script that will, in turn, probably call something in the "scripts"
dir to do the dirty work.  If that script needs to process loads of things,
then it itself submit parametric job (job array); otherwise, it will just do
its thing.  

Thanks to examples from Matt Vaughn and help from Greg Zynda.

# Notes

## 00-controller.sh

You will need to add your arguments and command-line flags, update the 
HELP function, add the "export" commands to the config, etc.  

## 01-foo.sh

Create your steps as 01, 02, 03, etc., for each step that needs to complete
before the next.  Use "01-foo.sh" as a template.  I usually just change the 
last line to launch something in the "scripts" dir passing whatever arguments
necessary.

## Makefile

You should set your email address at the top if you would like to get messages
when your jobs start/stop/fail.  You can add targets to help your testing, e.g.,
I put a "foo" target to "-r" run just the "01-foo.sh" step in the "development"
queue (gets picked up much faster than "normal") for the maximum of "-t" 2 hours
time.  You will find "make clean" is handy to clean up all the temporary files
that are created.

## app.json

An example of the JSON to describe your app which can be submitted to 
"apps-update -F app.json".

## foo-template.sh

A way to pass the arguments from Discovery Environment to the controller, 
referenced in the "app.json," so change that if when you change this file name.

## test-foo.sh

The "app.json" wants a simple test shell script, so this is an example.  Also
referenced in the "app.json," so change that if when you change this file name.

## "bin" dir

If you need binaries not availble as modules (e.g., "module spider foo" to see
if it's available), then you can build them into "stampede/bin" for use on 
your nodes.

# Author

Ken Youens-Clark <kyclark@email.arizona.edu>
