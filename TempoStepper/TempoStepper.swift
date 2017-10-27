//
//  TempoStepper.swift
//  TempoStepper
//
//  Created by Cem Olcay on 27.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit
import ALKit

/// Holds `TempoStepper`'s stepping state.
private enum TempoStepperState {
  /// Normal state. Nor increasing either decreasing.
  case normal
  /// Either with tap or by auto stepping, stepper increasing.
  case increasing
  /// Either with tap or by auto stepping, stepper decreasing.
  case decreasing
}

/// Custom stepper with auto stepping.
@IBDesignable public class TempoStepper: UIControl, UITextFieldDelegate {
  /// Current value of stepper. Defaults 0.
  @IBInspectable public var value: Double = 0 {
    didSet {
      valueTextField.text = showIntValue ? "\(Int(value))" : "\(value)"
      sendActions(for: .valueChanged)
    }
  }
  /// Minimum value can stepper get. Defaults 0.
  @IBInspectable public var minValue: Double = 0
  /// Maximum value can stepper get. Defaults 100.
  @IBInspectable public var maxValue: Double = 100
  /// Each tap or auto step in auto stepping time interval either increase or decrease its `value` this amount. Defaults 1.
  @IBInspectable public var stepValue: Double = 1
  /// Auto steps `stepValue` every this interval. Defaluts 0.3
  @IBInspectable public var defaultAutoSteppingInterval: TimeInterval = 0.3
  /// Auto steps faster `stepValue` every this interval. Defaults 0.1
  @IBInspectable public var fastAutoSteppingInterval: TimeInterval = 0.1
  /// Starts auto stepping `defaultAutoSteppingInterval` after this seconds. Otherwise behaves like user just tapped. Defaults 0.5
  @IBInspectable public var autoStepAfterInterval: TimeInterval = 0.5
  /// Auto step goes faster with `fastAutoSteppingInterval` after this seconds. Defaults 2.
  @IBInspectable public var fastAutoStepAfterInterval: TimeInterval = 2.0
  /// On/off tap to change stepper's `value` with a keypad feature. Defaults true.
  @IBInspectable public var shouldTapToChange: Bool = true
  /// On/off auto stepping feature. Defaults true.
  @IBInspectable public var shouldAutoStep: Bool = true
  /// Set true, if you want to show `value` without decimals. Defaults true.
  @IBInspectable public var showIntValue: Bool = true
  /// Text color that shows stepper's `value`. Defaults black.
  @IBInspectable public var valueTextColor: UIColor = .black
  /// Font that shows stepper's `value`. Defaults body system font.
  @IBInspectable public var valueFont: UIFont = .preferredFont(forTextStyle: .body)
  /// Text color of stepper's increase/decrease buttons. Defaults black.
  @IBInspectable public var stepperButtonTextColor: UIColor = .black
  /// Font of stepper's increase/decrease buttons. Defaults body system font.
  @IBInspectable public var stepperButtonFont: UIFont = .preferredFont(forTextStyle: .body)
  /// Increase button text. Defaults "+".
  @IBInspectable public var increaseButtonText: String = "+"
  /// Decrease button text. Defaults "-".
  @IBInspectable public var decreaseButtonText: String = "-"

  /// Current state of stepper.
  private var stepperState: TempoStepperState = .normal
  /// Timer that control auto stepping.
  private var stepperTimer: Timer?
  /// Timer start date reference to update default/fast speed by `fastAutoSteppingInterval`.
  private var stepperTimerStartDate: Date?
  /// Stack view that layouts stepper components.
  public private(set) var stepperContainerStackView = UIStackView(frame: .zero)
  /// Stack view that layouts increase/decrease buttons vertically.
  public private(set) var stepperButtonsStackView = UIStackView(frame: .zero)
  /// Text field that shows stepper's `value`.
  public private(set) var valueTextField = UITextField(frame: .zero)
  /// Incrases stepper's `value` on each tap or auto stepping mode, `stepValue` amount.
  public private(set) var increaseButton = UIButton(type: .system)
  /// Decreases stepper's `value` on each tap or auto stepping mode, `stepValue` amount.
  public private(set) var decreaseButton = UIButton(type: .system)

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    // Container
    stepperContainerStackView.axis = .horizontal
    stepperContainerStackView.alignment = .center
    stepperContainerStackView.spacing = 0
    addSubview(stepperContainerStackView)
    stepperContainerStackView.translatesAutoresizingMaskIntoConstraints = false
    stepperContainerStackView.fill(to: self)
    // Text field
    stepperContainerStackView.addArrangedSubview(valueTextField)
    valueTextField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    valueTextField.borderStyle = .none
    valueTextField.delegate = self
    valueTextField.translatesAutoresizingMaskIntoConstraints = false
    valueTextField.fillVertical(to: stepperContainerStackView)
    // Buttons Container
    stepperContainerStackView.addArrangedSubview(stepperButtonsStackView)
    stepperButtonsStackView.distribution = .fillEqually
    stepperButtonsStackView.alignment = .center
    stepperButtonsStackView.axis = .vertical
    stepperButtonsStackView.spacing = 0
    stepperButtonsStackView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
    stepperButtonsStackView.addArrangedSubview(increaseButton)
    stepperButtonsStackView.addArrangedSubview(decreaseButton)
    // Increase button
    increaseButton.translatesAutoresizingMaskIntoConstraints = false
    increaseButton.fillHorizontal(to: stepperButtonsStackView)
    increaseButton.isUserInteractionEnabled = false
    // Decrease button
    decreaseButton.translatesAutoresizingMaskIntoConstraints = false
    decreaseButton.fillHorizontal(to: stepperButtonsStackView)
    decreaseButton.isUserInteractionEnabled = false
  }

  // MARK: Lifecycle

  public override func layoutSubviews() {
    super.layoutSubviews()
    // Text field
    valueTextField.textColor = valueTextColor
    valueTextField.font = valueFont
    valueTextField.text = showIntValue ? "\(Int(value))" : "\(value)"
    // Increase button
    increaseButton.setTitle(increaseButtonText, for: .normal)
    increaseButton.setTitleColor(stepperButtonTextColor, for: .normal)
    increaseButton.titleLabel?.font = stepperButtonFont
    // Decrease button
    decreaseButton.setTitle(decreaseButtonText, for: .normal)
    decreaseButton.setTitleColor(stepperButtonTextColor, for: .normal)
    decreaseButton.titleLabel?.font = stepperButtonFont
  }

  // MARK: Stepping

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touch = touches.first, touches.count == 1 else { invalidateTimer(); return }
    let position = touch.location(in: nil)
    // Start stepping timer if user touched a step button.
    if increaseButton.convert(increaseButton.frame, to: nil).contains(position) {
      stepperState = .increasing
      increaseButton.isHighlighted = true
      decreaseButton.isHighlighted = false
    } else if decreaseButton.convert(increaseButton.frame, to: nil).contains(position) {
      stepperState = .decreasing
      increaseButton.isHighlighted = false
      decreaseButton.isHighlighted = true
    }

    // Pass increase or decrease data to userInfo.
    stepperTimerStartDate = Date()
    stepperTimer = Timer.scheduledTimer(
      timeInterval: autoStepAfterInterval,
      target: self,
      selector: #selector(stepperTimeTick(timer:)),
      userInfo: nil,
      repeats: false)
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard let touch = touches.first, touches.count == 1 else { invalidateTimer(); return }
    let position = touch.location(in: nil)

    // Check if stepper changed
    if increaseButton.convert(increaseButton.frame, to: nil).contains(position) {
      stepperState = .increasing
      increaseButton.isHighlighted = true
      decreaseButton.isHighlighted = false
    } else if decreaseButton.convert(increaseButton.frame, to: nil).contains(position) {
      stepperState = .decreasing
      increaseButton.isHighlighted = false
      decreaseButton.isHighlighted = true
    } else {
      stepperState = .normal
      increaseButton.isHighlighted = false
      decreaseButton.isHighlighted = false
    }
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard let startDate = stepperTimerStartDate else { invalidateTimer(); return }

    // Check if user just tapped instead of auto stepping.
    if Date().timeIntervalSince(startDate) < autoStepAfterInterval {
      switch stepperState {
      case .decreasing:
        decreaseValue()
        increaseButton.isHighlighted = false
        decreaseButton.isHighlighted = false
      case .increasing:
        increaseValue()
        increaseButton.isHighlighted = false
        decreaseButton.isHighlighted = false
      default:
        break
      }
    }

    invalidateTimer()
  }

  @objc internal func stepperTimeTick(timer: Timer) {
    guard let startDate = stepperTimerStartDate else { invalidateTimer(); return }
    let interval = Date().timeIntervalSince(startDate) > fastAutoStepAfterInterval ? fastAutoSteppingInterval : defaultAutoSteppingInterval
    stepperTimer = Timer.scheduledTimer(
      timeInterval: interval,
      target: self,
      selector: #selector(stepperTimeTick(timer:)),
      userInfo: nil,
      repeats: false)

    switch stepperState {
    case .increasing:
      increaseValue()
    case .decreasing:
      decreaseValue()
    default:
      return
    }
  }

  private func increaseValue() {
    value = max(min(value + stepValue, maxValue), minValue)
  }

  private func decreaseValue() {
    value = max(min(value - stepValue, maxValue), minValue)
  }

  private func invalidateTimer() {
    stepperTimer?.invalidate()
    stepperTimer = nil
    stepperTimerStartDate = nil
    stepperState = .normal
    increaseButton.isHighlighted = false
    decreaseButton.isHighlighted = false
  }

  // MARK: UITextFieldDelegate

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return shouldTapToChange
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string == "\n" {
      textField.resignFirstResponder()
      value = max(min((Double(textField.text ?? "") ?? 0), maxValue), minValue)
      return false
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimum = 0
    return formatter.number(from: "\(valueTextField.text ?? "")\(string)") != nil
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    let value = Double(textField.text ?? "") ?? 0
    self.value = max(min(value, maxValue), minValue)
  }
}
