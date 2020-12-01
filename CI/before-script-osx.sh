# Make sure ccache is found
export PATH=/usr/local/opt/ccache/libexec:$PATH
export PKG_CONFIG_PATH=/tmp/telley-deps/lib/pkgconfig
mkdir build
cd build
cmake \
  -DENABLE_SCRIPTING=OFF \
  -DDepsPath=/tmp/telley-deps \
  -DCMAKE_BUILD_TYPE=Release \
  -DVLCPath=/tmp/vlc-3.0.4 \
  -DQTDIR=/usr/local/Cellar/qt/5.14.1 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
  -DOPENSSL_ROOT_DIR=/tmp/telley-deps \
  -Dlibwebrtc_DIR=/tmp/libWebRTC-79.0-x64-Rel-COMMUNITY-BETA/cmake \
  -DBUILD_BROWSER=false \
  -DOBS_VERSION_OVERRIDE=23.2.0 \
  -DCONFIG_DIR=telley-viewer \
  -DSTATIC_MBEDTLS=ON \
  ..
