# MediQuo Flutter SDK

[![Latest release](https://img.shields.io/github/v/tag/mediquo/mediquo-flutter-sdk?label=release&sort=semver)](https://github.com/mediquo/mediquo-flutter-sdk/tags)

The MediQuo Flutter SDK adds MediQuo's telemedicine services to your Flutter app: chat and video calls with
healthcare professionals, and remote dermatology consultations.

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting started](#getting-started)
  - [Chat and video calls](#chat-and-video-calls)
  - [Dermatology](#dermatology)
- [Customization](#customization)
- [API reference](#api-reference)
- [Example](#example)
- [Troubleshooting](#troubleshooting)
- [Releases](#releases)
- [Support](#support)

## Features

**Chat and video calls** (`MediquoWidget`)

- Chat with MediQuo's healthcare professionals, including file and link sharing.
- Video calls inside your app.

**Dermatology** (`MediquoTelederma`)

- Patients send photos of a skin condition and a dermatologist replies within 48 business hours.
- Native screens for the consultation list, the consultation detail and the service information.
- Guided photo capture for each body zone, provided by [Legit.Health](https://legit.health).
- The dermatologist's report and prescriptions are available as PDFs once the consultation is finished.
- Terms and conditions are requested and stored by the SDK.
- Follows your organization's brand colour automatically, with full theme overrides.

## Requirements

| | Minimum version |
|---|---|
| Dart | 3.5 |
| Flutter | 3.27 |
| iOS | 13.0 |
| Android | API 21 (the Flutter default) |

You also need MediQuo credentials. See [Credentials](#credentials).

## Installation

### 1. Add the dependency

The SDK is distributed through this Git repository. Add it to your `pubspec.yaml` and pin a release tag:

```yaml
dependencies:
  mediquo_flutter_sdk:
    git:
      url: https://github.com/mediquo/mediquo-flutter-sdk.git
      ref: 0.6.0 # see https://github.com/mediquo/mediquo-flutter-sdk/tags
```

Then run:

```bash
flutter pub get
```

### 2. Configure Android

Add these permissions to `android/app/src/main/AndroidManifest.xml`, outside the `<application>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<!-- Only needed for video calls -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.VIDEO_CAPTURE" />
<uses-permission android:name="android.permission.AUDIO_CAPTURE" />
```

For file uploads in the chat, add this provider inside the `<application>` tag:

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

### 3. Configure iOS

Add the usage descriptions to `ios/Runner/Info.plist`. iOS shows these texts when it asks the patient for access:

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used for video calls and to take photos for your consultations.</string>
<!-- Only needed for video calls -->
<key>NSMicrophoneUsageDescription</key>
<string>The microphone is used for video calls.</string>
```

> [!NOTE]
> The SDK does not request permissions itself. It calls your permission callbacks, so you decide how to ask. The
> examples below use [permission_handler](https://pub.dev/packages/permission_handler).

## Getting started

### Credentials

You need two values:

| Value | Description |
|---|---|
| API key | Your organization's client API key, provided by MediQuo. |
| Patient token | Identifies the signed-in patient. Your backend gets it from the [patients authenticate endpoint](https://developer.mediquo.com/docs/api/patients/#authenticate) and passes it to the app. |

> [!IMPORTANT]
> Request the patient token from your backend. Never ship server-to-server credentials inside the app.

Import the package wherever you use it:

```dart
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';
```

### Chat and video calls

Push `MediquoWidget` as a page:

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => MediquoWidget(
    apiKey: apiKey,
    token: patientToken,
    onDownload: (url) => launchUrl(Uri.parse(url)),
    onLoadUrl: (url) => launchUrl(Uri.parse(url)),
    onMicrophonePermission: () => Permission.microphone.request(),
    onCameraPermission: () => Permission.camera.request(),
  ),
));
```

| Callback | When it is called |
|---|---|
| `onDownload(url)` | The patient downloads a file from the chat. |
| `onLoadUrl(url)` | The patient opens a link sent to the chat. |
| `onMicrophonePermission()` | A video call needs the microphone. |
| `onCameraPermission()` | A video call needs the camera. |

### Dermatology

> [!NOTE]
> Dermatology is enabled per organization. Patients without access see a "service not available" screen. Contact
> MediQuo to enable it.

Push `MediquoTelederma` as a page. It takes the same credentials as `MediquoWidget`:

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => MediquoTelederma(
    apiKey: apiKey,
    token: patientToken,
    onLoadUrl: (url) => launchUrl(Uri.parse(url)),
    onOpenDocument: (path) => OpenFilex.open(path, type: 'application/pdf'),
    onCameraPermission: () => Permission.camera.request(),
  ),
));
```

The patient's journey:

1. **Consultations.** The list shows pending consultations first, then finished ones. It refreshes when the app
   returns to the foreground.
2. **New consultation.** The first time, and whenever the terms change, the patient accepts the terms and
   conditions. Then the guided photo capture opens. Closing it before sending asks for confirmation and discards
   the draft.
3. **Sent.** A confirmation screen explains the next steps. The patient is notified by email when the
   dermatologist replies.
4. **Detail.** Shows the body zone, the patient's answers and the photos. Once a dermatologist takes the
   consultation, it shows who it is. Once finished, it also lists the dermatologist's documents (report,
   prescription, diagnostic tests).

#### Opening documents

Documents are protected by the patient session, so the SDK downloads them and passes `onOpenDocument` the path of a
local PDF. Open it with a viewer, share it or save it.

The SDK deletes the file when the patient leaves the consultation detail or opens another document. Copy it first if
you need to keep it.

The example uses [open_filex](https://pub.dev/packages/open_filex), which opens the system PDF viewer on Android and
iOS.

#### Opening a specific screen

Use `initialRoute` to open a consultation or start a new one directly, for example from a push notification or an
email link. The consultation list stays underneath, so going back lands on it.

```dart
MediquoTelederma(
  // ...
  initialRoute: TeledermaRoute.caseDetail(consultationId),
)
```

## Customization

### Chat and video calls

Pass a `MediquoWidgetTheme`:

```dart
MediquoWidget(
  // ...
  theme: const MediquoWidgetTheme(containerColor: Colors.white),
)
```

### Dermatology

By default the screens use your organization's brand colour, as configured in MediQuo. To override it, pass an
`MqTheme`. `MqTheme.fromBrand` derives the full palette from one colour:

```dart
MediquoTelederma(
  // ...
  theme: MqTheme.fromBrand(const Color(0xFF0079C8)),
)
```

Use the `MqTheme` constructor to set individual colours (`brand`, `textPrimary`, `background`, `error`…) and
`fontFamily`.

## API reference

### `MediquoWidget`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `apiKey` | `String` | Yes | Your client API key. |
| `token` | `String` | Yes | The patient token. |
| `onDownload` | `Function(String url)` | Yes | Called when the patient downloads a file. |
| `onLoadUrl` | `Function(String url)` | Yes | Called when the patient opens a link. |
| `onMicrophonePermission` | `Future Function()` | Yes | Request the microphone permission. |
| `onCameraPermission` | `Future Function()` | Yes | Request the camera permission. |
| `theme` | `MediquoWidgetTheme` | No | Visual customization. |
| `environment` | `MediquoWidgetEnvironment` | No | `production` (default) or `sandbox`. |

### `MediquoTelederma`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `apiKey` | `String` | Yes | Your client API key. |
| `token` | `String` | Yes | The patient token. |
| `onLoadUrl` | `void Function(String url)` | Yes | Opens the terms and conditions and the privacy policy. |
| `onOpenDocument` | `Future<void> Function(String filePath)` | Yes | Receives the path of a downloaded PDF. See [Opening documents](#opening-documents). |
| `onCameraPermission` | `Future<void> Function()` | No | Request the camera permission. On Android it is called before the photo capture opens. |
| `initialRoute` | `TeledermaRoute` | No | Screen to open first. Defaults to `TeledermaRoute.cases()`. |
| `theme` | `MqTheme` | No | Overrides the organization's brand colours. |

### `TeledermaRoute`

| Value | Opens |
|---|---|
| `TeledermaRoute.cases()` | The consultation list (default). |
| `TeledermaRoute.caseDetail(id)` | The detail of a consultation. |
| `TeledermaRoute.newConsultation()` | A new consultation. |

## Example

A complete app that opens both features from its home screen:

```dart
import 'package:flutter/material.dart';
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

const apiKey = 'YOUR_API_KEY';
const patientToken = 'PATIENT_TOKEN_FROM_YOUR_BACKEND';

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My app')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _open(
                context,
                MediquoWidget(
                  apiKey: apiKey,
                  token: patientToken,
                  onDownload: (url) => launchUrl(Uri.parse(url)),
                  onLoadUrl: (url) => launchUrl(Uri.parse(url)),
                  onMicrophonePermission: () => Permission.microphone.request(),
                  onCameraPermission: () => Permission.camera.request(),
                ),
              ),
              child: const Text('Chat with a doctor'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(
                context,
                MediquoTelederma(
                  apiKey: apiKey,
                  token: patientToken,
                  onLoadUrl: (url) => launchUrl(Uri.parse(url)),
                  onOpenDocument: (path) => OpenFilex.open(path, type: 'application/pdf'),
                  onCameraPermission: () => Permission.camera.request(),
                ),
              ),
              child: const Text('Dermatology'),
            ),
          ],
        ),
      ),
    );
  }
}
```

This example depends on [permission_handler](https://pub.dev/packages/permission_handler),
[url_launcher](https://pub.dev/packages/url_launcher) and [open_filex](https://pub.dev/packages/open_filex). Replace
them with your own implementations if you prefer.

## Troubleshooting

### The camera is not offered in the dermatology photo capture on Android

Android's file chooser only offers the camera once the permission is granted. Implement `onCameraPermission` and
declare `android.permission.CAMERA` in the manifest.

### PDFs do not open on Android

`open_filex` hands the PDF to an installed viewer app. If the device has none, nothing opens: check the
`OpenResult` it returns and show a message. If you implemented `onOpenDocument` yourself, read the file before the
patient leaves the consultation detail, because the SDK deletes it then.

### The patient sees "service not available" in Dermatology

Dermatology is not enabled for the patient's organization. Contact MediQuo.

### Video calls have no audio or video

Check that the microphone and camera callbacks request the permission and that the manifest and `Info.plist`
entries from [Installation](#installation) are present. See also the
[InAppWebView WebRTC guide](https://inappwebview.dev/docs/web-rtc).

## Releases

Releases follow [semantic versioning](https://semver.org) and are published as tags in this repository, without a
`v` prefix (`0.6.0`). Each release has its notes in [CHANGELOG.md](CHANGELOG.md) and on the
[GitHub releases page](https://github.com/mediquo/mediquo-flutter-sdk/releases).

Pin an exact tag in `pubspec.yaml` and read the changelog before upgrading.

## Support

For integration help or to report an issue, contact your MediQuo account manager. Include the SDK version, the
platform and OS version, and the steps to reproduce.
