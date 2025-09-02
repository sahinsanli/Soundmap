//
//  RegisterViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 3.08.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase


class RegisterViewController: UIViewController {
    @IBOutlet var EmailLabel: UIView!
   
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailfield: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismisskeyboard))
        view.addGestureRecognizer(gesture)
        // Do any additional setup after loading the view.
    }
    

    @IBAction func signinClicked(_ sender: Any) {
        
        if emailfield.text != "" && passwordField.text != ""{
            
            Auth.auth().signIn(withEmail: emailfield.text!, password: passwordField.text!) {
                (authdata, error) in
                if error != nil{
                    self.makeAlert(title: "Error", message: error!.localizedDescription)
                }
                else{
                    self.performSegue(withIdentifier: "toRecords", sender: nil)
                
                }
            }
        }
        
        
    }
    
    
    @IBAction func signupClicked(_ sender: Any) {
        performSegue(withIdentifier: "toRegister", sender: nil)
        
    }
    
    @objc func dismisskeyboard(){
        view.endEditing(true)
    }
    
    
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let button = UIAlertAction(title: "OK", style: UIAlertAction.Style.default,handler: nil)
        alert.addAction(button)
        self.present(alert,animated: true,completion: nil)
        
        
    }
    
}
