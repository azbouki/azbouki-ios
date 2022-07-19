//
//  AzboukiClient.swift
//  AzboukiClient
//
//  Created by Dermendzhiev, Teodor on 29.04.22.
//

import UIKit
import FirebaseCore
import Sentry
import ReplayKit

public class AzboukiClient {
    
    static let shared = AzboukiClient()
    var currentSessionID = "\(Int(Date().timeIntervalSince1970*1000))"
    var dbConnection: DBConnection?
    var inputPipe: Pipe?
    var outputPipe: Pipe?
    private var isCurrentlyRecording = false;
    var currentSessionPathURL: URL?
    
    var newLogFileURL: URL?
    var newShotsPathURL: URL?
    var sessionsPathURL: URL?
    
    var saved_stdout: Int32?
    
    var pipe = Pipe()
    
    var viewRefs = [UIView]()
    
    var screenRecorder = ScreenRecorder()
    var currentSessionLogPathURL: URL?
    public weak var delegate: RPPreviewViewControllerDelegate?
    
    public static func configure(appId: String, userId: String?) {
        shared.configure(appId: appId, userId: userId, googleAppID: Constants.GOOGLE_APP_ID, gcmSenderID: Constants.GCM_SENDER_ID, apiKey: Constants.FB_API_KEY, projectID: Constants.FB_PROJECT_ID, clientID: Constants.FB_CLIENT_ID, storageBucket: Constants.FB_STORAGE_BUCKET, databaseURL: Constants.DATABASE_URL)
    }
    
    func setScreenshotHandlerEnabled(_ enabled: Bool, message: String) {
        if (enabled) {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                object: nil,
                queue: .main) { notification in
                    if var topController = UIApplication.shared.keyWindow?.rootViewController {
                        while let presentedViewController = topController.presentedViewController {
                            topController = presentedViewController
                        }

                        AzboukiClient.takeScreenshot(view: topController.view, message: message)
                    }
                    
            }
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        }
    }
    
    func configure(appId: String, userId: String?, googleAppID: String, gcmSenderID: String, apiKey: String, projectID: String, clientID: String, storageBucket: String, databaseURL: String) {
        AzboukiClientConfig.instance.appId = appId
        AzboukiClientConfig.instance.userId = userId
    configureFirebase(googleAppID: googleAppID, gcmSenderID: gcmSenderID, apiKey: apiKey, projectID: projectID, clientID: clientID, storageBucket: storageBucket, databaseURL: databaseURL)
        createFoldersAndPaths()
    }
    
    func setUserId(userId: String?) {
        AzboukiClientConfig.instance.userId = userId
    }
    
    func configureFirebase(googleAppID: String, gcmSenderID: String, apiKey: String, projectID: String, clientID: String, storageBucket: String, databaseURL: String) {
        let options = FirebaseOptions(googleAppID: googleAppID,
                                               gcmSenderID: gcmSenderID)
        options.apiKey = apiKey
        options.projectID = projectID
        options.clientID = clientID
        options.storageBucket = storageBucket
        options.databaseURL = databaseURL
        
        FirebaseApp.configure(name: "MRLiveSupport", options: options)
    }

    public class func startVideoSession(message: String?) {
        
        if AzboukiClient.shared.isCurrentlyRecording {
            print("Recording already started")
            return
        }
        AzboukiClient.shared.openConsolePipe()
        AzboukiClient.shared.attachSentry()
        AzboukiClient.shared.currentSessionID = "\(Int(Date().timeIntervalSince1970*1000))"
        AzboukiClient.shared.startRecordSession()
        AzboukiClient.setCurrentSessionMessage(message: message)
    }
    
    public static func setCurrentSessionMessage(message: String?) {
        Session.current?.message = message
    }
    
    public static func isRecording() -> Bool {
        return AzboukiClient.shared.isCurrentlyRecording
    }
    
    public class func hideView(view: UIView) {
        view.isPrivate = true
        AzboukiClient.shared.viewRefs.append(view)
        if (AzboukiClient.isRecording()) {
            //add overlay
        }
    }
    
    public func attachSentry() {
        
        SentrySDK.start { options in
            options.enabled = true
            options.parsedDsn = SentryDsn()
        }
        SentrySDK.startSession()
    }
    
    public func detachSentry() {
        let event = Event(level: .debug)
        SentryManager.prepare(event, with: SentryManager.getSentryHub().scope, alwaysAttachStacktrace: true)
       // print(event.serialize())
        let jsonData = try? JSONSerialization.data(withJSONObject: event.serialize(), options: .prettyPrinted)
        let str = String(decoding: jsonData!, as: UTF8.self)
      
        Session.current?.sentryEvent = str
        

    }
    
    public class func stopVideoSession() {
        if !AzboukiClient.shared.isCurrentlyRecording {
            print("Recording not started")
            return
        }
        AzboukiClient.shared.closeConsolePipe()
        AzboukiClient.shared.detachSentry()
        AzboukiClient.shared.stopRecordSession()
        
        AzboukiClient.shared.unhideViews()
    }
    
    func unhideViews() {
        for v in viewRefs {
            if v != nil {
                //remove overlay
            }
        }
    }
    
    func handleVideoReport() {

        dbConnection = DBConnection(sessionID: currentSessionID)
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            let videoURL = path.appendingPathComponent(Session.getVideoPath()!)

            if let data = try? Data.init(contentsOf: videoURL), let dbConnection = self.dbConnection {
                dbConnection.uploadVideoFile(url: videoURL, videoPath: Session.getVideoPath()!) {[weak self] (url) in
                    print(url)
                    let uploadedVideoURL = url
                    if let logURL = self?.currentSessionLogPathURL,  let logsFile = try? Data.init(contentsOf: logURL) {
                        dbConnection.uploadLogs(data: logsFile) { (url) in
                            self?.currentSessionLogPathURL = nil
                            let uploadedLogsURL = url
                            dbConnection.uploadSession(logFileURL: uploadedLogsURL, videoURL: uploadedVideoURL)
                            Session.stop()
                           
                        }
                    }
                }
            }
            
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }
    }
    
    @objc public func stopRecordSession() {
//        ShowTime.enabled = .never
        
        screenRecorder.stoprecording { err in
            if let error = err {
                print(err)
            } else {
                self.handleVideoReport()
            }
        }
        
    }
    
    public class func takeScreenshot(view: UIView, message: String) {
        AzboukiClient.shared.captureViewHierarchy(view: view, message: message)
    }
    
    func captureViewHierarchy(view: UIView, message: String) {
        var shots = [ViewImageRef]()
        if let rootView = ViewHierarchy.iterateSubviews(view: view, images: &shots) {
            let tree = ViewTree(rootView: rootView)
            let dbConnection = DBConnection(sessionID: "<unnamed>")
            let ref = dbConnection.uploadViewTree(tree: tree, message: message)
            guard let screenshotId = ref?.documentID else {
                print("Screenshot upload failed")
                return
            }
            for shot in shots {
                
                if let data = shot.data() {
                    dbConnection.uploadHierarchyImage(name: shot.name, screenshotId: screenshotId, data: shot.data()!) { url in
                        print("uploaded \(url)")
                    }
                }
                
            }
            
        }
        
    }
    
    @objc public func startRecordSession() {
        Session.start()
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let videoURL = path.appendingPathComponent(Session.getVideoPath()!)

        self.currentSessionLogPathURL = path.appendingPathComponent(Session.getLogPath()!)
        
        if (currentSessionLogPathURL == nil) {
            print("Failed to create logpath url")
            Session.stop()
            return
        }
        
        screenRecorder.startRecording(to: videoURL, size: nil, saveToCameraRoll: false) { err in
            print(err)
        }
        screenRecorder.delegate = self
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
}

extension AzboukiClient: ScreenRecorderDelegate {
    public func recordingDidStart() {
        Session.setVideoStartTimeNow()
        isCurrentlyRecording = true
    }
    
    public func recordingDidEnd() {
        Session.setVideoEndTimeNow()
        isCurrentlyRecording = false
    }
    
    //https://stackoverflow.com/questions/53978091/using-pipe-in-swift-app-to-redirect-stdout-into-a-textview-only-runs-in-simul
    
    
    public func openConsolePipe () {
        
        saved_stdout = dup(STDOUT_FILENO)
        
        setvbuf(stdout, nil, _IONBF, 0)
        
        dup2(pipe.fileHandleForWriting.fileDescriptor,
            STDOUT_FILENO)
        
        dup2(STDOUT_FILENO, pipe.fileHandleForWriting.fileDescriptor)
     
        pipe.fileHandleForReading.readabilityHandler = {
         [weak self] handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "<Non-ascii data of size\(data.count)>\n"
            self?.appendLogToFile(str: str)
            self?.outputPipe?.fileHandleForWriting.write(data)
      }
    }
    
    public func closeConsolePipe() {
        dup2(saved_stdout!, STDOUT_FILENO)
        close(saved_stdout!)
        pipe.fileHandleForReading.readabilityHandler = nil
    }
    
    func appendLogToFile(str: String) {
        if let url = newLogFileURL {
            
            do {
                let line = "\(Int(Date().timeIntervalSince1970*1000)), \(str)"
                try line.appendLineToURL(fileURL: url)
                if let currLog = self.currentSessionLogPathURL {
                    try line.appendLineToURL(fileURL: currLog)
                }
            } catch {
                print("Failed to write")
            }
        }
    }
    
    func createFoldersAndPaths() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        sessionsPathURL = path.appendingPathComponent("sessions")
        
        if !FileManager.default.fileExists(atPath: sessionsPathURL!.path) {
            do {
                try FileManager.default.createDirectory(atPath: sessionsPathURL!.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        currentSessionPathURL = sessionsPathURL!.appendingPathComponent(currentSessionID)
        try? FileManager.default.createDirectory(atPath: currentSessionPathURL!.path, withIntermediateDirectories: true, attributes: nil)
        
        self.newLogFileURL = currentSessionPathURL!.appendingPathComponent("logs.txt")
        
        self.newShotsPathURL = currentSessionPathURL!.appendingPathComponent("screenshots")
        
        
        try? FileManager.default.createDirectory(atPath: newShotsPathURL!.path, withIntermediateDirectories: true, attributes: nil)
    }
}
