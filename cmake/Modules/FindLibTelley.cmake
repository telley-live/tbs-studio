# Once done these will be defined:
#
#  LIBTELLEY_FOUND
#  LIBTELLEY_INCLUDE_DIRS
#  LIBTELLEY_LIBRARIES
#
# For use in OBS:
#
#  TELLEY_INCLUDE_DIR

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_lib_suffix 64)
else()
    set(_lib_suffix 32)
endif()

find_path(TELLEY_INCLUDE_DIR
        NAMES Telley.h
        HINTS
        ENV DepsPath${_lib_suffix}
        ENV DepsPath
        ${DepsPath${_lib_suffix}}
        ${DepsPath}
        PATHS
        /usr/include /usr/local/include /opt/local/include /sw/include
        PATH_SUFFIXES
        include
        include/libtelley)

find_library(TELLEY_LIB
        NAMES telley
        HINTS
        ENV DepsPath${_lib_suffix}
        ENV DepsPath
        ${DepsPath${_lib_suffix}}
        ${DepsPath}
        PATHS
        /usr/lib /usr/local/lib /opt/local/lib /sw/lib
        PATH_SUFFIXES
        lib${_lib_suffix} lib
        libs${_lib_suffix} libs
        bin${_lib_suffix} bin
        ../lib${_lib_suffix} ../lib
        ../libs${_lib_suffix} ../libs
        ../bin${_lib_suffix} ../bin)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibTelley DEFAULT_MSG TELLEY_LIB TELLEY_INCLUDE_DIR)
mark_as_advanced(TELLEY_INCLUDE_DIR TELLEY_LIB)

if(LIBTELLEY_FOUND)
    set(LIBTELLEY_INCLUDE_DIRS ${TELLEY_INCLUDE_DIR})
    set(LIBTELLEY_LIBRARIES ${TELLEY_LIB})
endif()
