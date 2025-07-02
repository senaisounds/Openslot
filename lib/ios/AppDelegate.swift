import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "app.openslot/deep_links"
    private var initialLink: String?
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up the Flutter method channel
        let controller = window?.rootViewController as! FlutterViewController
        methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            if call.method == "getInitialLink" {
                result(self.initialLink)
                // Clear after it's been delivered
                self.initialLink = nil
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Check if this is a Universal Link
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            let urlString = url.absoluteString
            
            // If app is not launched yet, save the link for later retrieval
            if methodChannel == nil {
                initialLink = urlString
            } else {
                // App is already running, forward the link
                methodChannel?.invokeMethod("handleDeepLink", arguments: urlString)
            }
            return true
        }
        return false
    }
    
    // Handle custom URL schemes (openslot://event/123)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let urlString = url.absoluteString
        
        // If app is not launched yet, save the link for later retrieval
        if methodChannel == nil {
            initialLink = urlString
        } else {
            // App is already running, forward the link
            methodChannel?.invokeMethod("handleDeepLink", arguments: urlString)
        }
        return true
    }
} 