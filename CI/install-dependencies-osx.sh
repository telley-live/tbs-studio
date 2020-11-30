# Exit if something fails
set -e

# Echo all commands before executing
set -v

#git fetch --unshallow

# Leave obs-studio folder
cd ../

brew update > /dev/null


#Base OBS Deps and ccache
brew install jack ccache clang-format fdk-aac swig

# QT - replace obs one, by brew one.
# brew install https://gist.githubusercontent.com/DDRBoxman/9c7a2b08933166f4b61ed9a44b242609/raw/ef4de6c587c6bd7f50210eccd5bd51ff08e6de13/qt.rb
brew install qt5

# Install Packages app so we can build a package later
# http://s.sudre.free.fr/Software/Packages/about.html
# NOTE ALEX: pretty sure this does not work with latest version of MacOS
wget --retry-connrefused --waitretry=1 https://s3-us-west-2.amazonaws.com/obs-nightly/Packages.pkg
sudo installer -pkg ./Packages.pkg -target /

# Set up ccache
export PATH=/usr/local/opt/ccache/libexec:$PATH
ccache -s || echo "CCache is not available."

# Fetch and untar prebuilt OBS deps that are compatible with older versions of OSX (10.11)
pushd /tmp
wget --retry-connrefused --waitretry=1 https://github.com/telley-live/tbs-studio/releases/download/deps/telley-deps.cpio.bz2
pax -rjf ./telley-deps.cpio.bz2
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
wget --retry-connrefused --waitretry=1 -O sparkle.tar.bz2 https://github.com/sparkle-project/Sparkle/releases/download/1.16.0/Sparkle-1.16.0.tar.bz2
mkdir ./sparkle
tar -xf ./sparkle.tar.bz2 -C ./sparkle
sudo cp -R ./sparkle/Sparkle.framework /Library/Frameworks/Sparkle.framework
