Contains files used to run the demo for user testing
Most of this is utter garbage, and quick fixes just to get it working for the day
There were minor fixes to the frontend, as when this branch was made for some reason it wasnt recieving data properly, but these aren't worth documenting as they have since been fixed properly
Lots of hardcoded file paths for my pc so these wont run here
As such these are all designed to be run from specific locations:

runDemo.py should be run from /backend/ and is a modified version of run.py from the same directory, but using hardcoded directory paths, and with the ability to pass in different user generated demo files

DemoParser.py is a modified version of MoTecCSVParser.py withsimilar updates to above

DemoCSVs contains user generated data, and a txt file used in runDemo.py to determine which file to use automatically