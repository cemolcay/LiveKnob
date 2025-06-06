//
//  LiveKnob.swift
//  LiveKnob
//
//  Created by Cem Olcay on 21.02.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// The marker views around the knob.
public class LiveKnobMarker: UIView {
    /// Offset of the markers from the knob base.
    public var markerOffset: CGFloat = 24
    /// Custom transform for the marker.
    public var markerTransform: CGAffineTransform?
}

/// Knob controlling type. Rotating or horizontal and/or vertical touching.
public enum LiveKnobControlType: Int, Codable, CaseIterable, CustomStringConvertible {
    /// Only horizontal sliding changes the knob's value.
    case horizontal
    /// Only vertical sliding changes the knob's value.
    case vertical
    /// Coarse control for vertical movements, fine control for horizontal movements.
    /// The control will lock to either horizontal or vertical axis based on initial movement.
    case coarseVerticalFineHorizontal
    /// Fine control for vertical movements, coarse control for horizontal movements.
    /// The control will lock to either horizontal or vertical axis based on initial movement.
    case fineVerticalCoarseHorizontal
    /// Both horizontal and vertical sliding changes the knob's value.
    case horizontalAndVertical
    /// Only rotating sliding changes the knob's value.
    case rotary
    
    public var description: String {
        switch self {
        case .vertical:
            return "Vertical"
        case .horizontal:
            return "Horizontal"
        case .coarseVerticalFineHorizontal:
            return "Vertical Coarse - Horizontal Fine"
        case .fineVerticalCoarseHorizontal:
            return "Vertical Fine - Horizontal Coarse"
        case .horizontalAndVertical:
            return "Vertical Coarse - Horizontal Coarse"
        case .rotary:
            return "Rotary"
        }
    }
}

@IBDesignable public class LiveKnob: UIControl, UIGestureRecognizerDelegate {
    /// Whether changes in the value of the knob generate continuous update events.
    /// Defaults `true`.
    @IBInspectable public var continuous = true
    
    /// The minimum value of the knob. Defaults to 0.0.
    @IBInspectable public var minimumValue: Float = 0.0 { didSet { drawKnob() }}
    
    /// The maximum value of the knob. Defaults to 1.0.
    @IBInspectable public var maximumValue: Float = 1.0 { didSet { drawKnob() }}
    
    /// Value of the knob. Also known as progress.
    @IBInspectable public var value: Float = 0.0 {
        didSet {
            value = min(maximumValue, max(minimumValue, value))
            setNeedsLayout()
        }
    }
    
    /// Default color for the ring base. Defaults black.
    @IBInspectable public dynamic var baseColor: UIColor = .black { didSet { drawKnob() }}
    
    /// Default color for the pointer. Defaults black.
    @IBInspectable public dynamic var pointerColor: UIColor = .black { didSet { drawKnob() }}
    
    /// Default color for the progress. Defaults orange.
    @IBInspectable public dynamic var progressColor: UIColor = .orange { didSet { drawKnob() }}
    
    /// Line width for the ring base. Defaults 2.
    @IBInspectable public dynamic var baseLineWidth: CGFloat = 2 { didSet { drawKnob() }}
    
    /// Line width for the progress. Defaults 2.
    @IBInspectable public dynamic var progressLineWidth: CGFloat = 2 { didSet { drawKnob() }}
    
    /// Line width for the pointer. Defaults 2.
    @IBInspectable public dynamic var pointerLineWidth: CGFloat = 2 { didSet { drawKnob() }}
    
    /// Fine control sensitivity multiplier. Lower values mean finer control. Defaults to 0.2.
    @IBInspectable public dynamic var fineControlSensitivity: CGFloat = 0.2 { didSet { drawKnob() }}
    
    /// Direction detection threshold multiplier. Higher values require more pronounced movement to detect direction. Defaults to 1.0.
    @IBInspectable public dynamic var directionDetectionSensitivity: CGFloat = 1.0
    
    /// The marker views around the knob.
    public var markers = [LiveKnobMarker]() { didSet { refreshMarkersIfNeeded() }}
    /// Layer for the base ring.
    public private(set) var baseLayer = CAShapeLayer()
    /// Layer for the progress ring.
    public private(set) var progressLayer = CAShapeLayer()
    /// Layer for the value pointer.
    public private(set) var pointerLayer = CAShapeLayer()
    /// Start angle of the base ring.
    public var startAngle = -CGFloat.pi * 11 / 8.0
    /// End angle of the base ring.
    public var endAngle = CGFloat.pi * 3 / 8.0
    /// Knob's sliding type for changing its value. Defaults to rotary.
    public var controlType: LiveKnobControlType = .rotary {
        didSet {
            updateDirectionLockState()
        }
    }
    /// Knob gesture recognizer.
    public private(set) var gestureRecognizer: LiveKnobGestureRecognizer!
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    // Track the initial movement direction for axis-locked controls
    private var initialMovementDirection: MovementDirection = .none
    
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
        gestureRecognizer = LiveKnobGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)
        // Setup layers
        baseLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        pointerLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(baseLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(pointerLayer)
        
        // Enable direction locking for the new control types
        updateDirectionLockState()
    }
    
    /// Updates direction lock state based on the control type
    private func updateDirectionLockState() {
        switch controlType {
        case .coarseVerticalFineHorizontal, .fineVerticalCoarseHorizontal:
            directionLockEnabled = true
        default:
            directionLockEnabled = false
        }
    }
    
    // MARK: Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        drawKnob()
        layoutMarkersIfNeeded()
    }
    
    public func drawKnob() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Get the minimum dimension to determine the actual knob size
        let shortestSide = min(bounds.width, bounds.height)
        
        // Calculate the inset to account for the baseLineWidth
        // The inset is half the line width to ensure lines are fully visible
        let inset = baseLineWidth / 2
        
        // Calculate usable size (accounting for the line width)
        let usableSize = CGSize(width: shortestSide - inset * 2, height: shortestSide - inset * 2)
        
        // Calculate center point of the view
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Calculate radius from the usable size (half the shortest side minus the inset)
        let radius = usableSize.width / 2
        
        // Configure the layer bounds and positions
        // All layers should have the same bounds to ensure proper centering
        let layerBounds = CGRect(x: 0, y: 0, width: shortestSide, height: shortestSide)
        
        // Set up base layer
        baseLayer.bounds = layerBounds
        baseLayer.position = centerPoint
        baseLayer.lineWidth = baseLineWidth
        baseLayer.strokeColor = baseColor.cgColor
        baseLayer.fillColor = UIColor.clear.cgColor
        
        // Set up progress layer
        progressLayer.bounds = layerBounds
        progressLayer.position = centerPoint
        progressLayer.lineWidth = progressLineWidth
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        
        // Set up pointer layer
        pointerLayer.bounds = layerBounds
        pointerLayer.position = centerPoint
        pointerLayer.lineWidth = pointerLineWidth
        pointerLayer.strokeColor = pointerColor.cgColor
        pointerLayer.fillColor = UIColor.clear.cgColor
        
        // Calculate the center of the layer bounds for path drawing
        let layerCenter = CGPoint(x: layerBounds.width / 2, y: layerBounds.height / 2)
        
        // Draw base ring
        let ring = UIBezierPath(
            arcCenter: layerCenter,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        baseLayer.path = ring.cgPath
        baseLayer.lineCap = .round
        
        // Draw progress ring
        let angle = CGFloat(angleForValue(value))
        let progressRing = UIBezierPath(
            arcCenter: layerCenter,
            radius: radius,
            startAngle: startAngle,
            endAngle: angle,
            clockwise: true
        )
        progressLayer.path = progressRing.cgPath
        progressLayer.lineCap = .round
        
        // Draw pointer
        let pointer = UIBezierPath()
        pointer.move(to: layerCenter)
        pointer.addLine(to: CGPoint(x: layerCenter.x + radius, y: layerCenter.y))
        pointerLayer.path = pointer.cgPath
        pointerLayer.lineCap = .round
        pointerLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        
        CATransaction.commit()
    }
    
    // Movement direction enum to track axis lock
    private enum MovementDirection {
        case none
        case horizontal
        case vertical
    }
    
    // Movement detection properties
    private var accumulatedMovement: CGSize = .zero
    private var directionThreshold: CGFloat { return 0.01 * directionDetectionSensitivity } // Minimum movement required to detect direction
    private var axisRatio: CGFloat { return 2.0 * directionDetectionSensitivity } // How much stronger one axis must be vs the other
    private var directionLockEnabled = false
    
    // MARK: Rotation Gesture Recogniser
    
    // note the use of dynamic, because calling
    // private swift selectors(@ gestureRec target:action:!) gives an exception
    @objc dynamic func handleGesture(_ gesture: LiveKnobGestureRecognizer) {
        
        // Initialize movement direction for the axis-locked controls if needed
        if gesture.state == .began {
            initialMovementDirection = .none
            accumulatedMovement = .zero
            sendActions(for: .editingDidBegin)
        }
        
        // Calculate movement direction for new gesture to maintain axis lock
        if initialMovementDirection == .none && directionLockEnabled {
            
            // Accumulate movement until we're confident about the direction
            accumulatedMovement.width += gesture.diagonalChange.width
            accumulatedMovement.height += gesture.diagonalChange.height
            
            let absWidth = abs(accumulatedMovement.width)
            let absHeight = abs(accumulatedMovement.height)
            
            // Only determine direction when we have enough movement AND one axis is clearly dominant
            if (absWidth > directionThreshold || absHeight > directionThreshold) {
                if absWidth > absHeight * axisRatio {
                    initialMovementDirection = .horizontal
                    // print("Direction locked to horizontal: \(accumulatedMovement)")
                } else if absHeight > absWidth * axisRatio {
                    initialMovementDirection = .vertical
                    // print("Direction locked to vertical: \(accumulatedMovement)")
                }
                
                // If we detected a direction and it's within a small movement range,
                // reset the gesture recognizer's diagonal change to avoid initial jumps
                if initialMovementDirection != .none &&
                    (absWidth < directionThreshold * 2 && absHeight < directionThreshold * 2) {
                    gesture.resetDiagonalChange()
                }
            }
        }
        
        switch controlType {
        case .horizontal:
            value += Float(gesture.diagonalChange.width) * (maximumValue - minimumValue)
            
        case .vertical:
            value -= Float(gesture.diagonalChange.height) * (maximumValue - minimumValue)
            
        case .horizontalAndVertical:
            value += Float(gesture.diagonalChange.width) * (maximumValue - minimumValue)
            value -= Float(gesture.diagonalChange.height) * (maximumValue - minimumValue)
            
        case .coarseVerticalFineHorizontal:
            if initialMovementDirection == .horizontal {
                // Fine horizontal control
                value += Float(gesture.diagonalChange.width * fineControlSensitivity) * (maximumValue - minimumValue)
            } else if initialMovementDirection == .vertical {
                // Coarse vertical control (normal sensitivity)
                value -= Float(gesture.diagonalChange.height) * (maximumValue - minimumValue)
            }
            
        case .fineVerticalCoarseHorizontal:
            if initialMovementDirection == .horizontal {
                // Coarse horizontal control (normal sensitivity)
                value += Float(gesture.diagonalChange.width) * (maximumValue - minimumValue)
            } else if initialMovementDirection == .vertical {
                // Fine vertical control
                value -= Float(gesture.diagonalChange.height * fineControlSensitivity) * (maximumValue - minimumValue)
            }
            
        case .rotary:
            let midPointAngle = (2 * CGFloat.pi + startAngle - endAngle) / 2 + endAngle
            
            var boundedAngle = gesture.touchAngle
            if boundedAngle > midPointAngle {
                boundedAngle -= 2 * CGFloat.pi
            } else if boundedAngle < (midPointAngle - 2 * CGFloat.pi) {
                boundedAngle += 2 * CGFloat.pi
            }
            
            boundedAngle = min(endAngle, max(startAngle, boundedAngle))
            value = min(maximumValue, max(minimumValue, valueForAngle(boundedAngle)))
        }
        
        // Inform changes based on continuous behaviour of the knob.
        if continuous {
            sendActions(for: .valueChanged)
        } else {
            if gesture.state == .ended || gesture.state == .cancelled {
                sendActions(for: .valueChanged)
            }
        }
        
        if gesture.state == .ended {
            initialMovementDirection = .none
            sendActions(for: .editingDidEnd)
        }
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
    
    // MARK: Double Tap
    
    /// Configures a double tap gesture recognizer for the knob
    /// - Parameter action: The action to perform when double-tapped
    public func addDoubleTapGesture(target: Any?, action: Selector?) {
        // Remove existing double tap gesture if any
        if let existingGesture = doubleTapGestureRecognizer {
            removeGestureRecognizer(existingGesture)
        }
        
        // Create a new double tap gesture
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self // Class needs to conform to UIGestureRecognizerDelegate
        
        // Store reference and add the gesture
        doubleTapGestureRecognizer = tapGesture
        addGestureRecognizer(tapGesture)
    }
    
    // This method is crucial - it allows two gesture recognizers to work simultaneously
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                 shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow double tap to work alongside the pan gesture
        if let tapGesture = gestureRecognizer as? UITapGestureRecognizer,
           tapGesture.numberOfTapsRequired == 2 {
            return true
        }
        
        // If it's our pan gesture and the other is our double tap
        if gestureRecognizer == self.gestureRecognizer &&
           otherGestureRecognizer == doubleTapGestureRecognizer {
            return true
        }
        
        return false
    }
    
    // This method controls which gesture should be delayed while another is being analyzed
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                 shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If this is our knob's pan gesture and the other is a double tap,
        // require the double tap to fail before allowing the pan
        if gestureRecognizer == self.gestureRecognizer &&
           otherGestureRecognizer == doubleTapGestureRecognizer {
            return true
        }
        return false
    }
    
    // This method controls which gesture should wait for another to fail
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                 shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If this is our double tap and the other is our knob's pan gesture,
        // make sure the double tap gets priority
        if gestureRecognizer == doubleTapGestureRecognizer &&
           otherGestureRecognizer == self.gestureRecognizer {
            return true
        }
        return false
    }


}

// MARK: - LiveKnobGestureRecognizer

/// Custom gesture recognizer for the knob.
public class LiveKnobGestureRecognizer: UIPanGestureRecognizer {
    /// Current angle of the touch related the current progress value of the knob.
    public private(set) var touchAngle: CGFloat = 0
    /// Horizontal and vertical slide changes for the calculating current progress value of the knob.
    public private(set) var diagonalChange: CGSize = .zero
    /// Horizontal and vertical slide calculation reference.
    private var lastTouchPoint: CGPoint = .zero
    /// Horizontal and vertical slide sensitivity multiplier. Defaults 0.005.
    public var slidingSensitivity: CGFloat = 0.005
    /// Movement smoothing factor (0.0-1.0, higher = more smoothing). Defaults 0.5.
    public var movementSmoothing: CGFloat = 0.5
    /// Previous diagonal changes for smoothing
    private var previousChanges: [CGSize] = []
    /// Maximum number of previous changes to store for smoothing
    private let maxPreviousChanges = 3
    
    // MARK: UIGestureRecognizerSubclass
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
        
        // Reset smoothing data
        previousChanges.removeAll()
        
        // Update diagonal movement.
        guard let touch = touches.first else { return }
        lastTouchPoint = touch.location(in: view)
        
        // Update rotary movement.
        updateTouchAngleWithTouches(touches)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        state = .changed
        
        // Update diagonal movement.
        guard let touchPoint = touches.first?.location(in: view) else { return }
        
        // Calculate raw movement
        let rawChangeWidth = (touchPoint.x - lastTouchPoint.x) * slidingSensitivity
        let rawChangeHeight = (touchPoint.y - lastTouchPoint.y) * slidingSensitivity
        
        // Apply smoothing to reduce jitter and improve direction detection
        let rawChange = CGSize(width: rawChangeWidth, height: rawChangeHeight)
        previousChanges.append(rawChange)
        
        // Keep only a limited history of changes
        if previousChanges.count > maxPreviousChanges {
            previousChanges.removeFirst()
        }
        
        // Apply smoothing algorithm (weighted average)
        var smoothedChange = CGSize.zero
        var totalWeight: CGFloat = 0
        
        for (index, change) in previousChanges.enumerated() {
            let weight = CGFloat(index + 1)
            smoothedChange.width += change.width * weight
            smoothedChange.height += change.height * weight
            totalWeight += weight
        }
        
        if totalWeight > 0 {
            diagonalChange.width = smoothedChange.width / totalWeight
            diagonalChange.height = smoothedChange.height / totalWeight
        } else {
            diagonalChange = rawChange
        }
        
        // Reset last touch point.
        lastTouchPoint = touchPoint
        
        // Update rotary movement.
        updateTouchAngleWithTouches(touches)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
        
        // Reset tracking values
        previousChanges.removeAll()
        diagonalChange = .zero
    }
    
    /// Resets the diagonal change to prevent jumps when direction is first detected
    public func resetDiagonalChange() {
        diagonalChange = .zero
        previousChanges.removeAll()
    }
    
    private func updateTouchAngleWithTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        touchAngle = calculateAngleToPoint(touchPoint)
    }
    
    private func calculateAngleToPoint(_ point: CGPoint) -> CGFloat {
        let centerOffset = CGPoint(x: point.x - view!.bounds.midX, y: point.y - view!.bounds.midY)
        return atan2(centerOffset.y, centerOffset.x)
    }
    
    // MARK: Lifecycle
    
    public init() {
        super.init(target: nil, action: nil)
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }
}

// MARK: - Markers

extension LiveKnob {
    
    func refreshMarkersIfNeeded() {
        for sub in subviews {
            if sub is LiveKnobMarker {
                sub.removeFromSuperview()
            }
        }
        for marker in markers {
            addSubview(marker)
        }
    }
    
    func layoutMarkersIfNeeded() {
        let shortestSide = min(bounds.width, bounds.height)
        let inset = baseLineWidth / 2
        
        // Calculate radius for marker positioning
        // This uses the same radius calculation as in drawKnob
        let knobRadius = (shortestSide - inset * 2) / 2
        
        for (index, marker) in markers.enumerated() {
            let angle = radians(from: self.angle(for: marker, at: index))
            
            let x = cos(angle)
            let y = sin(angle)
            
            marker.transform = .identity
            var rect = marker.frame
            
            // Position the marker outside the knob with the correct offset
            let markerRadius = knobRadius + marker.markerOffset
            
            // Calculate the position relative to the view's center
            let newX = CGFloat(x) * markerRadius + bounds.midX
            let newY = CGFloat(y) * markerRadius + bounds.midY
            
            // Adjust marker position (centered on the calculated point)
            rect.origin.x = newX - marker.frame.width / 2
            rect.origin.y = newY - marker.frame.height / 2
            marker.frame = rect
            
            // Apply custom transform or rotate to match the angle
            marker.transform = marker.markerTransform ?? CGAffineTransform(rotationAngle: angle)
        }
    }
    
    func angle(for marker: UIView, at index: Int) -> Float {
        let percentage: Float = ((100.0 / Float(markers.count - 1)) * Float(index)) / 100.0
        return degrees(for: percentage, from: degrees(from: startAngle), to: degrees(from: endAngle))
    }
    
    func degrees(for percentage: Float, from startAngle: Float, to endAngle: Float) -> Float {
        if endAngle > startAngle {
            return startAngle + (endAngle - startAngle) * percentage
        } else {
            return startAngle + (360.0 + endAngle - startAngle) * percentage
        }
    }
    
    public func degrees(from radian: CGFloat) -> Float {
        return degrees(from: Float(radian))
    }
    
    public func degrees(from radian: Float) -> Float {
        return radian * (180 / Float.pi)
    }
    
    func radians(from degree: Float) -> CGFloat {
        return radians(from: CGFloat(degree))
    }
    
    func radians(from degree: CGFloat) -> CGFloat {
        return degree * .pi / 180
    }
}
