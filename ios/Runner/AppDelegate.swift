import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter passes base64 Dart defines to the native build; no server key here.
    let defines = (Bundle.main.object(forInfoDictionaryKey: "PindDartDefines") as? String ?? "")
      .split(separator: ",")
      .compactMap { Data(base64Encoded: String($0)) }
      .compactMap { String(data: $0, encoding: .utf8) }
    if let entry = defines.first(where: { $0.hasPrefix("GOOGLE_MAPS_API_KEY=") }) {
      let key = String(entry.dropFirst("GOOGLE_MAPS_API_KEY=".count))
      if !key.isEmpty { GMSServices.provideAPIKey(key) }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
