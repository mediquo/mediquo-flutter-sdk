# MediQuo Flutter SDK

The MediQuo Flutter SDK allows to integrate the MediQuo web widget in your Flutter application. The main features are:
- Chat
- Video call

The package uses the [InAppWebView v6](https://inappwebview.dev/) plugin in order to load and interact with a MediQuo web widget. 

## Installation

The MediQuo Flutter SDK can be added in your project following the next steps:

- Add the Github package `https://github.com/mediquo/mediquo-flutter-sdk.git` the `pubspec.yaml` file in your Flutter project. Specify the version by the tag in the reference.

```yaml
  mediquo_flutter_sdk:
    git:
      url: https://github.com/mediquo/mediquo-flutter-sdk.git
      ref: x.y.z
```

Then, download the package by running the `flutter pub get` command.

## Integration

In order to integrate the SDK, import the package in your dart class.

```dart
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';
```

Before you initialize the SDK, make sure you have at hand these two values:
- `API_KEY`: Your personal api key provided by MediQuo.
- `TOKEN`: Patient token obtained from the [patients authenticate method](https://developer.mediquo.com/docs/api/patients/#authenticate)

Whenever you want to present the MediQuo functionality, add the lines below:

```dart
MediquoWidget(
    apiKey: API_KEY,
    token: TOKEN,
    onDownload: onDownloadListener,
    onMicrophonePermission: onMicrophonePermission,
    onCameraPermission: onCameraPermission
);
``` 

### Listeners

In order to have a full functionality of the widget, the init method requires the definition of some listener functions. These functions should define the behaviour of your application in the next cases:
- onDownload(string downloadUrl): It will be instantiated when the user tries to download a file in the SDK. 
- onMicrophonePermission(): It will be instantiated when the user is accessing to a video call and requires the microphone device permission.
- onCameraPermission(): It will be instantiated when the user is accessing to a video call and requires the camera device permission.

## Example

The next class opens a new page when the floating button is 