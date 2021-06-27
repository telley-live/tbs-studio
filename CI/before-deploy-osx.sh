hr() {
  echo "───────────────────────────────────────────────────"
  echo $1
  echo "───────────────────────────────────────────────────"
}

# Exit if something fails
set -e

# Generate file name variables
export FINAL_APP_NAME="Telley Viewer"

cd ./build

hr "Packaging DMG"
dmgbuild -s ../CI/install/osx/settings.json "$FINAL_APP_NAME" telley-viewer.dmg

