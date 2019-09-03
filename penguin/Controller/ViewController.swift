//
//  ViewController.swift
//  seefood
//
//  Created by Katy Garner on 01/09/2019.
//  Copyright © 2019 Geek Girl Solutions. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SVProgressHUD

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    var confidentResults : [VNClassificationObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:
        [UIImagePickerController.InfoKey : Any]) {

        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Cound not convert to CIImage")
            }
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: {})

    }

    //MARK: detect Image
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model, completionHandler: {(request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")}
            
            print(results)
            
            self.confidentResults =
                results.filter({(aResult) -> Bool in
                    return aResult.confidence > 0.05
                })
            
            let isPenguin =
                self.confidentResults.filter({(aResult) -> Bool in
                    return aResult.identifier.contains("penguin")
                }).count > 0
        
            if isPenguin {
                self.navigationItem.title = "Penguin!"
            } else {
                self.navigationItem.title = "Not Penguin!"
            }
        })
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    
    @IBAction func infoTapped(_ sender: UIBarButtonItem) {
        var displayMessage: String = ""
        confidentResults.forEach { (result) in
            if displayMessage != "" {
                displayMessage.append("\n")
            }
            let confidence = String(format: "%.2f", result.confidence * 100)
            let identified = result.identifier
            displayMessage.append("Confident: \(confidence)% of \(identified)")
        }
        
        if displayMessage == "" {
            displayMessage = "We have no clue what the image is.  Are you sure you've selected one?"
        }
        
        let alert = UIAlertController(title: "Classified As?",
                                      message: displayMessage,
                                      preferredStyle:.alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Camera Actions
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func openGallery()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

