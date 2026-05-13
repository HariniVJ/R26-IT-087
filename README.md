<div align="center">
<!-- Animated Banner SVG -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=B22222&height=200&section=header&text=🌱%20AI-POMEGRANATE%20FARMING%20SYSTEM&fontSize=32&fontColor=fff&animation=twinkling&fontAlignY=38&desc=Intelligent%20Smart%20Agriculture%20Platform&descAlignY=58&descSize=16" width="100%"/>




<br/>

<!-- Badges Row 1 -->
<img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Flutter-Mobile%20App-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-Database-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>

<br/>

<!-- Badges Row 2 -->
<img src="https://img.shields.io/badge/TensorFlow-AI%20Engine-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white"/>
<img src="https://img.shields.io/badge/OpenCV-Computer%20Vision-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white"/>
<img src="https://img.shields.io/badge/YOLO-Object%20Detection-00FFFF?style=for-the-badge&logo=yolo&logoColor=black"/>
<img src="https://img.shields.io/badge/ESP32-IoT%20Hardware-E7352C?style=for-the-badge&logo=espressif&logoColor=white"/>

<br/>

<!-- Metrics Badges -->
<img src="https://img.shields.io/badge/Dataset-10%2C000%20Records-8E44AD?style=for-the-badge&logo=databricks&logoColor=white"/>
<img src="https://img.shields.io/badge/Pomegranate-3%2C996%20Samples-C0392B?style=for-the-badge"/>
<img src="https://img.shields.io/badge/License-Academic%20Research-27AE60?style=for-the-badge"/>

<br/><br/>

<!-- Animated Divider -->
<img src="https://user-images.githubusercontent.com/74038190/212284100-6a7f2f8d-2c9d-4e66-9c2d-7f8d3f8c5b4d.gif" width="700"/>

</div>

# R26-IT-087
# AI-POMEGRANATE-FARMING-SYSTEM
### AI-Based Intelligent Farming System for Improving Pomegranate Yield and Quality

AI-POMEGRANATE-FARMING-SYSTEM is an intelligent smart agriculture platform designed to support pomegranate farmers using Artificial Intelligence (AI), Machine Learning (ML), Deep Learning (DL), Computer Vision, and IoT technologies.  

The system helps farmers improve pomegranate yield, fruit quality, irrigation management, disease control, fertilizer management, harvest prediction, and post-harvest utilization through intelligent AI-powered analysis and recommendations.

<img width="1920" height="1080" alt="Dashboard" src="https://github.com/user-attachments/assets/d75e6997-4b4d-4fef-902b-95471b971ea7" />

---

# Features

## 1. Fruit Disease Detection & Treatment Recommendation
- Detects pomegranate fruit diseases using image analysis
- Identifies diseases such as:
  - Bacterial Blight
  - Anthracnose
  - Cercospora
  - Alternaria
- Provides treatment and prevention recommendations
- Supports early disease identification
- AI-powered disease classification using CNN, SVM, and KNN

---

## 2. Fruit Quality Grading & Waste Utilization Analysis
- Classifies fruits into:
  - High Quality
  - Medium Quality
  - Low Quality
- Provides intelligent utilization recommendations
- Suggests:
  - Export selection
  - Juice processing
  - Cosmetic production
  - Organic fertilizer production
- Reduces post-harvest waste
- Uses image processing and deep learning models

---

## 3. Intelligent Fertilizer Recommendation & Irrigation Decision System
- Monitors:
  - Soil Moisture
  - Soil Temperature
  - Air Temperature
  - Humidity
  - Soil pH
  - Nitrogen (N)
  - Phosphorus (P)
  - Potassium (K)
- Provides fertilizer recommendations based on soil conditions
- Integrates weather forecast API data
- Generates smart irrigation recommendations
- Uses IoT sensors with ESP32 microcontroller
- Helps reduce water and fertilizer wastage

---

## 4. Fruit Growth Stage Detection and Harvest Time Prediction
- Detects pomegranate growth stages from images
- Identifies stages such as:
  - Bud
  - Flower
  - Early Fruit
  - Mid Growth
  - Mature Fruit
- Predicts remaining harvest time
- Provides stage-based care tips and warnings
- Uses YOLO and CNN-based image analysis
- Supports better harvest planning and crop management

<img width="1920" height="1080" alt="Purple Pink Gradient Mobile Application Presentation jpg" src="https://github.com/user-attachments/assets/eefcd0dd-91f0-452c-9c68-20ab7bb0924d" />

---

# Tech Stack

## Frontend
- Flutter

## Backend
- Python 3.10+
- FastAPI
- Flask
- Uvicorn

## Database
- Firebase

## Artificial Intelligence & Machine Learning
- TensorFlow
- Keras
- OpenCV
- CNN (Convolutional Neural Network)
- YOLO
- SVM
- KNN
- ANN
- tflite
- Random Forest

## IoT & Hardware
- ESP32 Microcontroller
- 7-in-1 Soil Sensor
- Temperature & Humidity Sensors

## External APIs & Tools
- OpenWeather API
- Git
- GitHub
- VS Code

---

# Installation Guide

## 1. Clone the Repository

```bash
git clone https://github.com/HariniVJ/R26-IT-087.git
cd R26-IT-087
```

---

## 2. Install Frontend Dependencies

```bash
cd frontend
flutter pub get
```

---

## 3. Install Backend Dependencies

```bash
cd backend
pip install -r requirements.txt
```

---

## 4. Configure Environment Variables

Create a `.env` file inside the backend folder and add:

```env
API_BASE_URL=http://127.0.0.1:8000
OPENWEATHER_API_KEY=your_api_key_here
```

---

## 5. Run the Backend Server

```bash
python -m uvicorn app.main:app --reload --port 8000
```

---

## 6. Run the Frontend

```bash
flutter run -d chrome
```

---

## 7. Open the Application

```bash
http://localhost:8000/docs
```

---

# Project Structure

```bash
R26-IT-087/
│
├── backend/
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── main.py
│   │
│   ├── .env
│   └── requirements.txt
│
├── frontend/
│   └── mobile_app/
│       ├── .dart_tool/
│       ├── android/
│       ├── assets/
│       ├── build/
│       ├── ios/
│       ├── lib/
│       ├── linux/
│       ├── macos/
│       ├── test/
│       ├── web/
│       ├── windows/
│       │
│       ├── .flutter-plugins-dependencies
│       ├── .gitignore
│       ├── .metadata
│       ├── analysis_options.yaml
│       ├── pubspec.lock
│       ├── pubspec.yaml
│       └── README.md
│
├── .gitignore
└── README.md
```

---

# Screenshots

Include screenshots for:
- Dashboard Interface
- Detecting Screen
- Disease Detection Screen
- Capture Image Screen
- Quality Grading Screen
- Fertilizer Screen

---

# Author

- Thishoharini V
- Sowmiya A
- Banuja S
- Kobiram T

---

# License

This project was developed for academic and research purposes.

---

<div align="center">

<!-- Footer Wave -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=100&section=footer" width="100%"/>


⭐ **Star this repo** if you find it useful!  


</div>
