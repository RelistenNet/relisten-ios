//
//  NapySlider.swift
//  NapySlider
//
//  Created by Jonas Schoch on 12.12.15.
//  Copyright © 2015 naptics. All rights reserved.
//

import UIKit

@IBDesignable
open class NapySlider: UIControl {
    
    // internal variables, our views
    internal var backgroundView: UIView!
    internal var titleBackgroundView: UIView!
    internal var sliderView: UIView!
    internal var sliderBackgroundView: UIView!
    internal var sliderFillView: UIView!
    internal var handleView: UIView!
    internal var currentPosTriangle: TriangleView!
    
    internal var titleLabel: UILabel!
    internal var handleLabel: UILabel!
    internal var currentPosLabel: UILabel!
    internal var maxLabel: UILabel!
    internal var minLabel: UILabel!

    internal var isFloatingPoint: Bool {
        get { return step.truncatingRemainder(dividingBy: 1) != 0 ? true : false }
    }

    // public variables
    @IBInspectable public var titleHeight: CGFloat = 30
    @IBInspectable public var sliderWidth: CGFloat = 20
    @IBInspectable public var handleHeight: CGFloat = 20
    @IBInspectable public var handleWidth: CGFloat = 50
    @IBInspectable public var sliderPaddingTop:CGFloat = 25
    @IBInspectable public var sliderPaddingBottom:CGFloat = 20
    
    // public inspectable variables
    @IBInspectable public var title: String = "Hello" {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBInspectable public var min: Double = 0 {
        didSet {
            minLabel.text = textForPosition(min)
        }
    }
    
    @IBInspectable public var max: Double = 10 {
        didSet {
            maxLabel.text = textForPosition(max)
        }
    }
    
    @IBInspectable public var step: Double = 1
    
    // colors
    @IBInspectable public var handleColor: UIColor = UIColor.gray
    @IBInspectable public var mainBackgroundColor: UIColor = UIColor.groupTableViewBackground
    @IBInspectable public var titleBackgroundColor: UIColor = UIColor.lightGray
    @IBInspectable public var sliderUnselectedColor: UIColor = UIColor.lightGray
    
    /**
     the position of the handle. The handle moves animated when setting the variable
    */
    open var handlePosition:Double {
        set (newHandlePosition) {
            moveHandleToPosition(newHandlePosition, animated: true)
        }
        get {
            let currentY = handleView.frame.origin.y + handleHeight/2
            let positionFromMin = -(Double(currentY) - minPosition - stepheight/2) / stepheight
            
            // add an offset if slider should go to a negative value
            var stepOffset:Double = 0
            if min < 0 {
            let zeroPosition = (0 - min)/Double(step) + 0.5
                if positionFromMin < zeroPosition {
                    stepOffset = 0 - step
                }
            }
            
//            let position = Int((positionFromMin * step + min + stepOffset) / step) * Int(step)
            let position = Double(Int((positionFromMin * step + min + stepOffset) / step)) * step
            return Double(position)
        }
    }
    
    open var disabled:Bool = false {
        didSet {
            sliderBackgroundView.alpha = disabled ? 0.4 : 1.0
            self.isUserInteractionEnabled = !disabled
        }
    }
    
    
    fileprivate var steps: Int {
        get {
            if (min == max || step == 0) {
                return 1
            } else {
                return Int(round((max - min) / step)) + 1
            }
        }
    }
    
    fileprivate var maxPosition:Double {
        get {
            return 0
        }
    }
    
    fileprivate var minPosition:Double {
        get {
            return Double(sliderView.frame.height)
        }
    }
    
    
    fileprivate var stepheight:Double {
        get {
            return (minPosition - maxPosition) / Double(steps - 1)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    fileprivate func setup() {
        backgroundView = UIView()
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        
        titleBackgroundView = UIView()
        addSubview(titleBackgroundView)
        
        titleLabel = UILabel()
        titleBackgroundView.addSubview(titleLabel)
        
        sliderBackgroundView = UIView()
        sliderBackgroundView.isUserInteractionEnabled = false
        backgroundView.addSubview(sliderBackgroundView)
        
        sliderFillView = UIView()
        sliderFillView.isUserInteractionEnabled = false
        sliderBackgroundView.addSubview(sliderFillView)
        
        sliderView = UIView()
        sliderView.isUserInteractionEnabled = false
        sliderBackgroundView.addSubview(sliderView)
        
        handleView = UIView()
        handleView.isUserInteractionEnabled = false
        sliderView.addSubview(handleView)
        
        handleLabel = UILabel()
        handleView.addSubview(handleLabel)
        
        minLabel = UILabel()
        backgroundView.addSubview(minLabel)
        
        maxLabel = UILabel()
        backgroundView.addSubview(maxLabel)
        
        currentPosLabel = UILabel()
        sliderBackgroundView.addSubview(currentPosLabel)
        
        currentPosTriangle = TriangleView()
        currentPosLabel.addSubview(currentPosTriangle)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.frame = CGRect(x: 0, y: titleHeight, width: frame.size.width, height: frame.size.height - titleHeight)
        backgroundView.backgroundColor = mainBackgroundColor
        
        titleBackgroundView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: titleHeight)
        titleBackgroundView.backgroundColor = titleBackgroundColor
        
        titleLabel.frame = CGRect(x: 0, y: 0, width: titleBackgroundView.frame.width, height: titleBackgroundView.frame.height)
        titleLabel.text = title
        titleLabel.textColor = handleColor
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        titleLabel.textAlignment = NSTextAlignment.center
        
        sliderBackgroundView.frame = CGRect(x: backgroundView.frame.width/2 - sliderWidth/2, y: sliderPaddingTop, width: sliderWidth, height: backgroundView.frame.height - (sliderPaddingTop + sliderPaddingBottom))
        sliderBackgroundView.backgroundColor = sliderUnselectedColor
        
        sliderView.frame = CGRect(x: 0, y: sliderWidth/2, width: sliderBackgroundView.frame.width, height: sliderBackgroundView.frame.height - sliderWidth)
        sliderView.backgroundColor = UIColor.clear
        
        handleView.frame = CGRect(x: -(handleWidth-sliderWidth)/2, y: sliderView.frame.height/2 - handleHeight/2, width: handleWidth, height: handleHeight)
        handleView.backgroundColor = handleColor
        
        sliderFillView.frame = CGRect(x: 0, y: handleView.frame.origin.y + handleHeight, width: sliderBackgroundView.frame.width, height: sliderBackgroundView.frame.height-handleView.frame.origin.y - handleHeight)
        sliderFillView.backgroundColor = tintColor
        
        /*
        handleLabel.frame = CGRect(x: 0, y: 0, width: handleWidth, height: handleHeight)
        handleLabel.text = ""
        handleLabel.textAlignment = NSTextAlignment.center
        handleLabel.textColor = UIColor.white
        handleLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.bold)
        handleLabel.backgroundColor = UIColor.clear
        handleLabel.adjustsFontSizeToFitWidth = true
        */
 
        minLabel.frame = CGRect(x: 0, y: backgroundView.frame.height-sliderPaddingBottom, width: backgroundView.frame.width, height: sliderPaddingBottom)
        minLabel.text = textForPosition(min)
        minLabel.textAlignment = NSTextAlignment.center
        minLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.regular)
        minLabel.textColor = handleColor
        
        maxLabel.frame = CGRect(x: 0, y: 0, width: backgroundView.frame.width, height: sliderPaddingTop)
        maxLabel.text = textForPosition(max)
        maxLabel.textAlignment = NSTextAlignment.center
        maxLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.regular)
        maxLabel.textColor = handleColor
        
        currentPosLabel.frame = CGRect(x: handleView.frame.width, y: handleView.frame.origin.y + handleHeight*0.5/2, width: handleWidth, height: handleHeight * 1.5)
        currentPosLabel.text = ""
        currentPosLabel.textAlignment = NSTextAlignment.center
        currentPosLabel.textColor = UIColor.white
        handleLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.bold)
        currentPosLabel.backgroundColor = tintColor
        currentPosLabel.alpha = 0.0
        
        currentPosTriangle.frame = CGRect(x: -10, y: 10, width: currentPosLabel.frame.height-20, height: currentPosLabel.frame.height-20)
        currentPosTriangle.tintColor = tintColor
        currentPosTriangle.backgroundColor = UIColor.clear
    }

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.currentPosLabel.alpha = 1.0
        })
        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        let _ = handlePosition
        let point = touch.location(in: sliderView)
        moveHandleToPoint(point)

        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        
        let endPosition = handlePosition
        handlePosition = endPosition
        handleLabel.text = textForPosition(handlePosition)

        UIView.animate(withDuration: 0.3, animations: {
            self.currentPosLabel.alpha = 0.0
        })
    }

    open override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
    }
    
    
    fileprivate func moveHandleToPoint(_ point:CGPoint) {
        var newY:CGFloat
        
        newY = point.y - CGFloat(handleView.frame.height/2)
        
        if newY < -handleHeight/2 {
            newY = -handleHeight/2
        } else if newY > sliderView.frame.height - handleHeight/2 {
            newY = sliderView.frame.height - handleHeight/2
        }
        
        handleView.frame.origin.y = CGFloat(newY)
        sliderFillView.frame = CGRect(x: 0 , y: CGFloat(newY) + handleHeight, width: sliderBackgroundView.frame.width, height: sliderBackgroundView.frame.height-handleView.frame.origin.y - handleHeight)
        
        let newText = textForPosition(handlePosition)
        if handleLabel.text != newText {
            handleLabel.text = newText
            currentPosLabel.text = newText
        }

        currentPosLabel.sizeToFit()
        
        currentPosLabel.frame = CGRect(x: handleView.frame.width + 10, y: handleView.frame.origin.y + handleHeight*0.5/2, width: currentPosLabel.frame.width + 16, height: currentPosLabel.frame.height + 16)
        
        currentPosTriangle.frame = CGRect(x: -10, y: currentPosLabel.frame.height / 2.0 - 10, width: 20, height: 20)
    }
    
    fileprivate func moveHandleToPosition(_ position:Double, animated:Bool = false) {
        if step == 0 { return }

        var goPosition = position
        
        if position >= max { goPosition = max }
        if position <= min { goPosition = min }
        
        let positionFromMin = (goPosition - min) / step
        
        let newY = CGFloat(minPosition - positionFromMin * stepheight)
        
        let changes = {
            self.currentPosLabel.sizeToFit()
            
            self.handleView.frame.origin.y = newY - self.handleHeight/2
            self.sliderFillView.frame = CGRect(x: 0 , y: CGFloat(newY) + self.handleHeight/2, width: self.sliderBackgroundView.frame.width, height: self.sliderBackgroundView.frame.height - self.handleView.frame.origin.y - self.handleHeight)
            self.currentPosLabel.frame = CGRect(x: self.handleView.frame.width + 10, y: self.handleView.frame.origin.y + self.handleHeight*0.5/2, width: self.currentPosLabel.frame.width + 16, height: self.currentPosLabel.frame.height + 16)
            
            self.currentPosTriangle.frame = CGRect(x: -10, y: self.currentPosLabel.frame.height / 2.0 - 10, width: 20, height: 20)
        }
        
        let newText = textForPosition(position)
        if handleLabel.text != newText {
            handleLabel.text = newText
            currentPosLabel.text = newText
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: changes)
        } else {
            changes()
        }

        self.sendActions(for: .valueChanged)
    }
    
    fileprivate func textForPosition(_ position:Double) -> String {
        if isFloatingPoint { return String(format: "%0.1f", arguments: [position]) }
        else { return String(format: "%0.0f", arguments: [position]) }
    }
}


class TriangleView : UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        
        let ctx : CGContext = UIGraphicsGetCurrentContext()!
        
        ctx.beginPath()
        ctx.move(to: CGPoint(x: rect.minX, y: rect.maxY/2.0))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        ctx.closePath()
        
        ctx.setFillColor(tintColor.cgColor)
        ctx.fillPath()
    }
}
