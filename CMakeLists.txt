cmake_minimum_required(VERSION 2.8.12)

if (UNIX AND POLICY CMP0072)
	# In case of both legacy and glvnd OpenGL libraries found. Prefer GLVND
	cmake_policy(SET CMP0072 NEW)
endif()
if( APPLE AND POLICY CMP0068 )
        cmake_policy(SET CMP0068 NEW)
endif()
if( POLICY CMP0048 )
        cmake_policy(SET CMP0048 NEW)
endif()

if(NOT OBS_WEBRTC_VENDOR_NAME)
	set(_project_name obs-studio)
else()
	set(_project_name ${OBS_WEBRTC_VENDOR_NAME})
endif()
project(${_project_name} VERSION 23.2.0)

if(NOT DEFINED CONFIG_DIR OR "${CONFIG_DIR}" STREQUAL "")
	if(NOT OBS_WEBRTC_VENDOR_NAME)
		set(CONFIG_DIR "obs-webrtc")
	else()
		set(CONFIG_DIR ${OBS_WEBRTC_VENDOR_NAME})
	endif()
endif()

# --- Handle CMake Options
#
# does not use a project unique prefix, prone to overlap.
#
option(BUILD_CAPTIONS "Build captions" FALSE)

# --- Handle Project Dependencies
#
# supposes that the super build, or the user uses QTDIR (CLI or ENV), QTDIR32 and or QTDIR64 (ENV only)
# and not the more standard Qt5_DIR variable. Brittle.
#
# supposes that the DepsPath variable exists and point to the obs precompile dependencies.
# Could be improved thourgh a superbuild script to make it fully deterministic.
#
if(WIN32)
	if (QTDIR OR DEFINED ENV{QTDIR} OR DEFINED ENV{QTDIR32} OR DEFINED ENV{QTDIR64})
		# Qt path set by user or env var
	else()
		set(QTDIR "" CACHE PATH "Path to Qt (e.g. C:/Qt/5.7/msvc2015_64)")
		message(WARNING "QTDIR variable is missing.  Please set this variable to specify path to Qt (e.g. C:/Qt/5.7/msvc2015_64)")
	endif()
	if (DepsPath OR DEFINED ENV{DepsPath} OR DEFINED ENV{DepsPath32} OR DEFINED ENV{DepsPath64})
		# Dependencies path set by user or env var
	else()
		set(DepsPath "" CACHE PATH "Path to compiled dependencies (e.g. D:/dependencies/win64)")
		message(WARNING "DepsPath variable is missing.  Please set this variable to specify path to compiled dependencies (e.g. D:/dependencies/win64)")
	endif()
endif()

# --- manage vendor look and feel

if( OBS_WEBRTC_VENDOR_NAME )
	add_subdirectory( vendor_skins )
endif()

# --- extend cmake with our own scripts, macros and modules

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/" ${CMAKE_MODULE_PATH})
set(ENABLE_SCRIPTING TRUE CACHE BOOL "Enables scripting")
set(SCRIPTING_ENABLED OFF CACHE BOOL "Internal global cmake variable" FORCE)

include(ObsHelpers)
include(ObsCpack)
include(GNUInstallDirs)

# Must be a string in the format of "x.x.x-rcx"
if(DEFINED RELEASE_CANDIDATE)
	set(OBS_VERSION "${RELEASE_CANDIDATE}")
	string(REPLACE "-rc" "." RC_SPLIT ${RELEASE_CANDIDATE})
	string(REPLACE "." ";" RC_SPLIT ${RC_SPLIT})
	message(WARNING "******************************************************************************\nRelease candidate deteced, OBS_VERSION is now: ${OBS_VERSION}\n******************************************************************************")
	list(GET RC_SPLIT 0 OBS_RELEASE_CANDIDATE_MAJOR)
	list(GET RC_SPLIT 1 OBS_RELEASE_CANDIDATE_MINOR)
	list(GET RC_SPLIT 2 OBS_RELEASE_CANDIDATE_PATCH)
	list(GET RC_SPLIT 3 OBS_RELEASE_CANDIDATE)
else()
	set(OBS_RELEASE_CANDIDATE_MAJOR 0)
	set(OBS_RELEASE_CANDIDATE_MINOR 0)
	set(OBS_RELEASE_CANDIDATE_PATCH 0)
	set(OBS_RELEASE_CANDIDATE 0)
endif()

# Binary Versioning for Windows
if(WIN32)
	string(REPLACE "-" ";" UI_VERSION_SPLIT ${OBS_VERSION})
	list(GET UI_VERSION_SPLIT 0 UI_VERSION)
	string(REPLACE "." ";" UI_VERSION_SEMANTIC ${UI_VERSION})
	list(GET UI_VERSION_SEMANTIC 0 UI_VERSION_MAJOR)
	list(GET UI_VERSION_SEMANTIC 1 UI_VERSION_MINOR)
	list(GET UI_VERSION_SEMANTIC 2 UI_VERSION_PATCH)
	configure_file(UI/obs.rc.in ${PROJECT_BINARY_DIR}/obs.rc)
        set( obs.rc_DIR ${PROJECT_BINARY_DIR} )
endif()

# --- Handle Compiler Settings

if(MSVC AND NOT EXISTS "${CMAKE_BINARY_DIR}/ALL_BUILD.vcxproj.user")
	file(GENERATE
		OUTPUT "${CMAKE_BINARY_DIR}/ALL_BUILD.vcxproj.user"
		INPUT "${CMAKE_SOURCE_DIR}/cmake/ALL_BUILD.vcxproj.user.in")
endif()

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

find_package(CXX11 REQUIRED)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX11_FLAGS}")

if(${CMAKE_C_COMPILER_ID} MATCHES "Clang" OR ${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
	set(CMAKE_COMPILER_IS_CLANG TRUE)
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(powerpc|ppc)64le")
	add_compile_definitions(NO_WARN_X86_INTRINSICS)
endif()

if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
	set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wno-unused-function -Werror-implicit-function-declaration -Wno-missing-field-initializers ${CMAKE_CXX_FLAGS} -fno-strict-aliasing")
	set(CMAKE_C_FLAGS "-Wall -Wextra -Wno-unused-function -Werror-implicit-function-declaration -Wno-missing-braces -Wno-missing-field-initializers ${CMAKE_C_FLAGS} -std=gnu99 -fno-strict-aliasing")

	option(USE_LIBC++ "Use libc++ instead of libstdc++" ${APPLE})
	if(USE_LIBC++)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
	endif()
elseif(MSVC)
	if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
		string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
	endif()

	# Disable pointless constant condition warnings
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4127 /wd4201 /wd4456 /wd4457 /wd4458 /wd4459 /wd4595")
endif()

if(WIN32)
	add_definitions(-DUNICODE -D_UNICODE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS)
endif()

if(MSVC)
	add_compile_options("/MP")
	set(CMAKE_C_FLAGS_DEBUG "/DDEBUG=1 /D_DEBUG=1 ${CMAKE_C_FLAGS_DEBUG}")
	set(CMAKE_CXX_FLAGS_DEBUG "/DDEBUG=1 /D_DEBUG=1 ${CMAKE_C_FLAGS_DEBUG}")

	if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SAFESEH:NO")
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO")
		set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /SAFESEH:NO")
	endif()
else()
	if(MINGW)
		set(CMAKE_WIDL "widl" CACHE STRING "wine IDL header file generation program")
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_WIN32_WINNT=0x0600 -DWINVER=0x0600")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_WIN32_WINNT=0x0600 -DWINVER=0x0600")
	endif()
	set(CMAKE_C_FLAGS_DEBUG "-DDEBUG=1 -D_DEBUG=1 ${CMAKE_C_FLAGS_DEBUG}")
	set(CMAKE_CXX_FLAGS_DEBUG "-DDEBUG=1 -D_DEBUG=1 ${CMAKE_C_FLAGS_DEBUG}")
endif()

if(APPLE)
	set(CMAKE_MACOSX_RPATH TRUE)
	set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
	list(APPEND CMAKE_INSTALL_RPATH "@loader_path/" "@executable_path/")
elseif(UNIX)
	option(USE_XDG "Utilize XDG Base Directory Specification" ON)
	if(USE_XDG)
		add_definitions(-DUSE_XDG)
	endif()
	if(NOT UNIX_STRUCTURE)
		list(APPEND CMAKE_INSTALL_RPATH "$ORIGIN")
	endif()
endif()

option( BUILD_TESTS "Build test directory (includes test sources and possibly a platform test executable)" FALSE)
mark_as_advanced(BUILD_TESTS)


# --- Handle source code, UI, package, ....

if(NOT INSTALLER_RUN)
	option(ENABLE_UI "Enables the OBS user interfaces" ON)
	if(DISABLE_UI OR NOT ENABLE_UI)
		set(UI_ENABLED FALSE)
	else()
		set(UI_ENABLED TRUE)

		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			set(_lib_suffix 64)
		else()
			set(_lib_suffix 32)
		endif()

		if(DEFINED QTDIR${_lib_suffix})
			list(APPEND CMAKE_PREFIX_PATH "${QTDIR${_lib_suffix}}")
		elseif(DEFINED QTDIR)
			list(APPEND CMAKE_PREFIX_PATH "${QTDIR}")
		elseif(DEFINED ENV{QTDIR${_lib_suffix}})
			list(APPEND CMAKE_PREFIX_PATH "$ENV{QTDIR${_lib_suffix}}")
		elseif(DEFINED ENV{QTDIR})
			list(APPEND CMAKE_PREFIX_PATH "$ENV{QTDIR}")
		endif()

		find_package(Qt5Widgets ${FIND_MODE})
                if( APPLE )
                        # Make sure we are using Qt installed by brew
                        list(GET Qt5Widgets_INCLUDE_DIRS 1 my_path)
                        string(FIND ${my_path} "/usr/local/Cellar/" cellar_index)
                        string(FIND ${my_path} "/usr/local/opt/" opt_index)
                        if( ${cellar_index} EQUAL -1 AND ${opt_index} EQUAL -1 )
                                message( "ERROR, you must give path to a Qt installed by brew." )
                        endif()
                endif()
	endif()

	add_subdirectory(deps)

	if(WIN32)
		add_subdirectory(libobs-d3d11)
	endif()

	add_subdirectory(libobs-opengl)
	add_subdirectory(libobs)
	add_subdirectory(plugins)
	add_subdirectory(UI)
	if (BUILD_TESTS)
		add_subdirectory(test)
	endif()

	add_subdirectory(cmake/helper_subdir)
else()
	# if INSTALLER_RUN
	obs_generate_multiarch_installer()
endif()

# this prepares the packaging by copying over
# all binaries needed. Make sure to extend
# if you add any binary or dependency
include(CopyMSVCBins)

# enable submissions to a CDash server
enable_testing()
include(CTest)

