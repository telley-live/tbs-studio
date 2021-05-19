#!/bin/bash

QT_REV=$(brew list --versions qt | cut -d' ' -f2)
QT_PREFIX=$(brew --prefix qt5)
EXE_NAME=tv

rm -rf "./$APP_NAME.app"

mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/PlugIns"
mkdir -p "$APP_NAME.app/Contents/Resources"
mkdir -p "$APP_NAME.app/Contents/Frameworks"

cp -r rundir/$BUILD_CONFIG/bin/                         "./$APP_NAME.app/Contents/MacOS"
cp -r rundir/$BUILD_CONFIG/data                         "./$APP_NAME.app/Contents/Resources"
cp ../CI/install/osx/telley.icns                        "./$APP_NAME.app/Contents/Resources"
cp -r rundir/$BUILD_CONFIG/obs-plugins/                 "./$APP_NAME.app/Contents/PlugIns"
cp ../CI/install/osx/Info.plist                         "./$APP_NAME.app/Contents"
cp /tmp/telley-deps/lib/lib{av,sw,postproc}*.*.dylib    "./$APP_NAME.app/Contents/MacOS"
cp /tmp/libtelley.dylib                                 "./$APP_NAME.app/Contents/Frameworks"

if [ -f "./$APP_NAME.app/Contents/PlugIns/linux-jack.so" ] ; then
  rm "./$APP_NAME.app/Contents/PlugIns/linux-jack.so"
fi
if [ -f "./$APP_NAME.app/Contents/PlugIns/obs-libfdk.so" ] ; then
  rm "./$APP_NAME.app/Contents/PlugIns/obs-libfdk.so"
fi

$(brew --prefix dylibbundler)/bin/dylibBundler -b -cd -d "./$APP_NAME.app/Contents/Frameworks" -p @executable_path/../Frameworks/ \
-s "./$APP_NAME.app/Contents/MacOS" \
-s "./$APP_NAME.app/Contents/PlugIns" \
-s "./$APP_NAME.app/Contents/Frameworks" \
-s /tmp/telley-deps/lib \
-x "./$APP_NAME.app/Contents/PlugIns/coreaudio-encoder.so" \
-x "./$APP_NAME.app/Contents/PlugIns/decklink-output-ui.so" \
-x "./$APP_NAME.app/Contents/PlugIns/frontend-tools.so" \
-x "./$APP_NAME.app/Contents/PlugIns/image-source.so" \
-x "./$APP_NAME.app/Contents/PlugIns/mac-avcapture.so" \
-x "./$APP_NAME.app/Contents/PlugIns/mac-capture.so" \
-x "./$APP_NAME.app/Contents/PlugIns/mac-decklink.so" \
-x "./$APP_NAME.app/Contents/PlugIns/mac-syphon.so" \
-x "./$APP_NAME.app/Contents/PlugIns/mac-vth264.so" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-ffmpeg.so" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-filters.so" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-transitions.so" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-vst.so" \
-x "./$APP_NAME.app/Contents/PlugIns/rtmp-services.so" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-outputs.so" \
-x "./$APP_NAME.app/Contents/MacOS/$EXE_NAME" \
-x "./$APP_NAME.app/Contents/MacOS/obs-ffmpeg-mux" \
-x "./$APP_NAME.app/Contents/PlugIns/obs-x264.so" \
-x "./$APP_NAME.app/Contents/PlugIns/text-freetype2.so"

$QT_PREFIX/bin/macdeployqt "./$APP_NAME.app"

mv "./$APP_NAME.app/Contents/MacOS/libobs-opengl.so" "./$APP_NAME.app/Contents/Frameworks"

# decklink ui qt
install_name_tool -change $QT_PREFIX/lib/QtGui.framework/Versions/5/QtGui @executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui "./$APP_NAME.app/Contents/PlugIns/decklink-output-ui.so"
install_name_tool -change $QT_PREFIX/lib/QtCore.framework/Versions/5/QtCore @executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore "./$APP_NAME.app/Contents/PlugIns/decklink-output-ui.so"
install_name_tool -change $QT_PREFIX/lib/QtWidgets.framework/Versions/5/QtWidgets @executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets "./$APP_NAME.app/Contents/PlugIns/decklink-output-ui.so"

# frontend tools qt
install_name_tool -change $QT_PREFIX/lib/QtGui.framework/Versions/5/QtGui @executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui "./$APP_NAME.app/Contents/PlugIns/frontend-tools.so"
install_name_tool -change $QT_PREFIX/lib/QtCore.framework/Versions/5/QtCore @executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore "./$APP_NAME.app/Contents/PlugIns/frontend-tools.so"
install_name_tool -change $QT_PREFIX/lib/QtWidgets.framework/Versions/5/QtWidgets @executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets "./$APP_NAME.app/Contents/PlugIns/frontend-tools.so"

# vst qt
install_name_tool -change $QT_PREFIX/lib/QtGui.framework/Versions/5/QtGui @executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui "./$APP_NAME.app/Contents/PlugIns/obs-vst.so"
install_name_tool -change $QT_PREFIX/lib/QtCore.framework/Versions/5/QtCore @executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore "./$APP_NAME.app/Contents/PlugIns/obs-vst.so"
install_name_tool -change $QT_PREFIX/lib/QtWidgets.framework/Versions/5/QtWidgets @executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets "./$APP_NAME.app/Contents/PlugIns/obs-vst.so"
install_name_tool -change $QT_PREFIX/lib/QtMacExtras.framework/Versions/5/QtMacExtras @executable_path/../Frameworks/QtMacExtras.framework/Versions/5/QtMacExtras "./$APP_NAME.app/Contents/PlugIns/obs-vst.so"

# libtelley
install_name_tool -change $QT_PREFIX/lib/QtGui.framework/Versions/5/QtGui @executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui "./$APP_NAME.app/Contents/Frameworks/libtelley.dylib"
install_name_tool -change $QT_PREFIX/lib/QtCore.framework/Versions/5/QtCore @executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore "./$APP_NAME.app/Contents/Frameworks/libtelley.dylib"
install_name_tool -change $QT_PREFIX/lib/QtWidgets.framework/Versions/5/QtWidgets @executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets "./$APP_NAME.app/Contents/Frameworks/libtelley.dylib"
install_name_tool -change $QT_PREFIX/lib/QtNetwork.framework/Versions/5/QtNetwork @executable_path/../Frameworks/QtNetwork.framework/Versions/5/QtNetwork "./$APP_NAME.app/Contents/Frameworks/libtelley.dylib"

# qt plugins
for folder in {bearer,iconengines,imageformats,platforminputcontexts,platforms,printsupport,styles,virtualkeyboard} ; do
  pushd "./$APP_NAME.app/Contents/PlugIns/$folder"
  for plugin in *.dylib ; do
    plugin_base=$(basename $plugin)
    install_name_tool -id "@executable_path/../PlugIns/$folder/$plugin_base" $plugin_base
  done
  popd
done
