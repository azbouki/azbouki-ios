//
//  DBConnection.swift
//
//  Created by Teodor Dermendzhiev on 10.02.21.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift


class DBConnection {
    var storageRef: StorageReference!
    var firestoreDB: Firestore!
    
    var sessionID: String!
    
    init(sessionID: String) {
        guard let app = FirebaseApp.app(name: "SupportTool")
          else {
              assert(false, "Could not retrieve app")
              return
          }
        
        self.sessionID = sessionID
        storageRef = Storage.storage(app: app).reference().child("teams").child(AzboukiClientConfig.instance.teamId).child("applications").child(AzboukiClientConfig.instance.appId).child("sessions").child(sessionID)
        firestoreDB = Firestore.firestore(app: app)
    }
    
    func uploadSession(logFileURL: String?, videoURL: String?) {
        
        guard let session = Session.current else {
            print("No session initialized")
            return
        }
        
        session.videoUrl = videoURL
        session.logUrl = logFileURL

        try? firestoreDB.collection("teams").document(AzboukiClientConfig.instance.teamId).collection("applications").document(AzboukiClientConfig.instance.appId).collection("sessions").document(session.id).setData(from: session)
    }
    
    func uploadViewTree(tree: ViewTree, message: String) -> DocumentReference? {
        
        //TODO: use codable class
        
        return firestoreDB.collection("teams").document(AzboukiClientConfig.instance.teamId).collection("applications").document(AzboukiClientConfig.instance.appId).collection("screenshots").addDocument(data: ["createdAt": Date().timeIntervalSince1970*1000, "tree": tree.asJsonString(), "message": message, "userId": AzboukiClientConfig.instance.userId!, "deviceModel": UIDevice.current.model, "os": UIDevice.current.systemName, "osVersion": UIDevice.current.systemVersion, "batteryLevel": UIDevice.current.batteryLevel, "isDeleted": false, "reportType": "3D", "appId": AzboukiClientConfig.instance.appId], completion: { error in
            print(error as Any)
        })
        
    }
    
    func upload(ref: StorageReference, data: Data, completion: @escaping (String?) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = "video"
        ref.putData(data, metadata: metadata) { (metadata, error) in
//            let size = metadata!.size
          ref.downloadURL { (url, error) in
            completion(url?.absoluteString)
          }
        }
    }
    
    func uploadFile(ref: StorageReference, url: URL, completion: @escaping (String?) -> Void) {
        ref.putFile(from: url, metadata: nil) { metadata, error in

          ref.downloadURL { (url, error) in
            completion(url?.absoluteString)
          }
        }
    }
    func uploadScreenshot(data: Data, completion: @escaping (String?) -> Void) {
        let imageRef = storageRef.child("shots/\(UUID().uuidString).jpg")
        upload(ref: imageRef, data: data) { (url) in
            completion(url)
        }
    }
    
    func uploadHierarchyImage(name: String, screenshotId: String, data: Data, completion: @escaping (String?) -> Void) {
        let imageRef = storageRef.child("screenshots/\(screenshotId)/\(name)")
        upload(ref: imageRef, data: data) { (url) in
            completion(url)
        }
    }
    
    func uploadLogs(data: Data, completion: @escaping (String?) -> Void) {
        guard let sessionID = sessionID else { return }
        let logRef = storageRef.child("logs/\(sessionID).txt")
        upload(ref: logRef, data: data) { (url) in
            completion(url)
        }
    }
    
    func uploadVideo(data: Data, videoPath: String, completion: @escaping (String?) -> Void) {
        let videoRef = storageRef.child("videos/\(videoPath)")
        upload(ref: videoRef, data: data) { (url) in
            completion(url)
        }
    }
    
    func uploadVideoFile(url: URL, videoPath: String, completion: @escaping (String?) -> Void) {
        let videoRef = storageRef.child("videos/\(videoPath)")
        uploadFile(ref: videoRef, url: url) { url in
            completion(url)
        }
    }
    
    class func getNewSessionId() -> String {
        guard let app = FirebaseApp.app(name: "SupportTool")
          else {
              assert(false, "Could not retrieve app")
              return ""
          }
        let refer = Firestore.firestore(app: app).collection("teams").document(AzboukiClientConfig.instance.teamId).collection("applications").document(AzboukiClientConfig.instance.appId).collection("sessions").document()
        return refer.documentID
    }

}
