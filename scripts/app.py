from flask import Flask, jsonify, request
from flask_mail import Mail, Message
from test import fetch_real_time_steps, get_google_fit_service
from model import predict_adhd_patterns
import threading
import time
import firebase_admin
from firebase_admin import credentials, firestore
from flask import session  # Ensure session is imported

# Initialize Firebase Admin SDK
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize Flask app
app = Flask(__name__)

# Configure Flask-Mail for sending emails
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'nelly.mururi@strathmore.edu'  # Replace with your email
app.config['MAIL_PASSWORD'] = 'wpqgmshcocisunhg'  # Replace with your email password
mail = Mail(app)

# Global variables
latest_steps = []
latest_prediction = None
service = None
SEQUENCE_LENGTH = 60  # Match training sequence length

def send_email_alert(recipient, message_body):
    """
    Send an email alert using Flask-Mail.
    """
    try:
        msg = Message("ADHD Alert", sender="nellymururi@gmail.com", recipients=[recipient])
        msg.body = message_body
        mail.send(msg)
        print(f"Email sent to {recipient}")
    except Exception as e:
        print(f"Error sending email: {str(e)}")

def send_alert(severity, prediction_raw, recipient_email):
    """
    Send an alert to the user via email and store it in Firestore.
    """
    print(f"ALERT: {severity} detected!")
    print(f"Prediction Score: {prediction_raw}")

    if not recipient_email:
        recipient_email = "nellymururi@gmail.com"

    # Store the alert in Firestore
    alert_data = {
        "severity": severity,
        "prediction_score": prediction_raw,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "isRead": False,
        "recipient": recipient_email,
        "message": f"ALERT: {severity} detected with a score of {prediction_raw:.2f}."
    }
    db.collection('alerts').add(alert_data)

    # Send email alert
    send_email_alert(
        recipient=recipient_email,
        message_body=alert_data["message"]
    )



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
                if severity in ["Moderate ADHD symptoms", "Severe ADHD symptoms"]:
                    print(f"Severity detected: {severity}, fetching user email...")
                    user_id = session.get('user_id')
                    if not user_id:
                        print("User ID not found in session.")
                        continue


                    user_doc = db.collection('users').document(user_id).get()
                    recipient_email = None
                    if user_doc.exists:
                        recipient_email = user_doc.to_dict().get('email')
                        print(f"Recipient email fetched: {recipient_email}")
                    else:
                        print(f"User with ID {user_id} not found in Firestore.")
                        continue


                    print(f"Sending alert to: {recipient_email}")
                    send_alert(severity, prediction["adhd_prediction_raw"][0], recipient_email)
        except Exception as e:
            print(f"Error fetching steps or making predictions: {e}")

        time.sleep(30)  # Fetch and predict every 30 seconds






@app.route('/')
def home():
    """
    Home route providing available API endpoints.
    """
    return jsonify({
        "message": "Welcome to the Neurocare API!",
        "routes": {
            "real_time_steps": "/real_time_steps",
            "adhd_predictions": "/adhd_predictions",
            "monitor_alerts": "/monitor-alerts",
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

@app.route('/monitor-alerts', methods=['GET'])
def monitor_alerts():
    
    """
    Monitor Firestore for new email alerts and send emails.
     """
    try:
        doc_snapshot = db.collection('emailAlerts').get()
        for doc in doc_snapshot:
            data = doc.to_dict()
            send_email_alert(data.get('recipient'), data.get('message'))
            # Optionally delete the processed document to avoid re-sending
            db.collection('emailAlerts').document(doc.id).delete()
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
       
@app.route('/test-email', methods=['GET'])
def test_email():
    """
    Test the email functionality by sending a test email.
    """
    try:
        send_email_alert("nellymururi@gmail.com", "This is a test email from Neurocare.")
        return jsonify({"success": True, "message": "Test email sent successfully!"}), 200
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


if __name__ == "__main__":
    # Start the background thread to fetch steps continuously
    thread = threading.Thread(target=fetch_steps_continuously, daemon=True)
    thread.start()

    # Start the Flask server
    app.run(host='0.0.0.0', port=5000)
