# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }

# Keep Google Play Services 
-keep class com.google.android.gms.** { *; }

# Keep AndroidX
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Fix serialization issues
-keepattributes Signature
-keepattributes *Annotation*
