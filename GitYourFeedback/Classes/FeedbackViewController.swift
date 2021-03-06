//
//  FeedbackViewController.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/11/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

class FeedbackInterfaceViewController: UIViewController {
    
    var reporter: FeedbackManager?
    
    internal init(reporter: FeedbackManager?) {
        super.init(nibName: nil, bundle: nil)
        
        self.reporter = reporter
    }
    
    fileprivate var image: UIImage? {
        didSet {
            imagePreviewButton.setImage(image, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        
        stack.addArrangedSubview(emailField)
        stack.addArrangedSubview(titleField)
        stack.addArrangedSubview(bodyField)
        stack.addArrangedSubview(footerLabel)
        
        view.addSubview(imagePreviewButton)
        setupConstraints()
        
        // Navbar
        let bundle = Bundle(for: type(of: self))
        let saveImage = UIImage(named: "save.png", in: bundle, compatibleWith: nil)
        let saveButton = UIBarButtonItem(image: saveImage, style: .plain, target: self, action: #selector(save))
        saveButton.tintColor = UIColor.black
        navigationItem.rightBarButtonItem = saveButton

        let closeImage = UIImage(named: "close.png", in: bundle, compatibleWith: nil)
        let closeButton = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(close))
        closeButton.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = closeButton
        
        title = "Submit Feedback"
        
        handleScreenshot()
		
        populateEmailField()
        imagePreviewButton.addTarget(self, action: #selector(selectNewImage), for: .touchUpInside)
    }
    
    private func handleScreenshot() {
        if !MediaQuery.hasPhotosAccess() {
            MediaQuery.requestPhotosAccess(completionHandler: { (status) in
                if !MediaQuery.hasPhotosAccess() {
                    // Throw error
                    self.showNotification(title: "Photo Access", message: "Access must be granted to the photo library in order to import the screenshot")
                } else {
                    self.handleScreenshot()
                }
            })
            return
        }
        
        MediaQuery.fetchLastImage { (image) in
            OperationQueue.main.addOperation({ 
                if let image = image {
                    self.image = image
                }
            })
        }
    }
    
    func selectNewImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func showNotification(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(vc, animated: true, completion: nil)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        vc.addAction(ok)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: stack.frame.size.height)
        
        let buttonFrame = view.convert(imagePreviewButton.frame, to: bodyField).insetBy(dx: -10, dy: -10)
        let exclusionPath = UIBezierPath(rect: buttonFrame)
        bodyField.textContainer.exclusionPaths = [exclusionPath]
    }
    
    private func setupConstraints() {
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        stack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20).isActive = true
        stack.leftAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.rightAnchor).isActive = true
        
        imagePreviewButton.trailingAnchor.constraint(equalTo: bodyField.trailingAnchor, constant: -8).isActive = true
        imagePreviewButton.bottomAnchor.constraint(equalTo: bodyField.bottomAnchor, constant: -8).isActive = true
    }
    
    func save() {
        var imageData: Data?
        if let image = image {
            imageData = UIImageJPEGRepresentation(image, 20)
        }
        
        var titleText = "Feedback"
        if let text = titleField.text {
            titleText = "Feedback: \(text)"
        }
        
        var bodyText = "No description"
        if let email = emailField.text {
            bodyText = "From: \(email)"
        }
        
        if let bodyFieldText = bodyField.text {
            bodyText += "\n\n\(bodyFieldText)"
        }
        
        bodyText += Helpers.templateText()

        reporter?.submit(title: titleText, body: bodyText, screenshotData: imageData, completionHandler: { (complete) in
            self.close()
        })
		
		// Save the email address for next time
        Helpers.saveEmail(email: emailField.text)
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let stack: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 10
        return view
    }()
    
    private let titleField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.placeholder = "Short description of issue"
        textField.keyboardType = .asciiCapable
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let emailField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.placeholder = "Your email"
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let bodyField: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 130).isActive = true
        textView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.font = UIFont.systemFont(ofSize: 15)
        return textView
    }()
    
    private let imagePreviewButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let height = button.heightAnchor.constraint(equalToConstant: 80)
        height.priority = 999
        height.isActive = true
        
        let width = button.widthAnchor.constraint(equalToConstant: 80)
        width.priority = 999
        width.isActive = true
        
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.blue
        button.setTitle("Submit", for: .normal)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.layer.cornerRadius = 5
        return button
    }()
    
    private let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = Helpers.appDisplayVersion()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor(white: 0.8, alpha: 1.0)
        return label
    }()
    
    private func populateEmailField() {
        let defaults = UserDefaults(suiteName: "com.gabekangas.gityourfeedback")
        if let email = Helpers.email() {
            emailField.text = email
        }
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedbackInterfaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            image = pickedImage
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

class FeedbackViewController: UINavigationController {
    weak var reporter: FeedbackManager?
    
    init(reporter: FeedbackManager) {
        super.init(nibName: nil, bundle: nil)
        
        self.reporter = reporter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControllers = [FeedbackInterfaceViewController(reporter: reporter)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
