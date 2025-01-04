import google_auth_oauthlib.flow
from googleapiclient.discovery import build
import datetime
import pytz

# OAuth 2.0 flow for user authentication
def authenticate_google_fit():
    """
    Authenticate with Google Fit using OAuth 2.0.
    Returns a Google Fit API service object.
    """
    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        'client_secret.json',
        scopes=['https://www.googleapis.com/auth/fitness.activity.read']
    )
    credentials = flow.run_local_server(port=8080)
    return build('fitness', 'v1', credentials=credentials)

# Initialize Google Fit service
def get_google_fit_service():
    """
    Initialize and return the Google Fit API service object.
    """
    return authenticate_google_fit()

# Function to fetch step count data from Google Fit
def fetch_real_time_steps(service):
    """
    Fetch step count data from Google Fit for the current hour.

    :param service: Google Fit API service object
    :return: List of dictionaries containing steps and timestamps up to the current minute
    """
    data_source = "derived:com.google.step_count.delta:com.google.android.gms:merge_step_deltas"
    local_timezone = pytz.timezone("Africa/Nairobi")  # Replace with your local timezone if different
    now = datetime.datetime.now(local_timezone)
    start_of_hour = now.replace(minute=0, second=0, microsecond=0)

    start_time = int(start_of_hour.timestamp() * 1e9)  # Convert to nanoseconds
    current_time = int(now.timestamp() * 1e9)  # Current time in nanoseconds

    dataset_id = f"{start_time}-{current_time}"

    try:
        steps_data = service.users().dataSources().datasets().get(
            userId='me', dataSourceId=data_source, datasetId=dataset_id).execute()

        # Create a default dictionary for every minute in the hour up to now
        steps_with_timestamps = {
            (start_of_hour + datetime.timedelta(minutes=i)).strftime("%H:%M"): 0
            for i in range(now.minute - start_of_hour.minute + 1)
        }

        if 'point' in steps_data:
            for point in steps_data['point']:
                step_count = 0
                timestamp_start = point['startTimeNanos']
                local_time = datetime.datetime.fromtimestamp(
                    int(timestamp_start) / 1e9, tz=pytz.utc).astimezone(local_timezone)
                minute_key = local_time.strftime("%H:%M")
                if minute_key in steps_with_timestamps:
                    for value in point['value']:
                        step_count += value['intVal']
                    steps_with_timestamps[minute_key] += step_count

        return [{"time": time, "steps": steps} for time, steps in steps_with_timestamps.items()]
    except Exception as e:
        raise RuntimeError(f"Failed to fetch steps: {e}")
