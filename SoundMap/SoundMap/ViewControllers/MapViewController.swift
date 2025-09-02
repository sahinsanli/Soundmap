//
//  MapViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 4.08.2025.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
import FirebaseAuth
import Foundation
import FirebaseStorage
import FirebaseFirestore


class MapViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var audioRecorder : AVAudioRecorder?
    var recordingSession : AVAudioSession!
    var audiofileName : URL?
    var audioPlayer : AVAudioPlayer?
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    // Modern UI elements
    private let recordButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private let locateButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private var isRecordingUIActive = false
    private var hasSelectedLocation = false
    private var selectedAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Tek dokunuşla pin bırakma
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        fetchuserRecordingsOnMap()
        
        // Hide legacy text buttons if present
        for case let button as UIButton in view.subviews {
            if button.currentTitle == "Record" || button.currentTitle == "Play" || button.currentTitle == "Log Out" {
                button.isHidden = true
            }
        }
        
        setupFloatingButtons()
        
        // Marker style registration
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "marker")
        
        // Başta kayıt butonunu devre dışı bırak (nokta seçilmeden kayıt yok)
        recordButton.isEnabled = false
        recordButton.alpha = 0.5
        

        // Do any additional setup after loading the view.
    }
    // Tek dokunuşla pin bırakma
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self.mapView)
        let coord = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        if let old = selectedAnnotation { mapView.removeAnnotation(old) }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        annotation.title = "Seçim"
        self.mapView.addAnnotation(annotation)
        self.selectedAnnotation = annotation
        chosenLatitude = coord.latitude
        chosenLongitude = coord.longitude
        hasSelectedLocation = true
        recordButton.isEnabled = true
        recordButton.alpha = 1.0
    }
    
    // MARK: - Modern UI helpers
    private func setupFloatingButtons() {
        func style(_ b: UIButton, size: CGFloat = 56) {
            b.translatesAutoresizingMaskIntoConstraints = false
            b.backgroundColor = .systemBackground
            b.tintColor = .label
            b.layer.cornerRadius = size / 2
            b.layer.shadowColor = UIColor.black.cgColor
            b.layer.shadowOpacity = 0.15
            b.layer.shadowRadius = 8
            b.layer.shadowOffset = CGSize(width: 0, height: 4)
            b.widthAnchor.constraint(equalToConstant: size).isActive = true
            b.heightAnchor.constraint(equalToConstant: size).isActive = true
        }
        
        // Record (center bottom)
        recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        style(recordButton, size: 64)
        recordButton.addTarget(self, action: #selector(recordFloatingTapped), for: .touchUpInside)
        view.addSubview(recordButton)
        
        // Play (bottom-right)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        style(playButton)
        playButton.addTarget(self, action: #selector(playFloatingTapped), for: .touchUpInside)
        view.addSubview(playButton)
        
        // Locate (bottom-left)
        locateButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        style(locateButton)
        locateButton.addTarget(self, action: #selector(centerOnUserLocation), for: .touchUpInside)
        view.addSubview(locateButton)
        
        // Back (top-left)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backFloatingTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Logout (top-right)
        logoutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.tintColor = .label
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
        
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: g.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -20),
            playButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            playButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -24),
            locateButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            locateButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -24),
            backButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            logoutButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -12),
            logoutButton.topAnchor.constraint(equalTo: g.topAnchor, constant: 8)
        ])
    }
    
    @objc private func recordFloatingTapped() {
        guard hasSelectedLocation else {
            let alert = UIAlertController(title: "Konum gerekli", message: "Kayıt almadan önce haritada bir nokta seçin.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        if audioRecorder == nil {
            startRecording()
            startRecordingUI()
        } else {
            // 1) KAYDI HEMEN DURDUR
            audioStop()
            stopRecordingUI()
            guard let stoppedFile = self.audiofileName else { return }

            // 2) İSİM İSTE
            let alert = UIAlertController(title: "Kaydet", message: "Kayıt için bir isim girin", preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "ör. gün batımı"
            }
            let kaydet = UIAlertAction(title: "Kaydet", style: .default) { _ in
                let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = (name?.isEmpty == false) ? name! : "ses kaydı"
                let newfileName = finalName + ".m4a"
                let newfileURL = self.getDocumentsDirectory().appendingPathComponent(newfileName)
                do {
                    try FileManager.default.moveItem(at: stoppedFile, to: newfileURL)
                    self.audiofileName = newfileURL
                    self.selectedAnnotation?.title = finalName
                    self.savetoFirebase(url: newfileURL, displayname: finalName)
                } catch {
                    print("dosya taşıma hatası: \(error.localizedDescription)")
                }
            }
            let iptal = UIAlertAction(title: "İptal", style: .cancel)
            alert.addAction(kaydet)
            alert.addAction(iptal)
            present(alert, animated: true)
        }
    }
    
    @objc private func playFloatingTapped() {
        // Eğer bu oturumda yerel bir kayıt varsa doğrudan çal
        if audiofileName != nil {
            playRecording()
            return
        }
        // Yoksa Firestore'dan en son kaydı indirip çal
        guard let user = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("recordings")
            .whereField("userID", isEqualTo: user.uid)
            .order(by: "timeStamp", descending: true)
            .limit(to: 1)
            .getDocuments { snap, err in
                if let err = err {
                    print("Firestore fetch error: \(err.localizedDescription)")
                    return
                }
                guard let doc = snap?.documents.first,
                      let urlStr = doc["fileURL"] as? String,
                      let url = URL(string: urlStr) else {
                    print("Kayıt bulunamadı")
                    return
                }
                URLSession.shared.downloadTask(with: url) { localURL, _, error in
                    if let error = error {
                        print("Download error: \(error.localizedDescription)")
                        return
                    }
                    guard let localURL = localURL else { return }
                    DispatchQueue.main.async {
                        self.audiofileName = localURL
                        self.playRecording()
                    }
                }.resume()
            }
    }
    @objc private func backFloatingTapped() { gotoRecords() }
    @objc private func centerOnUserLocation() {
        if let c = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: c, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func startRecordingUI() {
        isRecordingUIActive = true
        recordButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        addPulseAnimation(to: recordButton.layer)
    }
    
    private func stopRecordingUI() {
        isRecordingUIActive = false
        recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        removePulseAnimation(from: recordButton.layer)
    }
    
    private func addPulseAnimation(to layer: CALayer) {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.initialVelocity = 0.5
        pulse.damping = 0.8
        pulse.duration = 0.8
        layer.add(pulse, forKey: "pulse")
        let shadow = CABasicAnimation(keyPath: "shadowOpacity")
        shadow.fromValue = 0.15
        shadow.toValue = 0.35
        shadow.autoreverses = true
        shadow.repeatCount = .greatestFiniteMagnitude
        shadow.duration = 0.8
        layer.add(shadow, forKey: "shadowPulse")
    }
    
    private func removePulseAnimation(from layer: CALayer) {
        layer.removeAnimation(forKey: "pulse")
        layer.removeAnimation(forKey: "shadowPulse")
    }
    
    // Eksik fonksiyon: Kayıtlı dosyayı çal
    func playRecording() {
        print("Çalınacak dosya yolu:", audiofileName as Any)
        guard let url = audiofileName else {
            print("Dosya yolu bulunamadı")
            return
        }
        do {
            if recordingSession == nil { recordingSession = AVAudioSession.sharedInstance() }
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Oynatılıyor...")
        } catch {
            print("Ses çalma hatası: \(error.localizedDescription)")
        }
    }
    
    func fetchuserRecordingsOnMap(){
        guard let currentUser = Auth.auth().currentUser else {return}
        let db = Firestore.firestore()
        
        db.collection("recordings")
            .whereField("userID", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, err in
                if err != nil {
                    print("error")
                    return
                }
                guard let documents = snapshot?.documents else {return}
                for doc in documents {
                    let data = doc.data()
                    if let lat = data["latitude"] as? CLLocationDegrees,
                       let long = data["longitude"] as? CLLocationDegrees,
                       let filename = data["filename"] as? String{
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        annotation.title = filename
                        self.mapView.addAnnotation(annotation)
                    }
                }
            }
    }
     
    
    
    @objc func gestureAction(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self.mapView)
            let coord = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            // Eski seçimi kaldır
            if let old = selectedAnnotation { mapView.removeAnnotation(old) }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = "Seçim"
            self.mapView.addAnnotation(annotation)
            self.selectedAnnotation = annotation
            chosenLatitude = coord.latitude
            chosenLongitude = coord.longitude
            hasSelectedLocation = true
            // Kayıt butonunu aktifleştir
            recordButton.isEnabled = true
            recordButton.alpha = 1.0
        }
    }

    
    
    
    @IBAction func LogOutClicked(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            gotoMainApp()
        }
        catch {
            print("error")
        }
    }
    func gotoRecords () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RecordsViewController") as! RecordsViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .flipHorizontal
        self.present(vc,animated: true,completion: nil)
    }
    
    func gotoMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        self.present(vc,animated: true,completion: nil)
    }
    
    func startRecording() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do{
            try recordingSession.setCategory(.playAndRecord,mode: .default)
            try recordingSession.setActive(true)
            
            let filename = UUID().uuidString + ".m4a"
            audiofileName = getDocumentsDirectory().appendingPathComponent(filename)
            
            let settings = [
                AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey : 12000,
                AVNumberOfChannelsKey : 1,
                AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audiofileName!, settings: settings)
            audioRecorder?.record()
            
            
            print("Kayıt başladı ! Dosya adresi: \(audiofileName!)")
        }
        catch{
            print("Kayıt başlatılamadı ! \(error.localizedDescription)")
        }
    }
    
    func audioStop(){
        audioRecorder?.stop()
        audioRecorder = nil
        print("kayıt durdu.")
        
        if let audioPath = audiofileName {
            print("kayıt dosyası: \(audioPath)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }

    @IBAction func recordTapped(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
            sender.setTitle("durdur", for: .normal)
            
        }
        else{
            let alert = UIAlertController(title: "Kaydetme", message: nil , preferredStyle: UIAlertController.Style.alert)
            alert.addTextField(){ textfield in
                textfield.placeholder = "deneme"}
            
            let kaydetaction = UIAlertAction(title: "Kaydet", style: .default) { _ in
                let girilenisim = alert.textFields?.first?.text ?? "ses kaydı"
                self.audioStop()
                
                if let currentfile = self.audiofileName {
                    let newfileName = girilenisim + ".m4a"
                    let newfileURL = self.getDocumentsDirectory().appendingPathComponent(newfileName)
                    
                    do {
                        try FileManager.default.moveItem(at: currentfile, to: newfileURL)
                        self.audiofileName = newfileURL
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: self.chosenLatitude, longitude: self.chosenLongitude)
                        annotation.title = girilenisim
                        self.mapView.addAnnotation(annotation)
                        self.savetoFirebase(url: newfileURL,displayname: girilenisim)
                        
                    }
                    catch{
                        print("error")
                    }
                    
                }
                sender.setTitle( "Kaydet", for: .normal)
        }
            let iptalaction = UIAlertAction(title: "iptal", style: UIAlertAction.Style.cancel) { _ in
                self.audioStop()
                sender.setTitle("Kaydet", for: .normal)
                
            }
            
            alert.addAction(kaydetaction)
            alert.addAction(iptalaction)
            present(alert,animated: true)
        
        
        }
        
        
    }
    
    
    
    func uploadFirebase(url: URL) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let voice = storageRef.child("recordings/\(url.lastPathComponent)")
        
        voice.putFile(from: url,metadata: nil) { metadata,error in
            if let error = error {
                print("hata: \(error.localizedDescription)")
            }
            else{
                print("success")
            }
            
            
        }
    }
    
    
    
    @IBAction func backbuttonClicked(_ sender: Any) {
        gotoRecords()
    }
    
    @objc private func logoutTapped() {
        do {
            try Auth.auth().signOut()
            gotoMainApp()
        } catch {
            print("logout error: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    func savetoFirebase(url: URL,displayname: String) {
      guard let user = Auth.auth().currentUser else {
        print("No authenticated user")
        return
      }

      let storageRef = Storage.storage().reference()
      let voiceRef = storageRef.child("recordings/\(user.uid)/\(url.lastPathComponent)")

      voiceRef.putFile(from: url, metadata: nil) { metadata, error in
        if let error = error {
          print("Storage upload error: \(error.localizedDescription)")
          return
        }

        voiceRef.downloadURL { downloadURL, error in
          if let error = error {
            print("Get downloadURL error: \(error.localizedDescription)")
            return
          }
          guard let downloadURL = downloadURL else {
            print("No downloadURL")
            return
          }

          let db = Firestore.firestore()
          db.collection("recordings").addDocument(data: [
            "userID": user.uid,
            "filename": displayname,
            "fileURL": downloadURL.absoluteString,
            "timeStamp": FieldValue.serverTimestamp(),
            "latitude": self.chosenLatitude,
            "longitude": self.chosenLongitude
          ]) { err in
            if let err = err {
              print("Firestore write error: \(err.localizedDescription)")
            } else {
              print("Recording doc saved")
            }
          }
        }
      }
        
    }
    
    // Modern annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "marker", for: annotation) as! MKMarkerAnnotationView
        view.markerTintColor = .label
        view.glyphImage = UIImage(systemName: "waveform")
        view.titleVisibility = .adaptive
        return view
    }
        
    }

    
  
    
