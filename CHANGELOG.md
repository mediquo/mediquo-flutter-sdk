# Changelog

## 0.8.1

### Patch Changes

- Telederma no longer shows its own "Foto rechazada" notice with the raw analysis data when Legit Health rejects a photo: the "Revisa tu foto" dialog from Legit Health is the only message the patient sees.

## 0.8.0

### Minor Changes

- Telederma shows the dermatologist assigned to each consultation: name on the list cards, and name, speciality, collegiate number and photo on the detail. Assigned consultations stay with the pending ones.

### Patch Changes

- Telederma screens no longer draw their last lines under the Android navigation bar: the service information footer, the case detail and the consultations list now end above it.

## 0.7.0

### Minor Changes

- **Breaking:** `MediquoTeledermaCases` is now `MediquoTelederma` and takes `apiKey` and `token` like `MediquoWidget`. `ApiChatClient` and `ApiChatTeledermaClient` are no longer exported.
  
  ```dart
  // Before
  MediquoTeledermaCases(repository: ApiChatTeledermaClient(ApiChatClient(apiKey: apiKey, token: token)), ...)
  // After
  MediquoTelederma(apiKey: apiKey, token: token, ...)
  ```

## 0.6.0

### Minor Changes

- Adds the telederma flow for IMQ patients with `MediquoTeledermaCases`: consultations list and detail, new consultations through the Legit.Health photo capture, the dermatologist's documents once a case is finished, and `initialRoute` to open a case or a new consultation directly.

