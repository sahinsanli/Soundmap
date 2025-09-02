//
//  RecordsViewController.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 11.08.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import AVFoundation
import FirebaseStorage


class RecordsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, AVAudioPlayerDelegate{
    var player: AVAudioPlayer?
    struct Recording {
        let name: String
        let url: URL
    }
    
    var recordings: [Recording] = []
    
    @IBOutlet weak var tableview: UITableView!
    private let addFloating = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    private var currentlyPlayingIndexPath: IndexPath?
    private var currentDownloadTask: URLSessionDownloadTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableview.tableFooterView = UIView()
        
        setupHeader()
        setupAddFloating()
        
        fetchUserRecordings()
        
    }
  
  
    func gotoMap(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil )
        let vc = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .fullScreen
        self.present(vc,animated: true,completion: nil)
        
    }

    private func setupHeader(){
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Your Records"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
        
        // Give top inset so first cell doesn't collide
        var inset = tableview.contentInset
        inset.top += 44
        tableview.contentInset = inset
    }
    
    private func setupAddFloating(){
        addFloating.translatesAutoresizingMaskIntoConstraints = false
        addFloating.setImage(UIImage(systemName: "plus"), for: .normal)
        addFloating.tintColor = .white
        addFloating.backgroundColor = .black
        addFloating.layer.cornerRadius = 28
        addFloating.layer.shadowColor = UIColor.black.cgColor
        addFloating.layer.shadowOpacity = 0.2
        addFloating.layer.shadowRadius = 8
        addFloating.layer.shadowOffset = CGSize(width: 0, height: 4)
        addFloating.addTarget(self, action: #selector(addFloatingTapped), for: .touchUpInside)
        view.addSubview(addFloating)
        
        NSLayoutConstraint.activate([
            addFloating.widthAnchor.constraint(equalToConstant: 56),
            addFloating.heightAnchor.constraint(equalToConstant: 56),
            addFloating.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            addFloating.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func addFloatingTapped(){
        gotoMap()
    }
    
    func fetchUserRecordings(){
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("recordings")
            .whereField("userID", isEqualTo: user.uid )
            //.order(by: "timeStamp",descending: true)
            .getDocuments() { (snapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    return
                    
                }
                self.recordings = []
                guard let snapshot = snapshot else {return}
                for doc in snapshot.documents {
                    let data = doc.data()
                    if let fileURLString = data["fileURL"] as? String,
                       let fileURL = URL(string: fileURLString),
                       let fileName = data["filename"] as? String {
                        let recording = Recording(name: fileName,url: fileURL)
                        self.recordings.append(recording)
                    }
                }
                DispatchQueue.main.async{
                    self.tableview.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let recording = recordings[indexPath.row]
            let db = Firestore.firestore()
            db.collection("recordings")
                .whereField("fileURL", isEqualTo: recording.url.absoluteString)
                .getDocuments { (snapshot, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    snapshot?.documents.forEach{ doc in
                        db.collection("recordings").document(doc.documentID).delete(){error in
                            if error != nil {
                                print(error!.localizedDescription)
                            }
                            else{
                                print("silinme başarılı.")}
                        }
                    }
                    
                }
            DispatchQueue.main.async {
           self.recordings.remove(at: indexPath.row)
           tableView.deleteRows(at: [indexPath], with: .automatic)}
            
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecordsCell
        let recording = recordings[indexPath.row]
        cell.recordlabel.text = recording.name
        cell.playbutton.tag = indexPath.row
        cell.playbutton.addTarget(self, action: #selector(PlayButtonTapped) , for: .touchUpInside)
        // aktif çalan satırı görsel olarak işaretle
        let isThisPlaying = (currentlyPlayingIndexPath == indexPath) && (player?.isPlaying == true)
        cell.apply(state: isThisPlaying ? .playing : .paused, animated: false)
        
        return cell
        
    }
    @objc func PlayButtonTapped(_ sender: UIButton){
        // Hangi hücreye basıldığını güvenilir şekilde bul (superview zinciri)
        guard let indexPath = indexPathForButton(sender) else { return }
        let recording = recordings[indexPath.row]
        
        // Aynı satıra tekrar basılırsa durdur
        if currentlyPlayingIndexPath == indexPath, player?.isPlaying == true {
            player?.stop()
            player = nil
            updateCellState(at: indexPath, state: .paused)
            currentlyPlayingIndexPath = nil
            return
        }
        
        // Başka satır çalıyorsa onu durdur ve UI'ı sıfırla
        if let prev = currentlyPlayingIndexPath {
            player?.stop()
            player = nil
            updateCellState(at: prev, state: .paused)
        }
        currentlyPlayingIndexPath = indexPath
        updateCellState(at: indexPath, state: .playing)
        
        // Var olan indirme görevini iptal et
        currentDownloadTask?.cancel()
        currentDownloadTask = URLSession.shared.downloadTask(with: recording.url) { localURL, _, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled { return }
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.updateCellState(at: indexPath, state: .paused) }
                return
            }
            guard let localURL = localURL else { return }
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode: .default,options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.player = try AVAudioPlayer(contentsOf: localURL)
                    self.player?.delegate = self
                    self.player?.prepareToPlay()
                    self.player?.play()
                } catch {
                    print("Error playing audio: \(error.localizedDescription)")
                    self.updateCellState(at: indexPath, state: .paused)
                }
            }
        }
        currentDownloadTask?.resume()
        
    }
    
    private func indexPathForButton(_ button: UIButton) -> IndexPath? {
        var view: UIView? = button
        while view != nil && !(view is UITableViewCell) {
            view = view?.superview
        }
        guard let cell = view as? UITableViewCell else { return nil }
        return tableview.indexPath(for: cell)
    }
    
    private func updateCellState(at indexPath: IndexPath, state: RecordsCell.PlayState) {
        if let cell = tableview.cellForRow(at: indexPath) as? RecordsCell {
            cell.apply(state: state, animated: true)
        } else {
            tableview.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let indexPath = currentlyPlayingIndexPath {
            updateCellState(at: indexPath, state: .paused)
            currentlyPlayingIndexPath = nil
        }
    }
    
    

  

}
