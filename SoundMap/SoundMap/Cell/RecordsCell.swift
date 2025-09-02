//
//  RecordsCell.swift
//  SoundMap
//
//  Created by Şahin Şanlı on 12.08.2025.
//

import UIKit

class RecordsCell: UITableViewCell {

    @IBOutlet weak var playbutton: UIButton!
    @IBOutlet weak var recordlabel: UILabel!
    
    private var isConfigured = false
    
    enum PlayState {
        case playing
        case paused
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureOnce()
        apply(state: .paused, animated: false)
    }
    
    private func configureOnce() {
        guard !isConfigured else { return }
        isConfigured = true
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        // Play button as circular
        playbutton.backgroundColor = .systemGray6
        playbutton.tintColor = .label
        playbutton.layer.cornerRadius = 22
        playbutton.layer.masksToBounds = true
        playbutton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        
        recordlabel.textColor = .label
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func apply(state: PlayState, animated: Bool) {
        let changes = {
            switch state {
            case .playing:
                self.playbutton.backgroundColor = .label
                self.playbutton.tintColor = .systemBackground
                self.playbutton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                self.recordlabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            case .paused:
                self.playbutton.backgroundColor = .systemGray6
                self.playbutton.tintColor = .label
                self.playbutton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.recordlabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            }
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
                changes()
                self.playbutton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            } completion: { _ in
                UIView.animate(withDuration: 0.15) {
                    self.playbutton.transform = .identity
                }
            }
        } else {
            changes()
        }
    }

}
