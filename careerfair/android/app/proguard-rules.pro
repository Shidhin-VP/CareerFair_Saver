# Prevent R8 from removing image I/O related classes
-keep class javax.imageio.** { *; }
-keep class com.github.jaiimageio.** { *; }
-keep class com.sun.imageio.** { *; }

-dontwarn javax.imageio.**
-dontwarn com.github.jaiimageio.**
-dontwarn com.sun.imageio.**
