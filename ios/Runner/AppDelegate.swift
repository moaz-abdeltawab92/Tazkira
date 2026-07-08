import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupWidgetChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Widget Platform Channel

  /// Registers the method channel handler for widget data communication.
  /// Channel name must match WidgetDataService._channel in Dart.
  private func setupWidgetChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.moaz.tazkira/widget_channel",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {

      case "writeWidgetData":
        self?.handleWriteWidgetData(call: call, result: result)

      case "reloadWidgets":
        self?.handleReloadWidgets(result: result)

      case "isWidgetInstalled":
        // WidgetKit does not expose an install-check API.
        // Return true as a best-effort response.
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Channel Handlers

  /// Writes the prayer data snapshot JSON to the shared App Group UserDefaults
  /// so the widget extension can read it.
  ///
  /// App Group identifier: group.com.moaz.tazkira
  /// UserDefaults key: tazkira_widget_data
  private func handleWriteWidgetData(call: FlutterMethodCall, result: FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(
        code: "INVALID_ARGS",
        message: "writeWidgetData expects a Map argument",
        details: nil
      ))
      return
    }

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
        result(FlutterError(
          code: "ENCODE_ERROR",
          message: "Failed to encode snapshot as UTF-8 string",
          details: nil
        ))
        return
      }

      let defaults = UserDefaults(suiteName: "group.com.moaz.tazkira")
      defaults?.set(jsonString, forKey: "tazkira_widget_data")
      // Note: synchronize() is intentionally omitted — it has been a no-op
      // since iOS 12 and the system persists App Group UserDefaults automatically.

      result(true)
    } catch {
      result(FlutterError(
        code: "WRITE_ERROR",
        message: "Failed to write widget data: \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  /// Requests WidgetKit to reload all widget timelines so the extension
  /// picks up the newly written snapshot immediately.
  private func handleReloadWidgets(result: FlutterResult) {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    result(nil)
  }
}
