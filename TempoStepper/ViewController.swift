//
//  ViewController.swift
//  TempoStepper
//
//  Created by Cem Olcay on 27.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBAction func stepperValueChanged(stepper: TempoStepper) {
    print(stepper.value)
  }
}
