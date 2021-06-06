# Exit if something fails
set -e

# Echo all commands before executing
set -v

#git fetch --unshallow

#Base OBS Deps and ccache
brew update > /dev/null
brew bundle --file ./CI/Brewfile

# Leave obs-studio folder
cd ../

# Install Packages app so we can build a package later
# http://s.sudre.free.fr/Software/Packages/about.html
# NOTE ALEX: pretty sure this does not work with latest version of MacOS
#wget --retry-connrefused --waitretry=1 https://s3-us-west-2.amazonaws.com/obs-nightly/Packages.pkg
#sudo installer -pkg ./Packages.pkg -target /

pip3 install dmgbuild

# Set up ccache
export PATH=/usr/local/opt/ccache/libexec:$PATH
ccache -s || echo "CCache is not available."

# Fetch and untar prebuilt OBS deps that are compatible with older versions of OSX (10.11)
pushd /tmp
wget --retry-connrefused --waitretry=1 https://github.com/telley-live/tbs-studio/releases/download/deps/telley-deps.cpio.bz2
pax -rjf ./telley-deps.cpio.bz2 || true
popd

# Fetch prebuilt libtelley.dylib
pushd /tmp
echo "Fetching latest libtelley build"
wget --retry-connrefused --waitretry=1 https://github.com/telley-live/tbs-studio/releases/download/deps/libtelley.dylib
pushd telley-deps/include/libtelley
echo "Fetching latest libtelley header"
wget --retry-connrefused --waitretry=1 https://github.com/telley-live/tbs-studio/releases/download/deps/Telley.h -O Telley.h
popd
popd

# if you have your own libwebrtc already installed, comment the following paragraph out.
# Fetch libwebrtc 79 Community Edition
wget --retry-connrefused --waitretry=1 https://github.com/telley-live/tbs-studio/releases/download/deps/libWebRTC-79-mac.tar.gz
tar -xf ./libWebRTC-79-mac.tar.gz -C /tmp

# Fetch vlc codebase
curl -L -O https://downloads.videolan.org/vlc/3.0.4/vlc-3.0.4.tar.xz
tar -xf vlc-3.0.4.tar.xz

# NOTE ALEX: sparkle is for auto-update, if autoupdate is not needed, you can comment out this part.
# Get sparkle
wget --retry-connrefused --waitretry=1 -O sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/1.26.0/Sparkle-1.26.0.tar.xz
mkdir ./sparkle
tar -xf ./sparkle.tar.xz -C ./sparkle
cp -R sparkle /tmp
sudo cp -R ./sparkle/Sparkle.framework /Library/Frameworks/Sparkle.framework
