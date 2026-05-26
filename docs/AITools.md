# AI in 2025-F1 AI Commentary
===========================

## Overview:
Below we provide a detailed breakdown of AI tool usage within this project. In accordance with the units AI policy, we have included; general usage,
tools used, example prompts. In addition to this, we have provided a detailed breakdown of the tools used and reasons for usage by each team member.


## AI tools have been used in the following ways:
    - Help with speedy prototyping to explore possibilities of new technologies and softwares before we commit to adding them, enhancing productivity and reducing wasted time.
    - Help with debugging certain sections of code
    - Help with writing comments to help others better understand code
    - Help with spotting less obvious errors in code
    - Help with reviewing PRs
    - Help to spot gaps in test coverage
    - Help learning new languages
    - Used as a fundamental part of our project to develop AI commentary

## AI tools used:

**Github Copilot:** 
    - Used in pull requests to generate quick overviews of PR (see pull requests for examples)
    - Tracked as having commits due to letting it quick fix pull request code for syntax etc
    - Adding comments to functions

**OpenAI API:**
    - Used generate the commentary based of telemetry.

**ElevenLabs:**
    - Used to convert text input into speech based on a prompt.

**Cursor:**
    - Used to help explore possibilities of data usage in the FastF1 API
    - Used to help generate graphs and visuals for FastF1 telemetry

**Claude:**
    - Used to help spot gaps in our test coverage
    - Used to help resolve errors in code quickly

**ChatGPT:**
    - Used to help spot less obvious errors in others PRs
    - Used to generate testing day poster

**ClaudeCode CLI:**
    - Used sheerly out of interest, no changes really made to code

## Example prompts:
    - "I have spotted A B C issues with this PR from my team mate which I think will cause X Y Z issues.
       Am I missing anything else?"
    - "I have not been able to spot any issues with this PR, please do a snity check for me to ensure I 
       am correct"
    - "I have written this comment to explain my code to my teammate, however i believe it could be altered
       for additional clarity without altering the unbderlying struture, please re-write for clarity and understanding"
    - "Create a gripping poster for 'F1 AI commentary', it's for our testing day to attract people to our stall."
    - "As a team we are consiering migrating our primary data source over to the FastF1 API. Help us to decide the pros 
       and cons of this. Factor in things such as data availibility, ease of use etc"
    - "Create me a roadmap to help learn new language X, include a detailed breakdown of each step of learning and 
       link useful rescouces"

## Specifics per person
### Felix
**Tools used**
- Claude
- Cursor

**Where did you use AI tools and why**
Research and Learning - I utilsed ChatGPT to help create a roadmap to learn new laungauges and tools in the most
                        efficient way possible. It also helped to explain other code for me in instnaces where I 
                        was not totally sure of my understanding.

Prototyping - I used Claude to help delve into what is possible in terms of switching over to FastF1. Fast an efficient 
              prototyping helped save lots of time and make quick and informed decisions moving forwards.

Frontend - I utilised claude to help me plan the best way to redesign the front end. I prompted it with a detailed 
           description of my vision for the front end and asked it to analsyse other modern websites, and critque my idea
           such that i could improve upon it before implementing any changes. This saved me time prototyping and resulted
           in a better looking frontend. 
           I encountered several issues when updating the frontend, one of which being widget placement issues, and track 
           heatmap issues. I utilised cursor to help me spot what I was missing, and where I was going wrong. In the
           case of the track heatmap, I also asked it to walk me through, in detail, step by step the best way to fix it.

Backend - I utilised cursor to help identify the best places to implement backend tests to increase test coverage.

### Kyrian
**Tools used**
- Github Copilot
- Gemini
- Nano Banana Pro

**Where did you use AI tools and why**
Research and Learning
- Used Gemini to initially research Python docs for FastF1, as well as webhook best practices.
- Used GitHub Copilot as a commentator on pull requests, summarising changes completed as well as suggesting code changes.

Prototyping
- Used Copilot to create mock html pages to test backend output (ensuring that the webhook was connected and sending the data as intended).
- Used Copilot to discuss the benefits of an AI commentary system based on a single snapshot (as was done before) vs the entire dataset being preloaded into the commentary.

Frontend
- Documentation site images - AI generated apart from logo
Backend
- Copilot (development) - Asked to add type hints to pydantic classes as required.
- Copilot - Pyproject config for Async Tests (asked how to not have to repeat mark.async)
- AI generated API reference for the docs/handover website
- Fixing cache consistency issues due to asynchronous python methods
- Generation of extensive tests that were manually verified
- Generation of Flutter upload page as little flutter experience at this point and little time to learn before submission.
### Leo
**Tools used**
- Claude
- ChatGPT

**Where did you use AI tools and why**
Research and Learning - Used to help understand and learn flutter.

Prototyping - Used ChatGPT to help generate mock up front ends. This helped reduce mistakes.

Frontend - Used Claude to fine-tune widgets

Backend - N/A


### Callum
**Tools used**
- ChatGPT
- Claude

**Where did you use AI tools and why**
Research and Learning
- Used ChatGPT when learning how to use flutter and dart. 
- Helped with figuring out the structure of/how to use a flutter project.
- Helped get to grips with dart syntax.

Prototyping
- ChatGPT helped come up with suggestions for a wider range of flutter tests.
- Used Claude to help direct most frontend tests
- Especially helpful for churning out lots of small tests to target particular sections of the code

Frontend
- Having never used flutter, I needed the help with understanding the project structure and how to run it.
- Same with dart, ChatGPT helped me understand and troubleshoot the syntax.

Backend
- Used ChatGPT to troubleshoot the demo, and help come up with suggestions to streamline it.

### Ella
**Tools used**
- Claude
- ChatGPT

**Where did you use AI tools and why**
Research and Learning - I used ChatGPT to reasearch and help my understanding with FastF1 documentation

Prototyping - I used ChatGPT to help learn more about each F1 commentator, to help prompt our commentary agent to produce accurate commentary

Frontend - N/A

Backend - OpenAi is used to generate commentary from telemetry on the backend




