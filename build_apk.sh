#!/bin/bash
# Build Android APK with license acceptance

export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"

echo "=== Accepting Android SDK Licenses ==="
flutter doctor --android-licenses <<EOF
y
y
y
y
y
y
y
y
y
y
EOF

echo ""
echo "=== Building Release APK ==="
cd /home/frankbria/projects/pachinko
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
    ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo "APK file check failed"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
