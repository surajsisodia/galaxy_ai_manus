# galaxy_ai_assignment

A new Flutter project.

## Android Release APK (Size-Optimized)

Use this command for direct APK distribution:

```bash
./scripts/build_android_release.sh
```

This builds:

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```

Why:
- Avoids full universal APK packaging that includes extra ABI payload.
- Keeps one APK that supports both 32-bit and 64-bit real Android devices.

### Release checklist

1. Build with `./scripts/build_android_release.sh`.
2. Confirm generated file: `build/app/outputs/flutter-apk/app-release.apk`.
3. Verify APK size is in expected range (~34-36 MB, adjust as app grows).
4. Install and smoke test on:
   - one `arm64-v8a` device/emulator
   - one `armeabi-v7a` device/emulator (if available)
5. Record APK size. Flag unexplained growth over 2 MB.

### Baseline tracking

To store/update baseline size used for +2 MB growth warnings:

```bash
./scripts/build_android_release.sh --update-baseline
```
