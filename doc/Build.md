# Building from source
These are the build steps for Windows, MacOS and Linux. Depending on your hardware the dependencies compilation may take a significant amount of time (hours). PrusaSlicer compilation is also not instant. 

## 0. Prerequisites

### Windows
 - `Microsoft Visual Studio`
 - `CMake`
 - `git`.
### MacOS
- [Xcode](https://developer.apple.com/xcode/) and its Command Line Tools.
- [Homebrew](https://brew.sh) to install the required build dependencies.

```bash
xcode-select --install
brew update && brew install automake cmake gettext git libomp libtool ninja texinfo
```
### Linux
For example on Ubuntu 26.04:
```bash
sudo apt install git build-essential autoconf cmake libtool libglu1-mesa-dev libgtk-3-dev libdbus-1-dev libwebkit2gtk-4.1-dev texinfo
```
or for Fedora 44:
```bash
sudo dnf install cmake g++ git-core m4 texinfo autoconf automake libtool perl-FindBin perl-lib perl-IPC-Cmd perl-Time-Piece webkit2gtk4.1-devel zlib-devel zlib-static libpng-static
```
Adapt it for your package manager and packages provided by your operating system.
## 1. Build dependencies
From the repository root:
```bash
cmake -S deps -B deps/build
cmake --build deps/build
```

## 1.1 Ensure dependencies build succeeded
After the dependencies build finishes, run `cmake --build deps/build` again. It should be close to instant, **complete successfully** and no additional work should be done. For example, using `make`, it should say something along the lines of:
```
make: Nothing to be done for 'all'.
```

## 2. Build PrusaSlicer
From the repository root:

- **Unix shells or PowerShell:** use `$PWD` for the current directory
```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH="$PWD/deps/build/destdir/usr/local"
cmake --build build
```

- **Windows `cmd.exe`**: use `%CD%` for the current directory
```cmd
cmake -S . -B build -DCMAKE_PREFIX_PATH="%CD%/deps/build/destdir/usr/local"
cmake --build build
```

### 2.1. macOS (Tahoe)

> [!NOTE]
> This is a Tahoe-specific native Apple Silicon Release build using AppleClang and a macOS 26.0 deployment target. It keeps Homebrew headers and libraries out of dependency discovery to avoid mixing them with the bundled dependencies. Xcode 27's libc++ headers no longer support targeting macOS 10.15.

Use [AppleClang, the compiler toolchain shipped with Xcode](https://developer.apple.com/documentation/xcode-release-notes). If your shell sets `CC` or `CXX` to a Homebrew LLVM compiler, the commands below explicitly unset those variables.

#### 2.1.1. Build The Project Dependencies

Build the dependencies from the repository root:

```bash
env -u CC -u CXX -u CPPFLAGS -u CFLAGS -u CXXFLAGS \
  cmake -S deps -B deps/build-macos-tahoe -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
    -DCMAKE_C_COMPILER=/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++

cmake --build deps/build-macos-tahoe --parallel 1
```

The dependency build is intentionally single-threaded; its external projects select their own parallelism.

#### 2.1.2. Configure Build

> [!NOTE]
> `DEPS_PREFIX` points to the staged install prefix from the dependency build above. Passing it as `CMAKE_PREFIX_PATH` lets CMake find those dependencies, while `Boost_DIR` and `fmt_DIR` select package configs within that same prefix.

Configure PrusaSlicer to use only the dependency prefix built above. Do not add `/opt/homebrew` to `CMAKE_PREFIX_PATH`. Use `-DCMAKE_BUILD_TYPE=Release` for a release bundle, or change it to `Debug` for a debug bundle:

```bash
DEPS_PREFIX="$PWD/deps/build-macos-tahoe/destdir/usr/local"

env -u CC -u CXX -u CPPFLAGS -u CFLAGS -u CXXFLAGS \
  cmake -S . -B build-macos-tahoe -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
  -DCMAKE_PREFIX_PATH="$DEPS_PREFIX" \
  -DBoost_DIR="$DEPS_PREFIX/lib/cmake/Boost-1.86.0" \
  -Dfmt_DIR="$DEPS_PREFIX/lib/cmake/fmt" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/opt/homebrew/opt/libomp/lib"

cmake --build build-macos-tahoe --parallel "$(sysctl -n hw.ncpu)"
```

#### 2.1.3. Build a macOS `.app` bundle

> [!IMPORTANT]
> The targets ad-hoc sign the app bundle after fixing up library paths so it can launch locally. They do not use a Developer ID certificate or notarize the app for distribution.

Build the target matching the configured build type:

```bash
cmake --build build-macos-tahoe --target macos-release \
  --parallel "$(sysctl -n hw.ncpu)"
```

Use `macos-debug` instead for a Debug build. For a multi-configuration generator, add the matching `--config Debug` or `--config Release`; for a single-configuration generator, `CMAKE_BUILD_TYPE` must match the target.

The target creates the app bundle at `build-macos-tahoe/macos-release/PrusaSlicer.app`. For a Debug build, it is created at `build-macos-tahoe/macos-debug/PrusaSlicer.app`.

The targets bundle non-system dynamic libraries and fix their load paths; macOS provides the system libraries and frameworks. Inspect the launcher dependencies with:

```bash
otool -L "$PWD/build-macos-tahoe/macos-release/PrusaSlicer.app/Contents/MacOS/PrusaSlicer"
```

## 3. Run tests (optional)
From the repository root:
```bash
ctest --test-dir build
```

## Advanced build options
The standard `CMAKE_BUILD_TYPE` option is supported. Furthermore there are
several more build options provided by PrusaSlicer. These options have the
`SLIC3R_` prefix and can be passed to cmake during in the `Build PrusaSlicer`
step. E.g.:
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DSLIC3R_ASAN=ON -DCMAKE_PREFIX_PATH="$PWD/../deps/build/destdir/usr/local"
```
See the main CMakeLists.txt for the full list.


## Troubleshooting
There is a known error that may occur while extracting Boost when executing the `cmake
--build deps/build` command. It may happen
in sandboxed environment, such as a docker container. It can look
similar to this:
```
CMake Error: Problem with archive_read_next_header(): Pathname cannot be converted from UTF-8 to current locale.
CMake Error: Problem extracting tar: /workspace/deps/temp_build/downloads/Boost/boost-1.86.0-cmake.zip
-- extracting... [error clean up]
CMake Error at dep_Boost-stamp/extract-dep_Boost.cmake:40 (message):
  Extract of
  '/workspace/deps/temp_build/downloads/Boost/boost-1.86.0-cmake.zip' failed
```

Simply running `cmake` with overridden locale env vars *usually* fixes the issue:
```
LC_ALL=C.UTF-8 cmake --build deps/build
```
