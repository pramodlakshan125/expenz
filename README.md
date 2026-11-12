# Expenz

Flutter expense tracker connected to Firebase project `expenz-4f7ab` for Android
(application ID `com.expenz`).

## Firebase

- Firebase Authentication provides email/password registration, login, password
  reset, and profile names. Email/password sign-in is enabled in the project.
- Cloud Firestore stores transactions at `users/{uid}/transactions` and savings
  goals at `users/{uid}/goals`. Home, Transactions, Insights, and spending trends
  use the signed-in user's saved transactions.
- `firestore.rules` limits access to each user's own transactions and goals.
- `lib/firebase_options.dart` and `android/app/google-services.json` contain the
  Android app configuration. Other platforms are not configured.

Run on an Android device or emulator:

```sh
flutter pub get
flutter run
```

To regenerate configuration or deploy updated database rules:

```sh
firebase login
flutterfire configure --project=expenz-4f7ab --platforms=android --android-package-name=com.expenz
firebase deploy --only firestore:rules --project expenz-4f7ab
```

Google and Apple login buttons are placeholders. Their providers and platform
credentials still require separate setup. Storage, push notifications, Analytics,
and Crashlytics have not been added; the current app does not use those services.

## Validation

```sh
flutter analyze
flutter test
flutter build apk --debug
```
