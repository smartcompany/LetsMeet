import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private lazy var flutterEngine = FlutterEngine(name: "default")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    if window == nil {
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0) // #F5F7FA
      window?.rootViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
      window?.makeKeyAndVisible()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
