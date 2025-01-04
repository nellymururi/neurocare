import numpy as np
from tensorflow.keras.models import load_model

# Load the pre-trained LSTM model
try:
    model = load_model("adhd_lstm_model.keras")
    print("Model loaded successfully.")
except Exception as e:
    print(f"Failed to load model: {e}")
    raise

def classify_adhd_severity(prediction):
    """
    Classify ADHD severity based on prediction thresholds.
    """
    if prediction < 0.5:
        return "No ADHD detected"
    elif prediction < 0.7:
        return "Mild ADHD symptoms"
    elif prediction < 0.9:
        return "Moderate ADHD symptoms"
    else:
        return "Severe ADHD symptoms"

def predict_adhd_patterns(step_data):
    """
    Preprocess step data and make ADHD predictions using the loaded model.

    :param step_data: List of step counts (recent activity data)
    :return: ADHD severity classification and prediction raw score
    """
    try:
        # Validate input data
        if not isinstance(step_data, list) or len(step_data) == 0:
            raise ValueError("step_data must be a non-empty list of step counts.")

        print("Step data received for prediction:", step_data)

        # Preprocess step data
        input_data = np.array(step_data).reshape((1, len(step_data), 1))  # Shape (1, time_steps, 1)
        print("Input data shape:", input_data.shape)

        # Make ADHD prediction
        adhd_prediction = model.predict(input_data)
        print("ADHD prediction:", adhd_prediction)

        # Classify severity
        severity = classify_adhd_severity(adhd_prediction[0][0])

        return {
            "adhd_classification": severity,
            "adhd_prediction_raw": adhd_prediction.flatten().tolist()
        }
    except Exception as e:
        print(f"Error during prediction: {e}")
        raise
