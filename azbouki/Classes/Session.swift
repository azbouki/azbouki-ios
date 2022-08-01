//
//  Session.swift
//
//  Created by Dermendzhiev, Teodor on 18.01.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class Session: Codable {
    
    static var current: Session?
    
    enum CodingKeys: String, CodingKey {
        case videoUrl
        case logUrl
        case createdAt
        case videoStartTime
        case videoEndTime
        case videoPath
        case isDeleted
        case os
        case osVersion
        case deviceModel
        case batteryLevel
        case appId
        case sentryEvent
        case userId
        case reportType
        case message
    }
    
    var videoUrl: String?
    var logUrl: String?
    let createdAt: Int?
    var videoStartTime: Int?
    var videoEndTime: Int?
    var videoPath: String?
    var logPath: String?
    let isDeleted = false
    let os: String
    let osVersion: String
    let deviceModel: String
    let batteryLevel: Float
    let appId: String
    var sentryEvent: String?
    var userId: String?
    var message: String?
    let reportType = "video"
    
    init() {
        self.createdAt = Int(Date().timeIntervalSince1970*1000)
        self.deviceModel = UIDevice.current.model
        self.os = UIDevice.current.systemName
        self.osVersion = UIDevice.current.systemVersion
        self.batteryLevel = UIDevice.current.batteryLevel
        self.appId = AzboukiClientConfig.instance.appId
        self.userId = AzboukiClientConfig.instance.userId
    }
    
    static func start() {
        if let curr = Session.current {
            print("Session is already running")
            return
        }
        
        Session.current = Session()
        Session.current?.videoPath = "session-\(Date().timeIntervalSince1970 * 1000000).mp4"
        Session.current?.logPath = "session-\(Date().timeIntervalSince1970 * 1000000).txt"
    }
    
    static func stop() {
        Session.current = nil
    }
    
    static func setVideoStartTimeNow() {
        Session.current?.videoStartTime = Int(Date().timeIntervalSince1970*1000)
    }
    
    static func setVideoEndTimeNow() {
        Session.current?.videoEndTime = Int(Date().timeIntervalSince1970*1000)
    }
    
    static func getVideoPath() -> String? {
        return Session.current?.videoPath
    }
    
    static func getLogPath() -> String? {
        return Session.current?.logPath
    }
    
}
