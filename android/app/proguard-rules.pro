# Keep ML Kit text recognizers (ALL languages)
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Keep internal ML Kit text classes
-keep class com.google.android.gms.internal.vision.** { *; }
-dontwarn com.google.android.gms.internal.vision.**
# Keep TFLite GPU delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
# Needed for Flutter plugins using reflection
-keep class io.flutter.plugins.** { *; }
