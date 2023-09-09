//
//  ViewController.swift
//  WhatFlower
//
//  Created by Krish Murjani on 2/16/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera") , style: .plain, target: self, action: #selector(cameraTapped))
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[.editedImage] as? UIImage {
//            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(flower: ciimage)
        }
        imagePicker.dismiss(animated: true)
    }
    
    func detect(flower: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Failed to load CoreML Model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let result = request.results?.first as? VNClassificationObservation {
                let flowerName = result.identifier.capitalized
                self.navigationItem.title = flowerName
                print(flowerName)
                
                self.requestInfo(flowerName: result.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: flower)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String : String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if case .success(let value) = response.result {
                print("Got the wiki info")
//                print(value)
                
                let flowerJSON:JSON = JSON(value)
                
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                
                let flowerImageURL = URL(string: (flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue))
                
                self.imageView.sd_setImage(with: flowerImageURL)
                

                
                self.label.text = flowerDescription
                
            }
        }
        
    }
    
    @objc func cameraTapped() {
        present(imagePicker, animated: true)
    }
}


