# R26-IT-087
# AI-POMEGRANATE-FARMING-SYSTEM
### AI-Based Intelligent Farming System for Improving Pomegranate Yield and Quality

AI-POMEGRANATE-FARMING-SYSTEM is an intelligent smart agriculture platform designed to support pomegranate farmers using Artificial Intelligence (AI), Machine Learning (ML), Deep Learning (DL), Computer Vision, and IoT technologies.  

The system helps farmers improve pomegranate yield, fruit quality, irrigation management, disease control, fertilizer management, harvest prediction, and post-harvest utilization through intelligent AI-powered analysis and recommendations.
<img width="1920" height="1080" alt="Dashboard" src="https://github.com/user-attachments/assets/d75e6997-4b4d-4fef-902b-95471b971ea7" />

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
-Flutter


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
-tflite
-Random Forest

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
https://github.com/HariniVJ/R26-IT-087.git
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
OPENWEATHER_API_KEY
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
- Diease Detection Screen
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






