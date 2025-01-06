from flask import Flask, jsonify
from test import fetch_real_time_steps, get_google_fit_service
from model import predict_adhd_patterns
import threading
import time

app = Flask(__name__)

latest_steps = []
latest_prediction = None
service = None

# Sequence length used in training
SEQUENCE_LENGTH = 60  # Match training sequence length

def send_alert(severity, prediction_raw):
    """
    Simulate sending an alert (e.g., log or email notification).
    """
    print(f"ALERT: {severity} detected!")
    print(f"Prediction Score: {prediction_raw}")

def fetch_steps_continuously():
    """
    Fetch real-time steps continuously and make ADHD predictions.
    """
    global latest_steps, latest_prediction, service
    while True:
        try:
            if service is None:
                service = get_google_fit_service()

            # Fetch real-time steps from Google Fit
            steps = fetch_real_time_steps(service)
            latest_steps = steps
            print(f"Fetched steps: {latest_steps}")

            if latest_steps:
                # Extract step counts and ensure the sequence matches `SEQUENCE_LENGTH`
                step_data = [entry["steps"] for entry in latest_steps]
                if len(step_data) >= SEQUENCE_LENGTH:
                    step_data = step_data[-SEQUENCE_LENGTH:]  # Use only the last `SEQUENCE_LENGTH` steps

                # Make ADHD prediction
                prediction = predict_adhd_patterns(step_data)
                severity = prediction["adhd_classification"]

                latest_prediction = {
                    "adhd_classification": "ADHD detected" if severity != "No ADHD detected" else "ADHD not detected",
                    "adhd_level": severity,
                    "adhd_prediction_score": prediction["adhd_prediction_raw"][0],
                }
                print(f"Real-time Prediction: {latest_prediction}")

                # Trigger alert for Moderate or Severe ADHD symptoms
                if severity in ["Moderate ADHD symptoms", "Severe ADHD symptoms"]:
                    send_alert(severity, prediction["adhd_prediction_raw"][0])
        except Exception as e:
            print(f"Error fetching steps or making predictions: {e}")
        time.sleep(30)  # Fetch and predict every minute

@app.route('/')
def home():
    """
    Home route providing available API endpoints.
    """
    return jsonify({
        "message": "Welcome to the Neurocare API!",
        "routes": {
            "real_time_steps": "/real_time_steps",
            "adhd_predictions": "/adhd_predictions"
        }
    })

@app.route('/real_time_steps', methods=['GET'])
def get_real_time_steps():
    """
    API endpoint to return the latest fetched steps.
    """
    if latest_steps:
        return jsonify({
            "success": True,
            "steps": latest_steps
        })
    else:
        return jsonify({
            "success": False,
            "error": "No steps data available. Please wait for real-time updates."
        })

@app.route('/adhd_predictions', methods=['GET'])
def adhd_predictions():
    """
    API endpoint to return the latest ADHD predictions.
    """
    if latest_prediction:
        return jsonify({
            "success": True,
            "prediction": latest_prediction
        })
    else:
        return jsonify({
            "success": False,
            "error": "No ADHD predictions available yet. Please wait for real-time updates."
        })

if __name__ == "__main__":
    # Start the background thread to fetch steps continuously
    thread = threading.Thread(target=fetch_steps_continuously, daemon=True)
    thread.start()

    # Start the Flask server
    app.run(host='0.0.0.0', port=5000)
