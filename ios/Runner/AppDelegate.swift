import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 🔥 CRITICAL: Set notification delegate for foreground presentation
    UNUserNotificationCenter.current().delegate = self
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🔥 CRITICAL: Allow banner presentation when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      // ✅ iOS 14+: Allow banner, badge, and sound in foreground
      completionHandler([.banner, .badge, .sound])
    } else {
      // ✅ iOS 13: Allow alert, badge, and sound in foreground
      completionHandler([.alert, .badge, .sound])
    }
  }
}
