if(MACOS_CONFIGURATION_TYPES)
    set(_macos_actual_configuration "${MACOS_REQUESTED_CONFIGURATION}")
else()
    set(_macos_actual_configuration "${MACOS_BUILD_TYPE}")
endif()

if(NOT "${_macos_actual_configuration}" STREQUAL "${MACOS_EXPECTED_CONFIGURATION}")
    message(FATAL_ERROR
        "The macOS ${MACOS_EXPECTED_CONFIGURATION} target requires a "
        "${MACOS_EXPECTED_CONFIGURATION} build configuration, but this build uses "
        "'${_macos_actual_configuration}'. Configure a separate build directory "
        "with -DCMAKE_BUILD_TYPE=${MACOS_EXPECTED_CONFIGURATION}, or select the "
        "matching --config for a multi-configuration generator."
    )
endif()
