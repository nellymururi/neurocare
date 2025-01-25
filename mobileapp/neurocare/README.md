# Neurocare ADHD Project

Neurocare is a mobile application designed to provide real-time monitoring for adult ADHD patients. By integrating with wearable devices through Google Fit, it extracts health-related data such as step counts and utilizes an LSTM machine learning model to detect ADHD patterns and predict future episodes. The platform offers customizable alerts, insightful visualizations, and actionable data for caregivers to enhance patient care and management.

## Installation
- Fork the project to create a copy in your own GitHub account using the GitHub CLI:
  
  ```sh
    gh repo fork OWNER/REPO
  ```

- Download the project as a zip file from your forked repository and extract its contents.
- Enable developer settings on your Android device to allow installation of applications from unknown sources, ensuring USB debugging is enabled.
- Open the project in your preferred IDE such as Visual Studio Code.
- Install dependencies by running the command to fetch necessary packages:

  ```sh
    flutter pub get
  ```

- Run the application by executing the following command to build and deploy it on your connected Android device:

  ```sh
   flutter run
  ```

## Database

The project utilizes Firebase and PostgreSQL for data storage. To set up the databases, follow these steps:
  - Create a [Firebase project](https://console.firebase.google.com).
  - Enable Firebase Authentication and configure desired sign-in methods.
  - Set up the Firestore database and define Firestore rules according to your security needs.
  

## Contributions

To contribute to the project:
   - Fork the repository.
   - Create a feature branch on your forked repository.
   - Submit a [pull request](https://github.com/nellymururi/neurocare/pulls).

## Issues
If you encounter any issues with the project, please feel free to open an [issue](https://github.com/nellymururi/neurocare/issues).



## Features
- **Real-time Monitoring**: Tracks ADHD-related metrics via wearable devices.
- **AI-driven Predictions**: LSTM model detects and predicts ADHD episodes.
- **Customizable Alerts**: Notifications based on user-defined thresholds.
- **Interactive Visualization**: Historical data and trend analysis through charts.
- **Cross-platform Support**: Mobile compatibility for both Android and iOS.

## Contact
For inquiries or contributions, reach out via:
- Email: nellymururi@gmail.com
- GitHub: [nellymururi](https://github.com/nellymururi)

  ## License
This project is licensed under the [MIT License](LICENSE).

