//
//  ViewController.swift
//  LiveKnob
//
//  Created by Cem Olcay on 21.02.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var knob: LiveKnob?
    @IBOutlet weak var knobLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let knob = knob else { return }
        updateKnobValueText()
        
        // For coarse vertical, fine horizontal control
        knob.controlType = .coarseVerticalFineHorizontal
        knob.fineControlSensitivity = 0.15  // Adjust sensitivity (0.0-1.0, lower = finer control)
        
        // Add markers around the knob
        knob.markers = [Int](0..<8).map({ _ in createMarker() })
        
        knob.addDoubleTapGesture(target: self, action: #selector(knobDidDoubleTap(sender:)))
    }
    
    func createMarker() -> LiveKnobMarker {
        let view = LiveKnobMarker(frame: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
        view.isUserInteractionEnabled = false
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 4
        return view
    }
    
    @IBAction func knobValueDidChange(sender: LiveKnob) {
        updateKnobValueText()
    }
    
    @IBAction func knobDidEndChangingValue(sender: LiveKnob) {
        print("did end changing value")
    }
    
    @IBAction func knobDidDoubleTap(sender: UITapGestureRecognizer) {
        knob?.value = 0
        updateKnobValueText()
    }
    
    func updateKnobValueText() {
        knobLabel?.text = String(format: "%.2f", arguments: [knob?.value ?? 0])
    }
}

