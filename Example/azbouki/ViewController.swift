//
//  ViewController.swift
//  AzboukiClient
//
//  Created by tdermendjiev on 04/29/2022.
//  Copyright (c) 2022 tdermendjiev. All rights reserved.
//

import UIKit
import azbouki

class ViewController: UIViewController {
    
    @IBOutlet weak var screenshotButton: UIButton!
    @IBOutlet weak var toggleRecordingButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func start(_ sender: UIButton) {
        if AzboukiClient.isRecording() {
            AzboukiClient.stopVideoSession()
            sender.setTitle("start recording", for: .normal)
        } else {
            openMessageAlert()
        }
    }
    
    func openMessageAlert() {
        let alert = UIAlertController(title: "Start recording", message: "Add a description", preferredStyle: .alert)
  
        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            AzboukiClient.startVideoSession(message: textField?.text) { err in
                if let err = err {
                    print("Error starting session: \(err.localizedDescription)")
                    return
                }
                if (AzboukiClient.isRecording()) {
                    self.toggleRecordingButton.setTitle("stop recording", for: .normal)
                } else {
                    print("Error starting session")
                }
                
            }
            
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func screenshot(_ sender: Any) {
       openScreenshotMessageAlert()
    }
    
    func openScreenshotMessageAlert() {
        let alert = UIAlertController(title: "Send screenshot", message: "Add a description", preferredStyle: .alert)
  
        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            AzboukiClient.takeScreenshot(view: self.view, message: textField?.text ?? "")
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logButtonPressed(_ sender: Any) {
        print("Log button pressed")
    }
}

