# These dependencies are used in multiple places.
# If it makes sense to use the dep for only one target it does not belong here.

include(Boost)

if(APPLE)
    # Recent Apple Clang SDKs already declare these standard-library types.
    # Avoid range-v3's legacy redeclarations of them.
    add_compile_definitions(META_NO_STD_FORWARD_DECLARATIONS)
    # The Command Line Tools and Xcode SDK headers may disagree on availability
    # annotations while targeting an older macOS release.
    add_compile_options(-Wno-error=unguarded-availability-new)

    foreach(prefix IN LISTS CMAKE_PREFIX_PATH)
        if(IS_DIRECTORY "${prefix}/include")
            include_directories(BEFORE SYSTEM "${prefix}/include")
        endif()
    endforeach()
endif()

if(SLIC3R_STATIC)
    set(TBB_STATIC 1)
endif()
set(TBB_DEBUG 1)
find_package(TBB REQUIRED)
slic3r_remap_configs(TBB::tbb RelWithDebInfo Release)
slic3r_remap_configs(TBB::tbbmalloc RelWithDebInfo Release)

find_package(Boost REQUIRED COMPONENTS filesystem)

find_package(NLopt 1.4 REQUIRED)
slic3r_remap_configs(NLopt::nlopt RelWithDebInfo Release)

# Find expat. We have our overriden FindEXPAT which exports libexpat target
# no matter what.
find_package(EXPAT REQUIRED)

add_library(libexpat INTERFACE)

if (TARGET EXPAT::EXPAT ) # found by a newer Find script
    target_link_libraries(libexpat INTERFACE EXPAT::EXPAT)
elseif(TARGET expat::expat) # found by a config script
    target_link_libraries(libexpat INTERFACE expat::expat)
else() # found by an older Find script
    target_link_libraries(libexpat INTERFACE ${EXPAT_LIBRARIES})
endif ()

find_package(PNG REQUIRED)

if(SLIC3R_GUI)
    set(OpenGL_GL_PREFERENCE "LEGACY")
    find_package(OpenGL REQUIRED)

    if (NOT EMSCRIPTEN)
        # The GLEW is bundled with Emscripten SDK, but has no .cmake files
        # So it can't be found
        # Instead it is just part of OPENGL_LIBRARIES
        find_package(GLEW REQUIRED)
    endif()

    add_library(PlatformGL INTERFACE)
    if (EMSCRIPTEN)
        # OpenGL::GL and GLEW::GLEW are part of OPENGL_LIBRARIES
        target_include_directories(PlatformGL INTERFACE ${OPENGL_INCLUDE_DIR})
        target_link_libraries(PlatformGL INTERFACE ${OPENGL_LIBRARIES})
    else()
        target_link_libraries(PlatformGL INTERFACE OpenGL::GL GLEW::GLEW)
    endif()
endif()

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
endif()

# Find the Cereal serialization library
find_package(cereal 1.3.2 REQUIRED)
add_library(libcereal INTERFACE)
if (NOT TARGET cereal::cereal)
    target_link_libraries(libcereal INTERFACE cereal)
else()
    target_link_libraries(libcereal INTERFACE cereal::cereal)
endif()

find_package(fmt REQUIRED)
slic3r_remap_configs(fmt::fmt RelWithDebInfo Release)

find_package(Tracy REQUIRED)
