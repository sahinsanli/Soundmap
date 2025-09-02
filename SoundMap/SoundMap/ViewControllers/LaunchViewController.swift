//
//  LaunchViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 2.08.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LaunchViewController: UIViewController {

    @IBOutlet weak var splashImage: UIImageView!
    @IBOutlet weak var namelabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        namelabel.text = "Welcome to SoundMap!"
        namelabel.alpha = 0.0
        splashImage.alpha = 0.0
        splashImage.image = UIImage(named: "sound-waves.png")
        
       

        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 2.0, delay: 0.2, options: .curveEaseInOut, animations:  {
            self.namelabel.textColor = .black
            self.namelabel.alpha = 1.0
            self.splashImage.alpha = 1.0
            self.splashImage.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)},
                       completion: { _ in
            
            let currentUser = Auth.auth().currentUser
            if currentUser != nil {
                self.gotoMainApp()
            }
            self.goToOnboarding()
            
            })
            
            
        }
    
    func goToOnboarding() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
        onboardingVC.modalPresentationStyle = .fullScreen
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    func gotoMainApp() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RecordsViewController") as! RecordsViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .coverVertical
            self.present(vc,animated: true,completion: nil)
        
        
    }
    
  
   }
    
    
    
    
  
    

  


