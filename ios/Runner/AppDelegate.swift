import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required to make any communication available in the action isolate.
    GeneratedPluginRegistrant.register(with: self)

    if window == nil {
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0) // #F5F7FA
      window?.rootViewController = FlutterViewController()
      window?.makeKeyAndVisible()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
