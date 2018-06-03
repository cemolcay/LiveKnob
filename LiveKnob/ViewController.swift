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
  }

  @IBAction func knobValueDidChange(sender: LiveKnob) {
    knobLabel?.text = String(format: "%.2f", arguments: [sender.value])
  }
}

