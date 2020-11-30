hr() {
  echo "───────────────────────────────────────────────────"
  echo $1
  echo "───────────────────────────────────────────────────"
}

# Exit if something fails
set -e

# Generate file name variables
export APP_NAME="TelleyViewer"
export FINAL_APP_NAME="Telley Viewer"
export LIBWEBRTC_REV=79
export DEPLOY_VERSION=23.2
export GIT_HASH=$(git rev-parse --short HEAD)
export FILE_DATE=$(date +%Y-%m-%d.%H:%M:%S)
export BUILD_CONFIG=Release

cd ./build

hr "Packaging DMG"
dmgbuild -s ../CI/install/osx/settings.json "$FINAL_APP_NAME" telley-viewer.dmg

