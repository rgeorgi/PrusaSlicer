# Building PrusaSlicer on macOS

This guide builds a native Apple Silicon Release build on macOS Tahoe with
AppleClang from Xcode. It keeps the project's dependency bundle separate from
Homebrew headers and libraries, which prevents version mismatches.

## Prerequisites

Install Xcode and its command-line tools, then install the build tools:

```sh
xcode-select --install
brew install automake cmake gettext git libomp libtool ninja texinfo
```

Use AppleClang for this build. If a shell profile sets `CC` or `CXX` to a
Homebrew LLVM compiler, unset those variables for the configure commands.

## Build dependencies

From the repository root:

```sh
env -u CC -u CXX -u CPPFLAGS -u CFLAGS -u CXXFLAGS \
  cmake -S deps -B deps/build-macos-tahoe -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
    -DCMAKE_C_COMPILER=/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++

cmake --build deps/build-macos-tahoe --parallel 1
```

The top-level dependency build is intentionally single-threaded. Its external
projects select their own parallelism.

## Build PrusaSlicer

Configure the application against only the dependency prefix built above. Do
not add `/opt/homebrew` to `CMAKE_PREFIX_PATH`: doing so can mix Homebrew
headers with the bundled Boost and fmt libraries.

```sh
DEPS_PREFIX="$PWD/deps/build-macos-tahoe/destdir/usr/local"

cmake -S . -B build-macos-tahoe -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
  -DCMAKE_PREFIX_PATH="$DEPS_PREFIX" \
  -DBoost_DIR="$DEPS_PREFIX/lib/cmake/Boost-1.86.0" \
  -Dfmt_DIR="$DEPS_PREFIX/lib/cmake/fmt" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/opt/homebrew/opt/libomp/lib"

cmake --build build-macos-tahoe --parallel "$(sysctl -n hw.ncpu)"
```

## Create a local `.app` bundle

The build produces a launcher executable and an `Info.plist`, but does not
assemble them into a macOS application bundle. After building, create a local
bundle with the executable and application resources:

```sh
APP_BUNDLE="$PWD/build-macos-tahoe/dist/PrusaSlicer.app"

cmake --build build-macos-tahoe --target slic3r-app-launcher \
  --parallel "$(sysctl -n hw.ncpu)"

mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp build-macos-tahoe/src/slic3r-app-launcher/slic3r-app-launcher \
  "$APP_BUNDLE/Contents/MacOS/PrusaSlicer"
cp build-macos-tahoe/src/Info.plist "$APP_BUNDLE/Contents/Info.plist"
ditto resources "$APP_BUNDLE/Contents/Resources"
```

This is a development bundle, not a self-contained release package; it still
depends on the libraries used when linking the build. To open it:

```sh
open "$APP_BUNDLE"
```

## Run the build

```sh
build-macos-tahoe/src/slic3r-app-launcher/slic3r-app-launcher
```

For a Tahoe-native build, use a deployment target of `26.0`. Xcode 27 no
longer supports targeting macOS 10.15 with its libc++ headers.
