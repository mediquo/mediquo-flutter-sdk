# Changelog

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

