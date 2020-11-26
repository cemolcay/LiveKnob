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
    guard let knob = knob, let knobLabel = knobLabel else { return }
    knobLabel.text = String(format: "%.2f", arguments: [knob.value])
    knob.controlType = .horizontalAndVertical
    knob.markers = [Int](0..<8).map({ _ in createMarker() })
  }
  
  func createMarker() -> LiveKnobMarker {
    let view = LiveKnobMarker(frame: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
    view.isUserInteractionEnabled = false
    view.backgroundColor = .lightGray
    view.layer.cornerRadius = 4
    return view
  }
  
  @IBAction func knobValueDidChange(sender: LiveKnob) {
    knobLabel?.text = String(format: "%.2f", arguments: [sender.value])
  }

  @IBAction func knobDidEndChangingValue(sender: LiveKnob) {
    print("did end changing value")
  }
}

