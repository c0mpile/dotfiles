# Android development environment (user-owned SDK, replaces /opt/android-sdk)
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Android Gradle Plugin builds run on JDK 21; system default java stays as is
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"

# cmdline-tools and emulator first; platform-tools last so /usr/bin/adb stays primary
path=("$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/emulator" $path "$ANDROID_HOME/platform-tools")
