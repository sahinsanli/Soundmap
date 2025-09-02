//
//  SignUpViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 4.08.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

class SignUpViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailFİeld: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(gesture)
        
        // Top-left back button (theme-friendly)
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])

        // Do any additional setup after loading the view.
    }
    
    func makealert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let button = UIAlertAction(title: "ok", style: UIAlertAction.Style.default)
        alert.addAction(button)
        self.present(alert,animated: true,completion: nil)
        
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        
        if passwordField.text != "" && emailFİeld.text != "" {
            Auth.auth().createUser(withEmail: emailFİeld.text!, password: passwordField.text!){ (authdata,error) in
                if error != nil {
                    self.makealert(title: "Error", message: error!.localizedDescription)
                }
                else{
                    self.performSegue(withIdentifier: "toRecords", sender: nil )
                }
                
                
                
            }
            
        }
    }
    
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func backTapped() {
        // Return to RegisterViewController
        dismiss(animated: true)
    }
    

}
