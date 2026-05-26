# 🏎️ F1-Style AI Commentary

<p align="center">
  A <b>realtime multimodal LLM analysis</b> dashboard to review and enjoy racing in a new format.
</p>

<p align="center">
  <b>In partnership with</b><br>
  <a href="https://www.ibm.com/">
    <img src="docs/ReadMeImages/ibm_logo.svg" alt="IBM Logo" width="220">
  </a>
</p>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Python](https://img.shields.io/badge/Python-FFD43B?style=for-the-badge&logo=python&logoColor=blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Android Studio](https://img.shields.io/badge/Android_Studio-3DDC84?style=for-the-badge&logo=android-studio&logoColor=white)](https://developer.android.com/studio)
[![Xcode](https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://www.nginx.com/)
[![App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/gb/app/marine-conservation-app/id6477784808)
[![Google Play](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![ChatGPT](https://img.shields.io/badge/chatGPT-74aa9c?style=for-the-badge&logo=openai&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
---
[![Deploy Backend](https://github.com/spe-uob/2025-F1AICommentary/actions/workflows/cd-aws.yml/badge.svg)](https://github.com/spe-uob/2025-F1AICommentary/actions/workflows/cd-aws.yml)
[![Deploy Flutter Frontend](https://github.com/spe-uob/2025-F1AICommentary/actions/workflows/deploy-frontend.yml/badge.svg)](https://github.com/spe-uob/2025-F1AICommentary/actions/workflows/deploy-frontend.yml)
---
##  Contents
- [Documentation](#documentation)  
- [Project Structure](#project-structure)
- [Project Introduction](#project-introduction) 
- [Key Features](#key-features)  
- [Stakeholders](#stakeholders)  
- [User Stories](#user-stories)  
- [Tech Stack](#tech-stack)  
- [Getting Started](#getting-started) 
- [Continuous Integration](#continuous-integration)
- [Continuous Deployment](#continuous-deployment) 
- [Ethics](#ethics)  
- [Group Members](#group-members)  
- [Supporting Mentor](#supporting-mentor)  

---

##  Documentation
- [Kanban Board](https://github.com/orgs/spe-uob/projects/350)  
- [Pull Requests](https://github.com/spe-uob/2025-F1AICommentary/pulls)  
- [Documentation website](https://docs.f1aicommentary.co.uk/docs/intro)
###  Project Structure
```tree
 2025-F1AICommentary
    ├── backend
    ├── docs
    ├── frontend
    └── telemetry

```
---

##  Project Introduction
This project transforms raw automotive telemetry into an **F1-style race replay experience**.  
We will take datasets e.g. **KIT OBD-II Dataset** or **Asseto Corsa csv files** as a stand-in for real telemetry, and applies **Realtime Multimodal Analysis** to generate natural, live-sounding race commentary, held on a play-back engine such as:  

> “Driver hits 6,500 RPM — late braking into Turn 3!”  

This would allow one to skip to certain points in the race, or adjust playback speed with audio and visuals being synced to time location they desire. Whilst also showing more detailed, instantly updated graphs displaying the most relevant information at the same time. The goal is to simulate the excitement of Formula 1 whilst also providing more detailed and specific information, by combining telemetry graphs, AI commentary, and playback controls in a single cross-platform app from one preloaded file (mobile, web, desktop).

---
##  Key Features

### Playback Engine
- **Time-series replay** of telemetry data with synchronized audio/visual output
- **Playback controls**: play, pause, reset, and speed adjustment (0.5x - 4x)
- **Timeline scrubbing** to jump to any point in the race
- **Real-time data streaming** via WebSocket connections

### Telemetry Visualization
- **Live telemetry graphs** showing RPM, speed, throttle, brake pressure, and more
- **Multi-channel display** with synchronized data across all metrics
- **Brake temperature monitoring** for all four wheels
- **Fuel level and lap time tracking**

### AI-Powered Commentary
- **OpenAI API** for natural, live-style race commentary
- **Dual commentary modes**: 
  - Driver-specific analysis for detailed telemetry insights
- **Context-aware narration** based on real-time telemetry patterns
- **Unbiased, data-driven** commentary using objective metrics

### Race Data Support
- **Telemetry** from Assetto Corsa and similar sources
- **Assetto Corsa CSV files** for sim racing analysis
- **Multiple track support** with circuit selection
- **Metadata tracking** for venue, vehicle, and session information
- **Fastf1** for real race data that goes back years

### Cross-Platform Support
- **Flutter frontend** for mobile (iOS/Android), web, and desktop
- **FastAPI backend** for high-performance data streaming
- **Responsive design** adapting to different screen sizes and devices

### User-Centric Design
- **Configurable data complexity** based on user expertise level
- **Interactive controls** with intuitive UI/UX
- **Educational focus** to help fans understand racing strategy and technique
- **Second screen capability** for use alongside live race viewing

---

##  Stakeholders

- **IBM (Client)**  
  - **Stake**: Showcasing OpenAI API capabilities in real-world applications; brand visibility in academic/motorsport space.  
  - **Interest**: Demonstrating their AI technology's practical use cases and fostering relationships with future tech talent.

- **University Staff**  
  - **Stake**: Ensuring project meets academic standards and learning outcomes for software engineering curriculum.  
  - **Interest**: Student development, project quality assessment, and maintaining university-industry partnerships.

- **Students (Development Team)**  
  - **Stake**: Hands-on experience with AI/ML, API integration, and full-stack development; portfolio project for future careers.  
  - **Interest**: Learning enterprise-grade tools (OpenAI API, FastAPI, Flutter), earning course credit, and building practical skills.

- **Motorsport Fans**  
  - **Stake**: Enhanced viewing experience through AI-generated commentary and telemetry visualization.  
  - **Interest**: Reliving racing moments with professional-style commentary, deeper understanding of race data and driver performance.

- **ERacing Developers**  
  - **Stake**: Potential telemetry replay solution for sim racing platforms (iRacing, Assetto Corsa, etc.).  
  - **Interest**: Adapting the system for real-time or post-race analysis in simulation environments.

- **Broadcasters & Content Creators**  
  - **Stake**: Access to automated commentary generation for highlight reels and race replays.  
  - **Interest**: Reducing production costs and time while maintaining engaging content quality for audiences.  


##  User Stories

- As a fan, I want to hear live-style AI commentary so that I can relive racing moments.  
- As a developer, I want to compare my sim telemetry to real-world patterns so I can improve simulation fidelity.  
- As a student, I want to work with OpenAI APIs so that I can learn applied AI in real-world settings. 

### User Research Survey Results

We conducted **comprehensive user research** to understand the needs and expectations for our AI-powered F1 commentary system. View the full survey results and insights here:

**[📊 View Survey Results & Insights](survey.f1aicommentary.co.uk)**

Key findings from our survey:
- **90%** of respondents want a graphical interface beyond simple audio playback
- **90%** want both driver-specific and overview commentary modes
- Users prefer configurable complexity levels for both visual and audio data
- Track selection and unbiased, data-driven commentary are high priorities
---
##  Tech Stack
<img width="2831" height="1666" alt="Tech Stack" src="https://github.com/user-attachments/assets/5064f1f7-0bb3-4977-b103-cccb1728d41d" />

**Dev Tools**
- Docker / Docker Compose  
- GitHub Actions CI/CD  
- AWS

---
##  Getting Started
### Prerequisites
- Python 3.10+
- Git
- Flutter (stable channel)
- Android Studio or Xcode
- Clone the repository:
    ```bash
    git clone https://github.com/spe-uob/2025-F1AICommentary.git
    cd 2025-F1AICommentary
    ```
### Backend Setup Instructions
1.  **Create and activate a virtual environment:**

    On macOS/Linux
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
    On Windows
    ```bash
    
    python -m venv venv
    .\venv\Scripts\activate
    ```

3.  **Install the required dependencies:**
    ```bash
    pip install -r backend/requirements.txt
    ```
    > [!IMPORTANT]
    > Make sure you have the .env file which contains the secret key for the OpenAI model.
    > OPENAI_API_KEY="Your key"
    > The location to put the .env file should be as follows:
    ```
    2025-F1AICommentary/backend
        └── fast_app
            └── .env <- HERE
      ```
4. **Running the backend:**
 - Navigate into the backend directory and run the main.py file:
    ```bash
    cd backend/
    ```
    On macOS/Linux
    ```bash
    python3 run.py
    ```
    On Windows
    ```bash
    python run.py
    ```
### Frontend Setup Instructions
Install Flutter using their [official website](https://docs.flutter.dev/get-started/install)

Make sure that the Flutter SDK bin directory (/flutter/bin) is added to your system's PATH variable so that you are able to access Flutter from the terminal. (In windows search for Environment Variables and add from here)

Run the following command to check your setup and fix any issues it outputs
```
flutter doctor
```

To get dependencies, run...
```
flutter pub get
```

Then to check for platform compatibility run...
```
flutter analyze
```

Before running the app, first make sure that you are in the correct directory (frontend)

**Run the Flutter application:**
  - The frontend now uses a single configurable backend URL via `API_BASE_URL`.
  - If no value is provided, it defaults to the dev backend.

  - Run with local backend:
    ```bash
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
    ```

  - Run with dev backend:
    ```bash
    flutter run -d chrome --dart-define=API_BASE_URL=https://dev.api.f1aicommentary.co.uk
    ```

  - Run with production backend:
    ```bash
    flutter run -d chrome --dart-define=API_BASE_URL=https://api.f1aicommentary.co.uk
    ```

  - For non-web targets you can use the same flag with `flutter run`.

  - CI/CD uses the same `API_BASE_URL` define in the frontend deploy workflow.

When testing and debugging use `flutter analyze` and `flutter doctor` to find issues and make sure you refer to the [Flutter Documentation](https://docs.flutter.dev/)

While running your Flutter instance:
- You can hot reload by pressing the `r` key in your terminal which allows you to quickly apply code changes you have made in your IDE without restarting the app.

To stop the app press Ctrl+C to stop the terminal.

---
## Continuous Integration
**How our CI works**
Our CI pipeline uses GitHub Actions to create a virtual testing environment for Python and Flutter.

CI workflows can be found in './github/workflows'. Currently, they are contained entirely in one file:
- 'ci.yml' runs integration and unit tests for both our Flutter Frontend and Python Backend

**Run CI locally**
Using [Act](https://github.com/nektos/act) you can setup a CI environment locally 
- Install act
```
sudo apt install act  # Ubuntu
brew install act      # macOS
```

Then you can run the workflow locally with this command
```
act -j <workflow-name>
```

**Linting in CI**
- **Backend**
   - We use **Pylint**.
      - To run Pylint `pylint .` to run on all files, or if you want to lint a certain file/directory, run `pylint <filename/directoryname>`

- **Frontend**
   - We use the `flutter_lints` package with custom rules for our frontend linting
      - To analyze the code run `flutter analyze` (run automatically on CI)

## Continuous Deployment
**How our CD works**
Our CD uses a containerised version of our project through Docker. GitHub actions automatically deploys whenever changes are pushed to our `main` or `dev` branches. The two files responsible are `cd-aws.yml` and `deploy-frontend.yml`

**Dockerfiles, Nginx and Uvicorn**
- The FastAPI backend uses a Dockerfile that sets up the environment with Uvicorn. When deployed, it creates a Docker container, deploys it to GitHub Container Registry and downloads it on an EC2 server. If the branch is `dev`, then Nginx routes the API traffic to port 8001 and setups the container to that port. `main` routes to 8000, allowing for seperation between testing and live deployment.
- The Flutter frontend is built and packaged within the same Docker container as the backend. On deployment, GitHub Actions triggers the build process, compiles the Flutter web assets, and copies them into the container. The container is then pushed to the GitHub Container Registry and pulled onto the EC2 server. Nginx serves the frontend assets from the container, routing web traffic to the correct static files. This ensures both backend and frontend are deployed together, with branch-based routing for dev and main environments.
---

##  Ethics

- Transparency: commentary is AI-generated, not real F1 data.  
- Licensing: only public OBD-II datasets (KIT, Kaggle) are used.  
- Bias: prompt design avoids false claims / driver favoritism.  
- Educational use: project is academic, not commercial.  

---

##  Group Members

| Name | Email |
| --- | --- |
| Ella Pham | mg23673@bristol.ac.uk |
| Callum Mackenzie | op24533@bristol.ac.uk |
| Felix van Dijk | zw23711@bristol.ac.uk |
| Kyrian Salas | kyrian.salas.2024@bristol.ac.uk |
| Leo Faircloth | zm24838@bristol.ac.uk |

---

##  Supporting Mentor

[Dixant Pant] (ra22901@bristol.ac.uk)





