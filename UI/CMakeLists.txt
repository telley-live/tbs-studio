if(DISABLE_UI)
	message(STATUS "UI disabled")
	return()
elseif(ENABLE_UI)
	set(FIND_MODE REQUIRED)
else()
	set(FIND_MODE QUIET)
endif()

if(BROWSER_AVAILABLE_INTERNAL)
	add_definitions(-DBROWSER_AVAILABLE)
endif()

add_subdirectory(obs-frontend-api)

# ----------------------------------------------------------------------------

set(_gui_name tv)
project(${_gui_name})

set(DISABLE_UPDATE_MODULE TRUE CACHE BOOL "Disables building the update module")

if(NOT DEFINED TWITCH_CLIENTID OR "${TWITCH_CLIENTID}" STREQUAL "" OR
   NOT DEFINED TWITCH_HASH     OR "${TWITCH_HASH}"     STREQUAL "" OR
   NOT BROWSER_AVAILABLE_INTERNAL)
	set(TWITCH_ENABLED FALSE)
	set(TWITCH_CLIENTID "")
	set(TWITCH_HASH "0")
else()
	set(TWITCH_ENABLED TRUE)
endif()

if(NOT DEFINED MIXER_CLIENTID OR "${MIXER_CLIENTID}" STREQUAL "" OR
   NOT DEFINED MIXER_HASH     OR "${MIXER_HASH}"     STREQUAL "" OR
   NOT BROWSER_AVAILABLE_INTERNAL)
	set(MIXER_ENABLED FALSE)
	set(MIXER_CLIENTID "")
	set(MIXER_HASH "0")
else()
	set(MIXER_ENABLED TRUE)
endif()

if(NOT DEFINED RESTREAM_CLIENTID OR "${RESTREAM_CLIENTID}" STREQUAL "" OR
   NOT DEFINED RESTREAM_HASH     OR "${RESTREAM_HASH}"     STREQUAL "" OR
   NOT BROWSER_AVAILABLE_INTERNAL)
	set(RESTREAM_ENABLED FALSE)
	set(RESTREAM_CLIENTID "")
	set(RESTREAM_HASH "0")
else()
	set(RESTREAM_ENABLED TRUE)
endif()

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/ui-config.h.in"
	"${CMAKE_CURRENT_BINARY_DIR}/ui-config.h")

set(CMAKE_INCLUDE_CURRENT_DIR TRUE)
set(CMAKE_AUTOMOC TRUE)

find_package(Qt5Svg ${FIND_MODE})
find_package(Qt5Network ${FIND_MODE})

find_package(FFmpeg REQUIRED COMPONENTS avcodec avutil avformat)

if(APPLE)
	find_package(Qt5MacExtras REQUIRED)
endif(APPLE)

if(NOT Qt5Widgets_FOUND)
	if (ENABLE_UI)
		message(FATAL_ERROR "Failed to find Qt5")
	else()
		message(STATUS "Qt5 not found - UI disabled")
		return()
	endif()
endif()


include_directories(${FFMPEG_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(SYSTEM "obs-frontend-api")
include_directories(SYSTEM "${CMAKE_SOURCE_DIR}/libobs")
include_directories(SYSTEM "${CMAKE_SOURCE_DIR}/deps/libff")
include_directories(SYSTEM "${CMAKE_SOURCE_DIR}/deps/json11")
if(BROWSER_AVAILABLE_INTERNAL)
	include_directories(SYSTEM "${CMAKE_SOURCE_DIR}/plugins/obs-browser/panel")
endif()

find_package(Libcurl REQUIRED)
include_directories(${LIBCURL_INCLUDE_DIRS})
add_definitions(${LIBCURL_DEFINITIONS})

find_package(LibTelley REQUIRED)
include_directories(${LIBTELLEY_INCLUDE_DIRS})

if(WIN32)
	include_directories(${OBS_JANSSON_INCLUDE_DIRS})
	include_directories(${BLAKE2_INCLUDE_DIR})

	set(obs_PLATFORM_SOURCES
		platform-windows.cpp
		win-update/update-window.cpp
		win-update/win-update.cpp
		win-update/win-update-helpers.cpp
		${obs.rc_DIR}/obs.rc)
	set(obs_PLATFORM_HEADERS
		win-update/update-window.hpp
		win-update/win-update.hpp
		win-update/win-update-helpers.hpp)
	set(obs_PLATFORM_LIBRARIES
		crypt32
		blake2
		${OBS_JANSSON_IMPORT})

	if(CMAKE_SIZEOF_VOID_P EQUAL 4)
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LARGEADDRESSAWARE")
	endif()
elseif(APPLE)
	set(obs_PLATFORM_SOURCES
		platform-osx.mm)

	find_package(AppKit REQUIRED)
	set(obs_PLATFORM_LIBRARIES ${APPKIT_LIBRARIES})

	add_definitions(-fobjc-arc)

	option(ENABLE_SPARKLE_UPDATER "Enables updates via the Sparkle framework (don't forget to update the Info.plist for your .app)" OFF)
	if(ENABLE_SPARKLE_UPDATER)
		find_library(SPARKLE Sparkle
				HINTS
					ENV SparklePath
					${SparklePath})
		include_directories(${SPARKLE})
		set(obs_PLATFORM_SOURCES
			${obs_PLATFORM_SOURCES}
			sparkle-updater.mm)
		set(obs_PLATFORM_LIBRARIES
			${obs_PLATFORM_LIBRARIES}
			${SPARKLE})
		add_definitions(-DUPDATE_SPARKLE=1)
	endif()

elseif(UNIX)
        find_package(Qt5X11Extras REQUIRED)

	set(obs_PLATFORM_SOURCES
		platform-x11.cpp)

        set(obs_PLATFORM_LIBRARIES
                Qt5::X11Extras)
endif()

if(BROWSER_AVAILABLE_INTERNAL)
	list(APPEND obs_PLATFORM_SOURCES
		obf.c
		auth-oauth.cpp
		window-extra-browsers.cpp
		)
	list(APPEND obs_PLATFORM_HEADERS
		obf.h
		auth-oauth.hpp
		window-extra-browsers.hpp
		)

	if(TWITCH_ENABLED)
		list(APPEND obs_PLATFORM_SOURCES
			auth-twitch.cpp
			)
		list(APPEND obs_PLATFORM_HEADERS
			auth-twitch.hpp
			)
	endif()

	if(MIXER_ENABLED)
		list(APPEND obs_PLATFORM_SOURCES
			auth-mixer.cpp
			)
		list(APPEND obs_PLATFORM_HEADERS
			auth-mixer.hpp
			)
	endif()

	if(RESTREAM_ENABLED)
		list(APPEND obs_PLATFORM_SOURCES
			auth-restream.cpp
			)
		list(APPEND obs_PLATFORM_HEADERS
			auth-restream.hpp
			)
	endif()
endif()

set(obs_libffutil_SOURCES
	../deps/libff/libff/ff-util.c
	)
set(obs_libffutil_HEADERS
	../deps/libff/libff/ff-util.h
	)

if(MSVC)
	set_source_files_properties(
		../deps/libff/libff/ff-util.c
		PROPERTIES COMPILE_FLAGS -Dinline=__inline
		)
endif()

set(obs_SOURCES
	${obs_PLATFORM_SOURCES}
	${obs_libffutil_SOURCES}
	../deps/json11/json11.cpp
	obs-app.cpp
	window-dock.cpp
	api-interface.cpp
	window-basic-main.cpp
	window-basic-stats.cpp
	window-basic-filters.cpp
	window-basic-settings.cpp
	window-basic-interaction.cpp
	window-basic-properties.cpp
	window-basic-auto-config.cpp
	window-basic-main-outputs.cpp
	window-basic-source-select.cpp
	window-basic-settings-stream.cpp
	window-basic-auto-config-test.cpp
	window-basic-main-scene-collections.cpp
	window-basic-main-transitions.cpp
	window-basic-main-dropfiles.cpp
	window-basic-main-profiles.cpp
	window-basic-main-browser.cpp
	window-basic-status-bar.cpp
	window-basic-adv-audio.cpp
	window-basic-transform.cpp
	window-basic-preview.cpp
	window-basic-about.cpp
	window-namedialog.cpp
	window-log-reply.cpp
	window-projector.cpp
	window-remux.cpp
	auth-base.cpp
	source-tree.cpp
	properties-view.cpp
	focus-list.cpp
	menu-button.cpp
	double-slider.cpp
	slider-ignorewheel.cpp
	combobox-ignorewheel.cpp
	spinbox-ignorewheel.cpp
	record-button.cpp
	volume-control.cpp
	adv-audio-control.cpp
	item-widget-helpers.cpp
	horizontal-scroll-area.cpp
	vertical-scroll-area.cpp
	visibility-item-widget.cpp
	slider-absoluteset-style.cpp
	qt-display.cpp
	crash-report.cpp
	hotkey-edit.cpp
	source-label.cpp
	remote-text.cpp
	audio-encoders.cpp
	qt-wrappers.cpp)

set(obs_HEADERS
	${obs_PLATFORM_HEADERS}
	${obs_libffutil_HEADERS}
	../deps/json11/json11.hpp
	obs-app.hpp
	platform.hpp
	window-dock.hpp
	window-main.hpp
	window-basic-main.hpp
	window-basic-stats.hpp
	window-basic-filters.hpp
	window-basic-settings.hpp
	window-basic-interaction.hpp
	window-basic-properties.hpp
	window-basic-auto-config.hpp
	window-basic-main-outputs.hpp
	window-basic-source-select.hpp
	window-basic-about.hpp
	window-basic-status-bar.hpp
	window-basic-adv-audio.hpp
	window-basic-transform.hpp
	window-basic-preview.hpp
	window-namedialog.hpp
	window-log-reply.hpp
	window-projector.hpp
	window-remux.hpp
	auth-base.hpp
	source-tree.hpp
	properties-view.hpp
	properties-view.moc.hpp
	display-helpers.hpp
	balance-slider.hpp
	double-slider.hpp
	slider-ignorewheel.hpp
	combobox-ignorewheel.hpp
	spinbox-ignorewheel.hpp
	focus-list.hpp
	menu-button.hpp
	mute-checkbox.hpp
	record-button.hpp
	volume-control.hpp
	adv-audio-control.hpp
	item-widget-helpers.hpp
	visibility-checkbox.hpp
	locked-checkbox.hpp
	horizontal-scroll-area.hpp
	expand-checkbox.hpp
	vertical-scroll-area.hpp
	visibility-item-widget.hpp
	slider-absoluteset-style.hpp
	qt-display.hpp
	crash-report.hpp
	hotkey-edit.hpp
	source-label.hpp
	remote-text.hpp
	audio-encoders.hpp
	qt-wrappers.hpp
	clickable-label.hpp)

set(obs_UI
	forms/NameDialog.ui
	forms/AutoConfigStartPage.ui
	forms/AutoConfigVideoPage.ui
	forms/AutoConfigStreamPage.ui
	forms/AutoConfigTestPage.ui
	forms/ColorSelect.ui
	forms/OBSLogReply.ui
	forms/OBSBasic.ui
	forms/OBSBasicTransform.ui
	forms/OBSBasicFilters.ui
	forms/OBSBasicSettings.ui
	forms/OBSBasicSourceSelect.ui
	forms/OBSBasicInteraction.ui
	forms/OBSExtraBrowsers.ui
	forms/OBSUpdate.ui
	forms/OBSRemux.ui
	forms/OBSAbout.ui
		)

set(obs_QRC
	forms/obs.qrc)

qt5_wrap_ui(obs_UI_HEADERS ${obs_UI})
qt5_add_resources(obs_QRC_SOURCES ${obs_QRC})

message( STATUS "rc file: ${obs_QRC_SOURCES}." )

add_executable( ${_gui_name} WIN32
	${obs_SOURCES}
	${obs_HEADERS}
	${obs_UI_HEADERS}
	${obs_QRC_SOURCES}
)

if(WIN32)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(_output_suffix "64")
	else()
		set(_output_suffix "32")
	endif()

	set_target_properties(${_gui_name}
		PROPERTIES
			OUTPUT_NAME "${_gui_name}${_output_suffix}")
	target_compile_options(${_gui_name} PRIVATE "/MD$<$<CONFIG:Debug>:d>")
endif()

target_link_libraries(${_gui_name}
	libobs
	Qt5::Widgets
	Qt5::Svg
	Qt5::Network
	obs-frontend-api
	${FFMPEG_LIBRARIES}
	${LIBCURL_LIBRARIES}
	${obs_PLATFORM_LIBRARIES})

if (APPLE)
	target_link_libraries(${_gui_name}
			Qt5::MacExtras)
	set_target_properties(${_gui_name} PROPERTIES LINK_FLAGS "-pagezero_size 10000 -image_base 100000000")
	set_property(
		TARGET ${_gui_name}
		APPEND
		PROPERTY INSTALL_RPATH
		"/usr/local/Cellar/python3/3.6.4_2/Frameworks/Python.framework/Versions/3.6/lib/"
		"/Library/Frameworks/Python.framework/Versions/3.6/lib/"
		"/opt/local/Library/Frameworks/Python.framework/Versions/3.6/lib/"
	)
endif()

define_graphic_modules(${_gui_name})

install_obs_core(${_gui_name})
install_obs_data(${_gui_name} data ${CONFIG_DIR})
install_obs_data_file(${_gui_name} ../AUTHORS ${CONFIG_DIR}/authors)

if (UNIX AND UNIX_STRUCTURE AND NOT APPLE)
	add_subdirectory(xdg-data)
endif()

add_subdirectory(frontend-plugins)
if(WIN32)
	add_subdirectory(win-update/updater)
endif()

