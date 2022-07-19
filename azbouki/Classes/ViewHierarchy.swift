//
//  ViewHierarchy.swift
//
//  Created by Dermendzhiev, Teodor on 21.03.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

public struct ViewImageRef {
    let name: String
    let url: URL
    
    func data() -> Data? {
        return try? Data(contentsOf: url)
    }
}

public struct ViewFrame: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    enum CodingKeys: String, CodingKey {
        case x
        case y
        case width
        case height
    }
    
    init(frame: CGRect) {
        x = frame.origin.x
        y = frame.origin.y
        width = frame.width
        height = frame.height
    }
}

public struct ViewNode: Codable {
    var className: String
    var fileName: String
    var subviews: [ViewNode]
    var frame: ViewFrame?
    var imageRef: ViewImageRef?
    var constraints: [String]
    
    enum CodingKeys: String, CodingKey {
        case className
        case fileName
        case subviews
        case frame
        case constraints
    }
}

public struct ViewTree: Codable {
    var rootView: ViewNode
    
    enum CodingKeys: String, CodingKey {
        case rootView
    }
    
    func asJsonString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}


extension UIView {
    public func saveAsImage()-> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            return UIImage.init(cgImage: cgImage)
        }
        return nil
    }
    
    public func snapshotMe() -> UIView? {
        _ = self.subviews.compactMap { $0.isHidden = true }
        var overlay: UIView?
        //TODO: for better performance we can just draw a black view in saveAsImage()
        if self.isPrivate {
            overlay = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
            overlay!.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
            self.addSubview(overlay!)
        }
     
        defer {

            _ = self.subviews.compactMap { $0.isHidden = false }
            overlay?.removeFromSuperview()
        }

        return self.snapshotView(afterScreenUpdates: true) //.snapshotView wont work on real device - https://developer.apple.com/forums/thread/108278
    }
}


extension UIView {
    private static var _isPrivate = [String:Bool]()
    
    var isPrivate:Bool {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIView._isPrivate[tmpAddress] ?? false
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIView._isPrivate[tmpAddress] = newValue
        }
    }
}

//alternative extension - https://stackoverflow.com/questions/29060767/snapshotview-of-uiview-render-draw-in-context-with-nothing
extension UIView {

   public func snapshot(scale: CGFloat = 0, isOpaque: Bool = false, afterScreenUpdates: Bool = true) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, scale)
      drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return image
   }


   public enum CASnapshotLayer: Int {
      case `default`, presentation, model
   }

   /// The method drawViewHierarchyInRect:afterScreenUpdates: performs its operations on the GPU as much as possible
   /// In comparison, the method renderInContext: performs its operations inside of your app’s address space and does
   /// not use the GPU based process for performing the work.
   /// https://stackoverflow.com/a/25704861/1418981
   public func caSnapshot(scale: CGFloat = 0, isOpaque: Bool = false,
                          layer layerToUse: CASnapshotLayer = .default) -> UIImage? {
       
       _ = self.subviews.compactMap { $0.isHidden = true }
    
       defer {

           _ = self.subviews.compactMap { $0.isHidden = false }
       }
       
      var isSuccess = false
      UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, scale)
      if let context = UIGraphicsGetCurrentContext() {
         isSuccess = true
         switch layerToUse {
         case .default:
            layer.render(in: context)
         case .model:
            layer.model().render(in: context)
         case .presentation:
            layer.presentation()?.render(in: context)
         }
      }
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return isSuccess ? image : nil
   }
}


public class ViewHierarchy {
    
    static var imagesCount = 0;
    
    public static func iterateSubviews(view: UIView, images: inout [ViewImageRef]) -> ViewNode? {
//        guard let img = view.snapshotMe()?.saveAsImage() else { return nil }
//        guard let img = view.snapshotMe()?.snapshot() else { return nil }
        guard let img = view.caSnapshot() else { return nil }
        guard let imgRef = ViewHierarchy.saveImage(image: img, name: "\(ViewHierarchy.imagesCount + 1)") else {
            return nil
        }
        images.append(imgRef)
        imagesCount += 1;
        var subviews = [ViewNode]()
        for v in view.subviews {
            if let sub = ViewHierarchy.iterateSubviews(view: v, images: &images) {
                subviews.append(sub)
            }
            
        }
        
        let node = ViewNode(className: String(describing: view.self), fileName: imgRef.name, subviews: subviews, frame: ViewFrame(frame: view.frame), imageRef: imgRef, constraints: view.constraints.map{$0.description})
        return node
    }
    
    static func saveImage(image: UIImage, name: String) -> ViewImageRef? {
        guard let data = UIImagePNGRepresentation(image) else {
            return nil
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        do {
            let url = directory.appendingPathComponent("\(name).png")!
            print(url.absoluteString)
            try data.write(to: url)
            return ViewImageRef(name: "\(name).png", url: url)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func imageFromLayer(layer:CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
    
    func ub_imageForView(view: UIView) -> UIImage {
       let bounds = view.bounds;
        let collection = UITraitCollection(displayGamut: UIDisplayGamut.P3)
        let format = UIGraphicsImageRendererFormat(for: collection)
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        return renderer.image { rendererContext in
            view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }

}
