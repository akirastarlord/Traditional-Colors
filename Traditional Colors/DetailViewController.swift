//
//  DetailViewController.swift
//  WebParser
//
//  Created by yy的mac on 2019/11/24.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import UIKit

enum DisplayState {
    case byProgress, byValue
}

class DetailViewController: UIViewController, StoryReaderDelegate {
    
    var color: Color? = nil
    var displayState: DisplayState = .byProgress
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var colorValueView: UIView!
    
    @IBOutlet weak var love: UIImageView!
    
    /* Note: r, g, b labels and progress views will be used as their
             c, m, y corresponding views in cmyk mode */
    @IBOutlet weak var rLabel: UILabel!
    @IBOutlet weak var gLabel: UILabel!
    @IBOutlet weak var bLabel: UILabel!
    @IBOutlet weak var kLabel: UILabel!
    
    @IBOutlet weak var rProgress: UIProgressView!
    @IBOutlet weak var gProgress: UIProgressView!
    @IBOutlet weak var bProgress: UIProgressView!
    @IBOutlet weak var kProgress: UIProgressView!
    
    @IBOutlet weak var rValueLabel: UILabel!
    @IBOutlet weak var gValueLabel: UILabel!
    @IBOutlet weak var bValueLabel: UILabel!
    @IBOutlet weak var kValueLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let color = color {
            
            if let link = color.link {
                let reader = Parser(url: link)
                reader.detailPageParserDelegate = self
                reader.readDetailPage(color)
            }
            
            if let colorView = view.viewWithTag(1) as? UIImageView {
                colorView.backgroundColor = UIColor(hex: color.colorCode)
            }
            if let nameLabel = view.viewWithTag(2) as? UILabel {
                nameLabel.text = color.name
            }
            if let kanaLabel = view.viewWithTag(3) as? UILabel {
                kanaLabel.text = color.hiragana
            }
            if let romanjiLabel = view.viewWithTag(4) as? UILabel {
                romanjiLabel.text = color.romanji
            }
            if let hexLabel = view.viewWithTag(5) as? UILabel {
                hexLabel.text = color.colorCode
            }
            
            segmentedControl.addTarget(self, action: #selector(swithColorValueMode(_:)), for: .valueChanged)
            colorValueView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(colorValueViewTapped(_:))))
            love.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapFavorite(_:))))
        }
    }
    
    // MARK: - Segemented Control method - switch color mode
    @objc func swithColorValueMode(_ sc: UISegmentedControl) {
        /* Default to progress state whenever color mode changes */
        displayState = .byProgress
        switch sc.selectedSegmentIndex {
        case 0, 1:
            configureProgressBars()
            configureColorValueView()
        default:
            print("unexpected case encountered by segmented control")
        }
    }
    
    private func configureProgressBars() {
        let index = segmentedControl.selectedSegmentIndex
        DispatchQueue.main.async {
            if let color = self.color, let cv = color.colorValue {
                /* RGB mode */
                if index == 0 && cv.rgbValid() {
                    self.kLabel.isHidden = true
                    self.kProgress.isHidden = true
                    self.rLabel.text = "R"
                    self.gLabel.text = "G"
                    self.bLabel.text = "B"
                    UIView.animate(withDuration: 1.0) {
                        self.rProgress.trackTintColor = .red
                        self.gProgress.trackTintColor = .green
                        self.bProgress.trackTintColor = .blue
                        self.rProgress.setProgress(1 - (Float(cv.r!) / 255.0), animated: true)
                        self.gProgress.setProgress(1 - (Float(cv.g!) / 255.0), animated: true)
                        self.bProgress.setProgress(1 - (Float(cv.b!) / 255.0), animated: true)
                    }
                    self.rValueLabel.text = String(cv.r!)
                    self.gValueLabel.text = String(cv.g!)
                    self.bValueLabel.text = String(cv.b!)
                }
                    /* CMYK mode */
                else if index == 1 && cv.cmykValid() {
                    self.kLabel.isHidden = false
                    self.kProgress.isHidden = false
                    self.rLabel.text = "C"
                    self.gLabel.text = "M"
                    self.bLabel.text = "Y"
                    UIView.animate(withDuration: 1.0) {
                        self.rProgress.trackTintColor = .cyan
                        self.gProgress.trackTintColor = .magenta
                        self.bProgress.trackTintColor = .orange
                        self.rProgress.setProgress(1 - (Float(cv.c!) / 255.0), animated: true)
                        self.gProgress.setProgress(1 - (Float(cv.m!) / 255.0), animated: true)
                        self.bProgress.setProgress(1 - (Float(cv.y!) / 255.0), animated: true)
                        self.kProgress.setProgress(1 - (Float(cv.k!) / 255.0), animated: true)
                    }
                    self.rValueLabel.text = String(cv.c!)
                    self.gValueLabel.text = String(cv.m!)
                    self.bValueLabel.text = String(cv.y!)
                    self.kValueLabel.text = String(cv.k!)
                }
            }
        }
    }

    // MARK: - color value display method - switch display state
    @objc func colorValueViewTapped(_ sender: UITapGestureRecognizer?) {
        //print("ColorValueView tap detected")
        /* update the state model and leave the UI to be handled by updateColorValueView */
        if displayState == .byProgress {
            displayState = .byValue
        }
        else {
            displayState = .byProgress
        }
        configureColorValueView()
    }
    
    /* update the color value display view according to the current state model
     this method doesn't change state at all */
    private func configureColorValueView() {
        let colorMode = segmentedControl.selectedSegmentIndex
        guard let cv = color?.colorValue else {
            print("Unexpected state when switching display state")
            return
        }
        switch displayState {
        case .byProgress:
            DispatchQueue.main.async {
                self.rValueLabel.isHidden = true
                self.gValueLabel.isHidden = true
                self.bValueLabel.isHidden = true
                self.kValueLabel.isHidden = true
                self.rProgress.isHidden = false
                self.gProgress.isHidden = false
                self.bProgress.isHidden = false
                if colorMode == 1 {
                    self.kProgress.isHidden = false
                }
            }
        case .byValue:
            /* (0,P) -> (0,V), (1,P) -> (1,V) */
            DispatchQueue.main.async {
                self.rProgress.isHidden = true
                self.gProgress.isHidden = true
                self.bProgress.isHidden = true
                self.kProgress.isHidden = true
                self.rValueLabel.isHidden = false
                self.gValueLabel.isHidden = false
                self.bValueLabel.isHidden = false
                if colorMode == 1 && cv.cmykValid() {
                    self.kValueLabel.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Add to favorites method
    @objc func didTapFavorite(_ sender: UITapGestureRecognizer?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0) {
                self.love.image = UIImage(systemName: "heart.fill")
                self.love.tintColor = .red
                self.love.alpha = 1
            }
        }
    }
    
    // MARK: - StoryReaderDelegate method
    func didFinishReadingStories() {
        DispatchQueue.main.async {
            if let textView = self.view.viewWithTag(6) as? UITextView {
                textView.text = self.color?.story
                self.configureProgressBars()
            }
        }
    }
    
    
}
