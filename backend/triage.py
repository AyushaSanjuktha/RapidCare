import joblib
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

model_path = os.path.join(
    BASE_DIR,
    "rapidcare_triage_model.pkl"
)

vectorizer_path = os.path.join(
    BASE_DIR,
    "rapidcare_tfidf_vectorizer.pkl"
)

model = joblib.load(model_path)
vectorizer = joblib.load(vectorizer_path)


def predict_severity(symptoms: str):

    features = vectorizer.transform([symptoms])

    prediction = model.predict(features)[0]

    probabilities = model.predict_proba(features)[0]

    confidence = max(probabilities)

    return {
        "severity_class": int(prediction),
        "confidence": round(float(confidence), 4)
    }