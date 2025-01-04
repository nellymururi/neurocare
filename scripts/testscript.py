from model import predict_adhd_patterns  # Replace 'your_model_file' with the actual file name where the function is defined

# Mock step data for testing
step_data = [10, 12, 13, 15, 17, 20]  # Replace with realistic test data

# Test the prediction function
try:
    prediction = predict_adhd_patterns(step_data)
    print("Test successful. Prediction results:")
    print("ADHD Classification:", prediction["adhd_classification"])
    print("Future Activity Levels:", prediction["future_activity_levels"])
except Exception as e:
    print(f"Test script failed: {e}")
