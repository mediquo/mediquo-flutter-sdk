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

## Telederma (PoC)

Our side is native; each body zone is captured with the [Legit.Health iframe](https://legit.health/integration/iframe/quickstart).
Backend contract: api-chat `/imq/telederma/v1` ([mediquo/api-chat#4309](https://github.com/mediquo/api-chat/pull/4309)), IMQ patients only.

1. `MediquoTeledermaCases` lists the patient's sent cases. **Nuevo caso** asks for an optional consultation reason
   and creates a draft.
2. `LegitIframeScreen` asks the backend for an iframe session (a URL with a single-use key) and loads it as is.
3. On `analysis_completed` the report `id` is attached as the case's zone and the case is submitted. Closing the
   iframe before that discards the draft.
4. The detail shows the zone's photos and, when the patient may see it, the AI analysis.

One zone per case for now; the backend already supports several (`reports`).

Patients without access (403 on the list) see a "not available" state and no **Nuevo caso** button.

```dart
MediquoTeledermaCases(
  repository: ApiChatTeledermaClient(ApiChatClient(apiKey: apiKey, token: patientToken)),
  onCameraPermission: () => Permission.camera.request(),
)
```

`ApiChatClient` exchanges the host token for a session (`POST /login/v1/token`), like sdk-web core, and renews it on 401.
`MockTeledermaRepository` (with `withAnalysis` to fake `enableResult`) stands in for the backend and loads the bundled
simulator as the iframe.

### White label

`lib/src/design_system/` ports `@mediquo/ui`: primitive tokens (`MqColors`, `MqRadius`, `MqControlSize`, `MqFontSize`),
semantic tokens (`MqTheme`, light mode) and components (`MqButton`, `MqTextarea`, `MqBadge`, `MqCard`, `showMqConfirm`).
Components sit on Cupertino widgets for native behaviour (press feedback, text editing, iOS alerts) and are painted
with the tokens, so nothing looks Material. The brand tokens come from the organization's `primary_color`
(`GET /organizations/v1/setup`, see `MqTheme.fromBrand`); falls back to the Mediquo purple. `theme` overrides them:

```dart
MediquoTeledermaCases(
  theme: const MqTheme(brand: Color(0xFF0079C8), brandStrong: Color(0xFF005A94), brandSubtle: Color(0xFFE5F2FA), textBrand: Color(0xFF0079C8)),
)
```

### Iframe bridge

On mobile the iframe does not use `window.postMessage`: it posts a JSON string (`{message, id, payload}`) to
`webkit.messageHandlers.bridge` on iOS and to `legitHealthJsObject` on Android. `LegitIframeScreen` injects a user
script that shims both (plus `postMessage`) and forwards everything to a Flutter handler. Handled callbacks:
`analysis_completed`, `image_rejected` (snackbar) and `invalid_company_key` (error + retry with a new session).
Messages are only accepted while the WebView is on a `legit.health` page or the bundled simulator, and only the
camera permission is granted. If attaching the zone fails, retry re-sends the same report instead of restarting the
iframe.

### Simulator

`assets/telederma/legit_iframe_mock.html` imitates the iframe and posts the same callbacks over the same transports,
encoding the demo choices in the report id (`mock_lesion_pigmented_back_changed_<ts>`) so `MockTeledermaRepository`
returns a matching zone.
