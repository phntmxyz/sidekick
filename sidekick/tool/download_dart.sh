# Downloads the dart sdk

# Highly inspired by https://github.com/flutter/flutter/blob/bde9f11831f60ef35ab15d69bc37fb47e04b0ee1/bin/internal/update_dart_sdk.sh


set -e

SIDEKICK_PACKAGE_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

DART_SDK_PATH="$SIDEKICK_PACKAGE_ROOT/build/cache/dart-sdk"
DART_SDK_PATH_OLD="$DART_SDK_PATH.old"
DART_VERSION="2.14.4"
DART_VERSION_STAMP="$SIDEKICK_PACKAGE_ROOT/build/cache/dartsdk.stamp"

if [ ! -f "$DART_VERSION_STAMP" ] || [ "$DART_VERSION" != `cat "$DART_VERSION_STAMP"` ]; then
  command -v curl > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "curl" tool. Unable to download Dart SDK.'
    case "$(uname -s)" in
      Darwin)
        >&2 echo 'Consider running "brew install curl".'
        ;;
      Linux)
        >&2 echo 'Consider running "sudo apt-get install curl".'
        ;;
      *)
        >&2 echo "Please install curl."
        ;;
    esac
    echo
    exit 1
  }
  command -v unzip > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "unzip" tool. Unable to extract Dart SDK.'
    case "$(uname -s)" in
      Darwin)
        echo 'Consider running "brew install unzip".'
        ;;
      Linux)
        echo 'Consider running "sudo apt-get install unzip".'
        ;;
      *)
        echo "Please install unzip."
        ;;
    esac
    echo
    exit 1
  }
  >&2 echo "Downloading Dart SDK from Flutter engine $ENGINE_VERSION..."

  # On x64 stdout is "uname -m: x86_64"
  # On arm64 stdout is "uname -m: aarch64, arm64_v8a"
  case "$(uname -m)" in
    x86_64)
      ARCH="x64"
      ;;
    *)
      ARCH="arm64"
      ;;
  esac

  case "$(uname -s)" in
    Darwin)
      DART_ZIP_NAME="dartsdk-macos-${ARCH}-release.zip"
      IS_USER_EXECUTABLE="-perm +100"
      ;;
    Linux)
      DART_ZIP_NAME="dartsdk-linux-${ARCH}-release.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    MINGW*)
      DART_ZIP_NAME="dartsdk-windows-${ARCH}-release.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  # Use the default find if possible.
  if [ -e /usr/bin/find ]; then
    FIND=/usr/bin/find
  else
    FIND=find
  fi

 DART_SDK_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/$DART_ZIP_NAME"

  # if the sdk path exists, copy it to a temporary location
  if [ -d "$DART_SDK_PATH" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
    mv "$DART_SDK_PATH" "$DART_SDK_PATH_OLD"
  fi

  # install the new sdk
  rm -rf -- "$DART_SDK_PATH"
  mkdir -m 755 -p -- "$DART_SDK_PATH"
  DART_SDK_ZIP="$SIDEKICK_PACKAGE_ROOT/build/cache/$DART_ZIP_NAME"

  # Conditionally set verbose flag for LUCI
  verbose_curl=""
  if [[ -n "$LUCI_CI" ]]; then
    verbose_curl="--verbose"
  fi

  curl ${verbose_curl} --retry 3 --continue-at - --location --output "$DART_SDK_ZIP" "$DART_SDK_URL" 2>&1 || {
    >&2 echo
    >&2 echo "Failed to retrieve the Dart SDK from: $DART_SDK_URL"
    >&2 echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  unzip -o -q "$DART_SDK_ZIP" -d "$SIDEKICK_PACKAGE_ROOT/build/cache/" || {
    >&2 echo
    >&2 echo "It appears that the downloaded file is corrupt; please try again."
    >&2 echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  rm -f -- "$DART_SDK_ZIP"
  $FIND "$DART_SDK_PATH" -type d -exec chmod 755 {} \;
  $FIND "$DART_SDK_PATH" -type f ${IS_USER_EXECUTABLE} -exec chmod a+x,a+r {} \;
  echo "$DART_VERSION" > "$DART_VERSION_STAMP"

  # delete any temporary sdk path
  if [ -d "$DART_SDK_PATH_OLD" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
  fi
fi
