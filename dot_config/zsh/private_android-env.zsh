# Android development environment (user-owned SDK, replaces /opt/android-sdk)
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Android Gradle Plugin builds use a stable JDK (Fedora has no 21): system JDK 25
# if installed, otherwise Android Studio's bundled JBR. System default java stays as is
if [[ -x /usr/lib/jvm/java-25-openjdk/bin/javac ]]; then
  export JAVA_HOME="/usr/lib/jvm/java-25-openjdk"
else
  export JAVA_HOME="/usr/libexec/android-studio/jbr"
fi

# cmdline-tools and emulator first; platform-tools last so /usr/bin/adb stays primary
# Newest installed build-tools (zipalign, apksigner, aapt2); sorts by name, highest first
android_build_tools=("$ANDROID_HOME"/build-tools/*(N/On[1]))

path=("$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/emulator" $android_build_tools $path "$ANDROID_HOME/platform-tools")
unset android_build_tools
