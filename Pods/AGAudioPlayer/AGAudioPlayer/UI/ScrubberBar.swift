//
//  Copyright © 2015 Squareheads. All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public protocol ScrubberBarDelegate: class {
    func scrubberBar(bar: ScrubberBar, didScrubToProgress: Float, finished: Bool)
}

public extension Comparable {
    func clamped<T: Comparable>(lower: T, upper: T) -> T {
        let value = self as! T
        return min(max(value, lower), upper)
    }
}

@IBDesignable
public class ScrubberBar: UIControl {
    
    @IBInspectable
    public var scrubberWidth: Float = 4.0{
        didSet{
            setNeedsLayout()
        }
    }
    
    @IBInspectable
    public var dragIndicatorColor: UIColor = .lightGray {
        didSet{
            setupColor()
        }
    }
    
    @IBInspectable
    public var barColor: UIColor = .lightGray {
        didSet{
            setupColor()
        }
    }
    
    @IBInspectable
    public var elapsedColor: UIColor = .darkGray {
        didSet{
            setupColor()
        }
    }
    
    @IBInspectable
    public var verticalBarScale: Float = 1.0{
        didSet{
            setNeedsLayout()
        }
    }
    
    @IBInspectable
    public var scrubbingEnabled: Bool = true
    
    @IBInspectable
    public var showDragArea: Bool = true{
        didSet{
            setNeedsLayout()
        }
    }
    
    private var progress: Float = 0.0
    
    let draggerButton = UIButton(frame: CGRect.zero)
    let topBar = UIView(frame: CGRect.zero)
    let elapsedBar = UIView(frame: CGRect.zero)
    var isDragging = false
    public weak var delegate: ScrubberBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        commonSetup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }
    
    public func setProgress(progress: Float){
        if !isDragging {
            self.progress = progress
            setNeedsLayout()
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        commonSetup()
    }
    
    func commonSetup(){
        setupColor()
        addSubviews()
        addTouchHandlers()
    }
    
    func setupColor(){
        backgroundColor = .clear
        draggerButton.backgroundColor = dragIndicatorColor
        topBar.backgroundColor = barColor
        elapsedBar.backgroundColor = elapsedColor
    }
    
    func addSubviews(){
        addSubview(topBar)
        addSubview(elapsedBar)
        addSubview(draggerButton)
    }
    
    func addTouchHandlers(){
        draggerButton.isUserInteractionEnabled = false
        topBar.isUserInteractionEnabled = false
        elapsedBar.isUserInteractionEnabled = false
        addTarget(self, action: .touchStarted, for: .touchDown)
        addTarget(self, action: .touchEnded, for: .touchUpInside)
        addTarget(self, action: .touchMoved, for: .touchDragInside)
        addTarget(self, action: .touchCancel, for: .touchCancel)
    }
    
    func positionFromProgress(progress: Float) -> Float{
        return ((Float(frame.width) * progress) - scrubberWidth).clamped(lower: scrubberWidth, upper: Float(frame.width) - scrubberWidth);
    }
    
    func progressFromPosition(position: Float) -> Float{
        return (position / Float(frame.width)).clamped(lower: 0, upper: 1)
    }
    
    public override func layoutSubviews(){
        super.layoutSubviews()
        let horizontalPosition = positionFromProgress(progress: progress)
        
        let alignToLeft = progress == 0 || CGFloat(progress) * frame.width < CGFloat(scrubberWidth)
        
        draggerButton.frame = CGRect(x: alignToLeft ? 0.0 : CGFloat(horizontalPosition), y: 12, width: CGFloat(scrubberWidth), height: frame.height - 12 * 2)
        draggerButton.isHidden = !showDragArea
        let barDivisor: CGFloat = CGFloat(1.0) / CGFloat(verticalBarScale)
        
        let centerY = CGFloat(frame.height - (frame.height / barDivisor)) / 2
        
        topBar.frame = CGRect(x: 0, y: centerY, width: frame.width, height: frame.height / barDivisor)
        elapsedBar.frame = CGRect(x: 0, y: centerY, width: CGFloat(horizontalPosition), height: frame.height / barDivisor)
    }
    
    @objc func touchStarted(){
        isDragging = true
    }
    
    @objc func touchEnded(){
        isDragging = false
        
        delegate?.scrubberBar(bar: self, didScrubToProgress: self.progress, finished: true)
    }
    
    @objc func touchCancel() {
        isDragging = false

        delegate?.scrubberBar(bar: self, didScrubToProgress: self.progress, finished: true)
    }
    
    @objc func touchMoved(object: AnyObject, event:UIEvent){
        if let touch = event.touches(for: self)?.first, scrubbingEnabled == true {
            let pointInView = touch.location(in: self)
            let progress = progressFromPosition(position: Float(pointInView.x))
            self.progress = progress
            delegate?.scrubberBar(bar: self, didScrubToProgress: self.progress, finished: false)
            setNeedsLayout()
        }
    }
}


private extension Selector {
    static let touchStarted = #selector(ScrubberBar.touchStarted)
    static let touchEnded =  #selector(ScrubberBar.touchEnded)
    static let touchMoved =  #selector(ScrubberBar.touchMoved(object:event:))
    static let touchCancel =  #selector(ScrubberBar.touchCancel)
}
