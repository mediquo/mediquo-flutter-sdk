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

## Telederma

Our side is native; each body zone is captured with the [Legit.Health iframe](https://legit.health/integration/iframe/quickstart).
Backend contract: api-chat `/imq/telederma/v1` ([mediquo/api-chat#4309](https://github.com/mediquo/api-chat/pull/4309)), IMQ patients only.

1. `MediquoTeledermaCases` lists the patient's consultations (Pendiente / Finalizada). The info button opens the
   service information.
2. **Nueva consulta** asks for the terms the first time (or after they change), like sdk-web: the status comes from
   the login `legal_consent`, the URLs from the organization setup, and accepting calls `POST /profile/v1/legal-consent`.
3. **Nueva consulta** asks the backend for a Legit.Health iframe session and loads it. Closing it asks for confirmation and
   discards the draft.
4. On `analysis_completed` the report is attached, the case is submitted and the "consulta enviada" screen is shown.
5. The detail shows the summary (zone, answers, photos) and, once `finished`, when it was closed and the documents
   the dermatologist generated (`documents`: report, prescription, diagnostic test prescription). A finished case may
   have no documents, and a document may have no `download_url` yet; both states are shown.

Patients without access (403 on the list) see a "not available" state and no **Nueva consulta** button.

```dart
MediquoTeledermaCases(
  repository: ApiChatTeledermaClient(ApiChatClient(apiKey: apiKey, token: patientToken)),
  onLoadUrl: (url) => launchUrl(Uri.parse(url)),
  onOpenDocument: (path) => OpenFilex.open(path, type: 'application/pdf'), // open_filex
  onCameraPermission: () => Permission.camera.request(),
  initialRoute: const TeledermaRoute.caseDetail(caseId), // optional
)
```

- `onLoadUrl` opens the terms and the privacy policy, like `MediquoWidget`.
- `onOpenDocument` receives the local path of a downloaded PDF. Document URLs need the patient session, so the SDK
  downloads them itself (`GET download_url` with the session JWT, only to the api-chat host) into the temp directory
  and hands the file over to be shown, shared or saved. The file is deleted when the patient leaves the case detail
  or opens another document, so copy it if you need to keep it. A 404 means the PDF is not ready yet.
- `onCameraPermission` is asked before the iframe on Android, whose file chooser only offers the camera once granted.
- `initialRoute` opens the flow on a given screen, like a deep link: `TeledermaRoute.cases()` (default),
  `TeledermaRoute.caseDetail(caseId)` or `TeledermaRoute.newConsultation()`. The list stays underneath, so going back
  lands on it.

`ApiChatClient` exchanges the host token for a session (`POST /login/v1/token`), like sdk-web core, and renews it on 401.


### White label

The screens follow the MediCore design system (`@mediquo/ui`) on Cupertino widgets, so nothing looks Material.
The brand colours come from the organization's `primary_color`
(`GET /organizations/v1/setup`, see `MqTheme.fromBrand`); falls back to the Mediquo purple. `theme` overrides them:

```dart
MediquoTeledermaCases(
  theme: const MqTheme(brand: Color(0xFF0079C8), brandSubtle: Color(0xFFE5F2FA), textBrand: Color(0xFF0079C8)),
)
```

### Iframe bridge

On mobile the iframe does not use `window.postMessage`: it posts a JSON string (`{message, id, payload}`) to
`webkit.messageHandlers.bridge` on iOS and to `legitHealthJsObject` on Android. The SDK injects a user
script that shims both (plus `postMessage`) and forwards everything to a Flutter handler. Handled callbacks:
`analysis_completed`, `image_rejected` (snackbar) and `invalid_company_key` (error + retry with a new session).
Messages are only accepted while the WebView is on an https `legit.health` page, and only the
camera permission is granted. If attaching the zone fails, retry re-sends the same report instead of restarting the
iframe.
