include(BundleUtilities)

set(_macos_release_install_prefix "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}")
set(_macos_release_bundle
    "${_macos_release_install_prefix}/${MACOS_RELEASE_APP_KEY}.app"
)
set(_macos_release_launcher
    "${_macos_release_bundle}/Contents/MacOS/${MACOS_RELEASE_APP_KEY}"
)

if(NOT EXISTS "${_macos_release_launcher}")
    message(FATAL_ERROR "macOS release launcher is missing: ${_macos_release_launcher}")
endif()

set(_macos_release_extra_executables)
set(_macos_release_crashpad_handler
    "${_macos_release_bundle}/Contents/MacOS/crashpad_handler"
)
if(EXISTS "${_macos_release_crashpad_handler}")
    list(APPEND _macos_release_extra_executables "${_macos_release_crashpad_handler}")
endif()

fixup_bundle(
    "${_macos_release_bundle}"
    "${_macos_release_extra_executables}"
    "${MACOS_RELEASE_BUNDLE_SEARCH_DIRS}"
)

execute_process(
    COMMAND /usr/bin/codesign --force --deep --sign - --timestamp=none
        "${_macos_release_bundle}"
    RESULT_VARIABLE _macos_release_codesign_result
)
if(NOT "${_macos_release_codesign_result}" STREQUAL "0")
    message(FATAL_ERROR
        "Failed to ad-hoc sign macOS app bundle: ${_macos_release_codesign_result}"
    )
endif()
