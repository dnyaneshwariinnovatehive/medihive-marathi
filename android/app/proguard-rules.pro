-keep class com.innovatehive.medihive.** { *; }

# Hive - keeps adapters and model classes used via reflection
-keep class * extends com.hive.common.binary.Adapter { *; }
-keep class * extends com.hive.common.binary.Binary { *; }
-keep class * extends com.hive.common.binary.Reader { *; }
-keep class * extends com.hive.common.binary.Writer { *; }
-keep class * extends hive.common.binary.Adapter { *; }
-keep class * extends hive.common.binary.Binary { *; }
-keep class * extends hive.common.binary.Reader { *; }
-keep class * extends hive.common.binary.Writer { *; }
-keep class * extends com.hive.common.Binary { *; }
-keep class * implements com.hive.common.binary.Adapter { *; }

# Flutter's Hive
-dontwarn com.hive.**
-dontwarn hive.**

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# flutter_secure_storage
-keep class com.wisecrypto.fluttersecurestorage.** { *; }
-dontwarn com.wisecrypto.fluttersecurestorage.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Workmanager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-dontwarn androidx.work.**

# Keep all model classes used with Hive
-keep class com.innovatehive.medihive.models.** { *; }

# Keep all Kotlin classes that might be accessed via reflection
-keep class kotlin.Metadata { *; }
