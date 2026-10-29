#!/bin/bash
set -e

echo "🚀 Сборка FileShifter в релизной конфигурации..."
swift build -c release

BIN_PATH=".build/release/FileShifter"
APP_NAME="FileShifter.app"
APP_DIR="build/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Создание бандла ${APP_NAME}..."
rm -rf "build"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Копируем бинарник
cp "${BIN_PATH}" "${MACOS_DIR}/FileShifter"
chmod +x "${MACOS_DIR}/FileShifter"

# Создаем Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>FileShifter</string>
    <key>CFBundleIdentifier</key>
    <string>com.artem.FileShifter</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FileShifter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>FileShifter использует AppleScript для определения выбранного файла в Finder.</string>
</dict>
</plist>
EOF

# Подписываем ad-hoc подписью для стабильных разрешений Accessibility
echo "✍️ Подписание приложения ad-hoc подписью..."
codesign --force --deep -s - "${APP_DIR}"

echo "✅ Приложение готово: $(pwd)/build/FileShifter.app"
echo "👉 Чтобы установить в систему: cp -R build/FileShifter.app /Applications/"
