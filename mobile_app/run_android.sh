#!/usr/bin/env sh
# Use Java 17 or 21 for the Android build (Gradle/Kotlin don't support Java 25 yet).
if command -v /usr/libexec/java_home >/dev/null 2>&1; then
  JAVA_17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)
  JAVA_21_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null)
  if [ -n "$JAVA_17_HOME" ]; then
    export JAVA_HOME="$JAVA_17_HOME"
  elif [ -n "$JAVA_21_HOME" ]; then
    export JAVA_HOME="$JAVA_21_HOME"
  fi
fi
exec flutter run "$@"
