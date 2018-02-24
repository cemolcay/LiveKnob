//
//  LiveKnob.swift
//  LiveKnob
//
//  Created by Cem Olcay on 21.02.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

@IBDesignable public class LiveKnob: UIControl {
  /// The minimum value of the knob. Defaults to 0.0.
  @IBInspectable public var minimumValue: Float = 0.0 { didSet { drawKnob() }}

  /// The maximum value of the knob. Defaults to 1.0.
  @IBInspectable public var maximumValue: Float = 1.0 { didSet { drawKnob() }}

  /// Value of the knob. Also known as progress.
  @IBInspectable public var value: Float = 0.0 { didSet { setNeedsLayout() }}

  /// Default color for the ring base. Defaults black.
  @IBInspectable public var baseColor: UIColor = .black { didSet { drawKnob() }}

  /// Default color for the pointer. Defaults black.
  @IBInspectable public var pointerColor: UIColor = .black { didSet { drawKnob() }}

  /// Default color for the progress. Defaults orange.
  @IBInspectable public var progressColor: UIColor = .orange { didSet { drawKnob() }}

  /// Line width for the ring base. Defaults 2.
  @IBInspectable public var baseLineWidth: CGFloat = 2 { didSet { drawKnob() }}

  /// Line width for the progress. Defaults 2.
  @IBInspectable public var progressLineWidth: CGFloat = 2 { didSet { drawKnob() }}

  /// Line width for the pointer. Defaults 2.
  @IBInspectable public var pointerLineWidth: CGFloat = 2 { didSet { drawKnob() }}

  /// Layer for the base ring.
  private let baseLayer = CAShapeLayer()
  /// Layer for the progress ring.
  private let progressLayer = CAShapeLayer()
  /// Layer for the value pointer.
  private let pointerLayer = CAShapeLayer()
  /// Start angle of the base ring.
  private var startAngle = -CGFloat.pi * 11 / 8.0
  /// End angle of the base ring.
  private var endAngle = CGFloat.pi * 3 / 8.0
  /// Knob gesture recognizer.
  private var gestureRecognizer: RotationGestureRecognizer!

  // MARK: Init

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  private func commonInit() {
    // Setup knob gesture
    gestureRecognizer = RotationGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    addGestureRecognizer(gestureRecognizer)
    // Setup layers
    baseLayer.fillColor = UIColor.clear.cgColor
    progressLayer.fillColor = UIColor.clear.cgColor
    pointerLayer.fillColor = UIColor.clear.cgColor
    layer.addSublayer(baseLayer)
    layer.addSublayer(progressLayer)
    layer.addSublayer(pointerLayer)
  }

  // MARK: Lifecycle

  public override func layoutSubviews() {
    super.layoutSubviews()
    drawKnob()
  }

  public func drawKnob() {
    // Setup layers
    baseLayer.bounds = bounds
    baseLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    progressLayer.bounds = baseLayer.bounds
    progressLayer.position = baseLayer.position
    pointerLayer.bounds = baseLayer.bounds
    pointerLayer.position = baseLayer.position
    baseLayer.lineWidth = baseLineWidth
    progressLayer.lineWidth = progressLineWidth
    pointerLayer.lineWidth = pointerLineWidth
    baseLayer.strokeColor = baseColor.cgColor
    progressLayer.strokeColor = progressColor.cgColor
    pointerLayer.strokeColor = pointerColor.cgColor

    // Draw base ring.
    let center = CGPoint(x: baseLayer.bounds.width / 2, y: baseLayer.bounds.height / 2)
    let radius = (min(baseLayer.bounds.width, baseLayer.bounds.height) / 2) - baseLineWidth
    let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    baseLayer.path = ring.cgPath
    baseLayer.lineCap = kCALineCapRound

    // Draw pointer.
    let pointer = UIBezierPath()
    pointer.move(to: center)
    pointer.addLine(to: CGPoint(x: center.x + radius, y: center.y))
    pointerLayer.path = pointer.cgPath
    pointerLayer.lineCap = kCALineCapRound

    let angle = CGFloat(angleForValue(value))
    let progressRing = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: angle, clockwise: true)
    progressLayer.path = progressRing.cgPath
    progressLayer.lineCap = kCALineCapRound

    // Draw pointer
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    pointerLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    CATransaction.commit()
  }

  // MARK: Rotation Gesture Recogniser

  // note the use of dynamic, because calling
  // private swift selectors(@ gestureRec target:action:!) gives an exception
  @objc dynamic func handleGesture(_ gesture: RotationGestureRecognizer) {
    let midPointAngle = (2 * CGFloat.pi + startAngle - endAngle) / 2 + endAngle

    var boundedAngle = gesture.touchAngle
    if boundedAngle > midPointAngle {
      boundedAngle -= 2 * CGFloat.pi
    } else if boundedAngle < (midPointAngle - 2 * CGFloat.pi) {
      boundedAngle += 2 * CGFloat.pi
    }

    boundedAngle = min(endAngle, max(startAngle, boundedAngle))
    value = min(maximumValue, max(minimumValue, valueForAngle(boundedAngle)))
    sendActions(for: .valueChanged)
  }

  // MARK: Value/Angle conversion

  public func valueForAngle(_ angle: CGFloat) -> Float {
    let angleRange = Float(endAngle - startAngle)
    let valueRange = maximumValue - minimumValue
    return Float(angle - startAngle) / angleRange * valueRange + minimumValue
  }

  public func angleForValue(_ value: Float) -> CGFloat {
    let angleRange = endAngle - startAngle
    let valueRange = CGFloat(maximumValue - minimumValue)
    return CGFloat(self.value - minimumValue) / valueRange * angleRange + startAngle
  }
}

/// Custom gesture recognizer for the knob.
public class RotationGestureRecognizer: UIPanGestureRecognizer {
  /// Current angle of the touch related the current progress value of the knob.
  public var touchAngle: CGFloat = 0

  // MARK: UIGestureRecognizerSubclass

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    updateTouchAngleWithTouches(touches)
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    updateTouchAngleWithTouches(touches)
  }

  private func updateTouchAngleWithTouches(_ touches: Set<UITouch>) {
    let touch = touches.first!
    let touchPoint = touch.location(in: view)
    touchAngle = calculateAngleToPoint(touchPoint)
  }

  private func calculateAngleToPoint(_ point: CGPoint) -> CGFloat {
    let centerOffset = CGPoint(x: point.x - view!.bounds.midX, y: point.y - view!.bounds.midY)
    return atan2(centerOffset.y, centerOffset.x)
  }

  // MARK: Lifecycle

  public override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    maximumNumberOfTouches = 1
    minimumNumberOfTouches = 1
  }
}
