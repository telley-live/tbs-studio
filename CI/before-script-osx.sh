# Make sure ccache is found
export PATH=/usr/local/opt/ccache/libexec:$PATH
export PKG_CONFIG_PATH=/tmp/telley-deps/lib/pkgconfig
mkdir build
cd build
cmake \
  -DENABLE_SCRIPTING=OFF \
  -DDepsPath=/tmp/telley-deps \
  -DFFmpegPath=/tmp/telley-deps \
  -DCMAKE_BUILD_TYPE=Release \
  -DVLCPath=/tmp/vlc-3.0.4 \
  -DQTDIR=$(brew --prefix qt5) \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
  -DOPENSSL_ROOT_DIR=/tmp/telley-deps \
  -Dlibwebrtc_DIR=/tmp/libWebRTC-79.0-x64-Rel-COMMUNITY-BETA/cmake \
  -DBUILD_BROWSER=false \
  -DOBS_VERSION_OVERRIDE=23.2.7 \
  -DCONFIG_DIR=telley-viewer \
  -DSTATIC_MBEDTLS=ON \
  -DOBS_OSX_BUNDLE=1 \
  -DENABLE_SPARKLE_UPDATER=ON \
  -DcurlPath=/usr \
  -DSparklePath=/tmp/sparkle \
  ..
