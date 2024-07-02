# MediQuo Flutter SDK

The MediQuo Flutter SDK allows to integrate the MediQuo web widget in your Flutter application. The main features are:
- Chat
- Video call

The package uses the next plugins: 
- [InAppWebView v6](https://inappwebview.dev/) plugin in order to load and interact with a MediQuo web widget.
- [Connectivity plus v6](https://pub.dev/packages/connectivity_plus) plugin in order check internet connectivity.

## Installation

The MediQuo Flutter SDK can be added in your project following the next steps:

- Add the Github package `https://github.com/mediquo/mediquo-flutter-sdk.git` the `pubspec.yaml` file in your Flutter project. Consult the [reference](https://github.com/mediquo/mediquo-flutter-sdk/tags) to specify the version by tag .

```yaml
  mediquo_flutter_sdk:
    git:
      url: https://github.com/mediquo/mediquo-flutter-sdk.git
      ref: x.y.z
```

Then, download the package by running the `flutter pub get` command.

## Integration

Before you initialize the SDK, make sure you have at hand these two values:
- `API_KEY`: Your personal api key provided by MediQuo.
- `TOKEN`: Patient token obtained from the [patients authenticate method](https://developer.mediquo.com/docs/api/patients/#authenticate)

In order to integrate the SDK, import the package in your dart class.

```dart
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';
```

Whenever you want to present the MediQuo functionality, add the lines below:

```dart
MediquoWidget(
    apiKey: API_KEY,
    token: TOKEN,
    onDownload: onDownloadCallback,
    onLoadUrl: onLoadUrlCallback,
    onMicrophonePermission: onMicrophonePermissionCallback,
    onCameraPermission: onCameraPermissionCallback
    theme: const MediquoWidgetTheme() // optional
);
``` 

### Callbacks

In order to have a full functionality of the widget, the init method requires the definition of some callback functions. These functions should define the behaviour of your application in the next cases:
- onDownload(string downloadUrl): It will be invoked when the user tries to download a file in the SDK. 
- onLoadUrl(string url): It will be invoked when the user tries to open a url sent to the chat in the SDK. 
- onMicrophonePermission(): It will be invoked when the user is accessing to a video call and requires the device microphone permission.
- onCameraPermission(): It will be invoked when the user is accessing to a video call and requires the device camera permission.

### Customization

You can optionally pass the `MediquoWidgetTheme` customization object as `theme` to the MediQuoWidget instance. The next properties can be defined:

| Nombre         | Tipo  | Valor por defecto |
|----------------|-------|-------------------|
| containerColor | Color | Colors.white      |

## Example

The next class opens a new page when the floating button is pressed.

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true
  );

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  static onDownloadCallback(String downloadUrl) async {
    final tempDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();

    await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: tempDir!.path,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true
    );

    return;
  }

  static onLoadUrlCallback(String url) async {
    launchUrl(Uri.parse(url));
    return;
  }

  static onMicrophonePermissionCallback() async {
    await Permission.microphone.request();
  }

  static onCameraPermissionCallback() async {
    await Permission.camera.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("My app"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return const MediquoWidget(
                    apiKey: '',
                    token: '',
                    onDownload: onDownloadCallback,
                    onLoadUrl: onLoadUrlCallback,
                    onMicrophonePermission: onMicrophonePermissionCallback,
                    onCameraPermission: onCameraPermissionCallback,
                    theme: const MediquoWidgetTheme(
                      containerColor: Colors.white
                    ),
                );
              },
              )
            );
          },
          child: const Icon(Icons.local_hospital)
        ),
    );
  }
}
```

Notice the next points in the code:
- Api key and token are empty values. 
- Camera and microphone permission callbacks are implemented using the [Flutter permission_handler plugin](https://pub.dev/packages/permission_handler).
- Download callback is implemented using the [Flutter downloader plugin](https://pub.dev/packages/flutter_downloader)
- Load URL callback is implemented using the [Flutter URL launcher plugin](https://pub.dev/packages/url_launcher)

In order to grant permissions, the `AndroidManifest.xml` was modified by adding these lines:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.VIDEO_CAPTURE" />
<uses-permission android:name="android.permission.AUDIO_CAPTURE" />
```

In the `<application>` tag insert this provider configuration:
```xml
<provider
    android:name="com.pichillilorenzo.flutter_inappwebview_android.InAppWebViewFileProvider"
    android:authorities="${applicationId}.flutter_inappwebview_android.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/provider_paths" />
</provider>
```

Also the `Info.plist` file:
```
<key>NSMicrophoneUsageDescription</key>
<string>Flutter requires access to microphone.</string>

<key>NSCameraUsageDescription</key>
<string>Flutter requires access to camera.</string>
```

You can find more information in the [InAppWebView WebRTC documentation](https://inappwebview.dev/docs/web-rtc) 
