//
//  OnboardingViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 2.08.2025.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var onboardImage: UIImageView!
    @IBOutlet weak var presentLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentLabel.text = pages[currentpage]
        titleLabel.text = titles[currentpage]
        overrideUserInterfaceStyle = .light
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentpage
        setswipeGestures()
    }
    
    func setswipeGestures(){
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        leftSwipeGesture.direction = .left
        view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe) )
        rightSwipeGesture.direction = .right
        view.addGestureRecognizer(rightSwipeGesture)
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction{
        case .left:
            if currentpage < pages.count - 1 {
                currentpage += 1
                updateUI()
            }
            else {
                gotoMainApp()
                
            }
        case .right:
            if currentpage > 0 {
                currentpage -= 1
                updateUI()}
            else {
                print("already at first page")
            }
        default:
            break
        }
        
    }
    
    let images = [("soundwave"),("geography"),("diskette"),("edit")]
    let titles = [("WELCOME!"), ("EXPLORE"), ("SAVE"), ("CREATE")]
    let pages = [("Record your memories aloud"), ("Explore new places"), ("When you come back to that place, your memories will come alive."), ("Go and create new memories")]
    
    var currentpage = 0
    
    
    
    
    
    
    func updateUI(){
        presentLabel.text = pages[currentpage]
        titleLabel.text = titles[currentpage]
        onboardImage.image = UIImage(named: images[currentpage])
        pageControl.currentPage = currentpage
        
       
        
    }
    
    func gotoMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        self.present(vc,animated: true,completion: nil)
        
    }
    
    
}
