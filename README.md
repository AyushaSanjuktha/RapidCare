# RapidCare

## AI-Powered Emergency Healthcare Platform

RapidCare is an emergency healthcare platform designed to reduce response time during medical emergencies.

The system allows a user to trigger an SOS, capture their location and symptoms, classify emergency severity using AI, automatically assign a nearby available responder, calculate responder ETA, and provide emergency information to the hospital.

---

## Main Features

- Instant SOS emergency dispatch
- GPS-based patient location
- AI-based emergency severity classification
- Automatic responder assignment
- Responder distance and ETA calculation
- Emergency case management
- Hospital selection
- Hospital pre-brief
- Emergency status tracking
- Offline/SMS fallback support
- Emergency analytics

---

## System Flow

SOS
↓
Get Patient Location
↓
AI Severity Classification
↓
Find Available Responders
↓
Calculate Distance and ETA
↓
Automatically Assign Fastest Responder
↓
Responder En Route
↓
Hospital Pre-Brief
↓
Emergency Completed

---

# Project Structure

```text
Rapidcare27/
│
├── backend/
│   ├── main.py
│   ├── triage.py
│   ├── rapidcare_triage_model.pkl
│   ├── rapidcare_triage_vectorizer.pkl
│   ├── requirements.txt
│   └── .env.example
│
├── flutter_app/
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
│
├── .gitignore
└── README.md