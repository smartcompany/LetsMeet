import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private lazy var flutterEngine = FlutterEngine(name: "default")
  private let splashTag = 9_991
  /// #6B4EAA — Launch Screen / Flutter 스플래시와 동일
  private let splashColor = UIColor(
    red: 107.0 / 255.0,
    green: 78.0 / 255.0,
    blue: 170.0 / 255.0,
    alpha: 1.0
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    if window == nil {
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.backgroundColor = splashColor

      let flutterVC = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
      flutterVC.view.backgroundColor = splashColor
      // Dart 첫 프레임 전까지 Launch Screen이 사라진 자리를 스플래시로 유지
      attachSplashOverlay(to: flutterVC.view)

      window?.rootViewController = flutterVC
      window?.makeKeyAndVisible()

      // Flutter에서 홈 appear 시 네이티브 오버레이 제거
      let channel = FlutterMethodChannel(
        name: "letsmeet/splash",
        binaryMessenger: flutterVC.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "remove" {
          self?.removeSplashOverlay()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func attachSplashOverlay(to view: UIView) {
    let overlay = UIView(frame: view.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.backgroundColor = splashColor
    overlay.tag = splashTag

    let imageView = UIImageView(frame: overlay.bounds)
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.contentMode = .scaleAspectFill
    // flutter_native_splash가 Assets에 넣는 LaunchImage
    imageView.image = UIImage(named: "LaunchImage")
    overlay.addSubview(imageView)

    view.addSubview(overlay)
  }

  private func removeSplashOverlay() {
    guard let root = window?.rootViewController?.view else { return }
    root.viewWithTag(splashTag)?.removeFromSuperview()
  }
}
