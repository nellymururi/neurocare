import google_auth_oauthlib.flow
from googleapiclient.discovery import build
import datetime

# OAuth 2.0 flow for user authentication
def authenticate_google_fit():
    # Use the client_secret.json downloaded from Google Cloud
    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        'client_secret.json', 
        scopes=['https://www.googleapis.com/auth/fitness.activity.read']
    )
    credentials = flow.run_local_server(port=8080)
    return build('fitness', 'v1', credentials=credentials)

# Function to fetch step count data from Google Fit
def fetch_real_time_steps(service):
    # Define the data source and the dataset time range
    data_source = "derived:com.google.step_count.delta:com.google.android.gms:merge_step_deltas"
    
    # Get current time
    now = datetime.datetime.utcnow()
    start_time = int((now - datetime.timedelta(minutes=1)).timestamp() * 1000000000)  # 1 minute ago
    end_time = int(now.timestamp() * 1000000000)  # current time

    dataset_id = f"{start_time}-{end_time}"
    
    steps_data = service.users().dataSources().datasets().get(
        userId='me', dataSourceId=data_source, datasetId=dataset_id).execute()

    # Process the fetched data
    if 'point' in steps_data:
        for point in steps_data['point']:
            for value in point['value']:
                print(f"Steps: {value['intVal']}")

# Main function to get real-time data
def main():
    service = authenticate_google_fit()
    fetch_real_time_steps(service)

if __name__ == "__main__":
    main()
