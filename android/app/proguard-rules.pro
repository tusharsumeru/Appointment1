######## ML KIT (BARCODE SCANNING) ########
-keep class com.google.mlkit.** { *; }
-keepclassmembers class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Specific vision + barcode models
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }

######## MOBILE SCANNER PLUGIN ########
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**



######## KEEP ANYTHING USED VIA REFLECTION ########
-keepclassmembers class * {
    public <init>(...);
}

######## NATIVE METHODS ########
-keepclasseswithmembernames class * {
    native <methods>;
}

######## KOTLIN METADATA ########
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

######## DEBUG SYMBOLS ########
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

######## IGNORE PLAY CORE WARNINGS ########
-dontwarn com.google.android.play.core.**
