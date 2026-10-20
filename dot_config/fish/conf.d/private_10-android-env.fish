# Android development environment (user-owned SDK, replaces /opt/android-sdk).
# Fish port of ~/.config/zsh/android-env.zsh.

set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx ANDROID_SDK_ROOT $ANDROID_HOME

# Android Gradle Plugin builds use a stable JDK (Fedora has no 21): system JDK 25
# if installed, otherwise Android Studio's bundled JBR. System default java stays as is
if test -x /usr/lib/jvm/java-25-openjdk/bin/javac
    set -gx JAVA_HOME /usr/lib/jvm/java-25-openjdk
else
    set -gx JAVA_HOME /usr/libexec/android-studio/jbr
end

# cmdline-tools and emulator first; platform-tools last so /usr/bin/adb stays primary.
# Newest installed build-tools (zipalign, apksigner, aapt2); sorts by name, highest first
set -l __build_tools
for __d in $ANDROID_HOME/build-tools/*/
    test -d $__d; and set -a __build_tools $__d
end
if test (count $__build_tools) -gt 0
    set __build_tools (path sort --reverse $__build_tools)[1]
    fish_add_path -g $__build_tools
end

fish_add_path -g $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/emulator
# platform-tools goes last so /usr/bin/adb stays primary. fish_add_path cannot
# truly append to PATH (its --append only affects fish_user_paths), so set it
# explicitly.
set -gx PATH $PATH $ANDROID_HOME/platform-tools
