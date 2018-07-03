//
//  AGAudioPlayerViewController.swift
//  AGAudioPlayer
//
//  Created by Alec Gorge on 1/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import QuartzCore
import MediaPlayer

import Interpolate
import MarqueeLabel
import BCColor
import NapySlider

public struct AGAudioPlayerColors {
    let main: UIColor
    let accent: UIColor
    let accentWeak: UIColor
    
    let barNothing: UIColor
    let barDownloads: UIColor
    let barPlaybackElapsed: UIColor
    let scrubberHandle: UIColor
    
    public init() {
        let main = UIColor(red:0.149, green:0.608, blue:0.737, alpha:1)
        let accent = UIColor.white

        self.init(main: main, accent: accent)
    }
    
    public init(main: UIColor, accent: UIColor) {
        self.main = main
        self.accent = accent
        
        accentWeak = accent.withAlphaComponent(0.7)
        
        barNothing = accent.withAlphaComponent(0.3)
        barDownloads = accent.withAlphaComponent(0.4)
        barPlaybackElapsed = accent
        scrubberHandle = accent
    }
}

@objc public class AGAudioPlayerViewController: UIViewController {

    @IBOutlet var uiPanGestureClose: VerticalPanDirectionGestureRecognizer!
    @IBOutlet var uiPanGestureOpen: VerticalPanDirectionGestureRecognizer!
    
    @IBOutlet weak var uiTable: UITableView!
    @IBOutlet weak var uiHeaderView: UIView!
    
    @IBOutlet weak var uiFooterView: UIView!
    @IBOutlet weak var uiProgressDownload: UIView!
    @IBOutlet weak var uiProgressDownloadCompleted: UIView!
    
    @IBOutlet weak var uiScrubber: ScrubberBar!
    @IBOutlet weak var uiProgressDownloadCompletedContraint: NSLayoutConstraint!
    
    @IBOutlet weak var uiLabelTitle: MarqueeLabel!
    @IBOutlet weak var uiLabelSubtitle: MarqueeLabel!
    @IBOutlet weak var uiLabelElapsed: UILabel!
    @IBOutlet weak var uiLabelDuration: UILabel!
    
    @IBOutlet weak var uiButtonShuffle: UIButton!
    @IBOutlet weak var uiButtonPrevious: UIButton!
    @IBOutlet weak var uiButtonPlay: UIButton!
    @IBOutlet weak var uiButtonPause: UIButton!
    @IBOutlet weak var uiButtonNext: UIButton!
    @IBOutlet weak var uiButtonLoop: UIButton!
    @IBOutlet weak var uiButtonDots: UIButton!
    @IBOutlet weak var uiButtonPlus: UIButton!
    @IBOutlet weak var uiSliderVolume: MPVolumeView!
    @IBOutlet weak var uiSpinnerBuffering: UIActivityIndicatorView!
    
    @IBOutlet weak var uiWrapperEq: UIView!
    @IBOutlet weak var uiSliderEqBass: NapySlider!
    
    @IBOutlet weak var uiConstraintTopTitleSpace: NSLayoutConstraint!
    @IBOutlet weak var uiConstraintSpaceBetweenPlayers: NSLayoutConstraint!
    @IBOutlet weak var uiConstraintBottomBarHeight: NSLayoutConstraint!
    
    // mini player
    @IBOutlet weak var uiMiniPlayerContainerView: UIView!
    
    public var barHeight : CGFloat {
        get {
            if let c = uiMiniPlayerContainerView {
                var extra: CGFloat = UIApplication.shared.keyWindow!.rootViewController!.view.safeAreaInsets.bottom
                
                return c.bounds.height + extra
            }
            return 64.0
        }
    }
    
    @IBOutlet weak var uiMiniPlayerTopOffsetConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var uiMiniProgressDownloadCompletedView: UIView!
    @IBOutlet weak var uiMiniProgressDownloadCompletedConstraint: NSLayoutConstraint!
    @IBOutlet weak var uiMiniProgressPlayback: UIProgressView!
    
    @IBOutlet weak var uiMiniButtonPlay: UIButton!
    @IBOutlet weak var uiMiniButtonPause: UIButton!

    @IBOutlet weak var uiMiniLabelTitle: MarqueeLabel!
    @IBOutlet weak var uiMiniLabelSubtitle: MarqueeLabel!
    
    @IBOutlet weak var uiMiniButtonDots: UIButton!
    @IBOutlet weak var uiMiniButtonPlus: UIButton!
    @IBOutlet weak var uiMiniSpinnerBuffering: UIActivityIndicatorView!
    // end mini player
    
    public var presentationDelegate: AGAudioPlayerViewControllerPresentationDelegate? = nil
    public var cellDataSource: AGAudioPlayerViewControllerCellDataSource? = nil
    public var delegate: AGAudioPlayerViewControllerDelegate? = nil
    
    public var shouldPublishToNowPlayingCenter: Bool = true
    
    var remoteCommandManager : RemoteCommandManager? = nil

    var dismissInteractor: DismissInteractor = DismissInteractor()
    var openInteractor: OpenInteractor = OpenInteractor()
    
    // colors
    var colors = AGAudioPlayerColors()
    
    // constants
    let SectionQueue = 0
    
    // bouncy header
    var headerInterpolate: Interpolate?
    var interpolateBlock: ((_ scale: Double) -> Void)?
    
    // swipe to dismiss
    static let defaultTransitionDelegate = AGAudioPlayerViewControllerTransitioningDelegate()
    
    // non-jumpy seeking
    var isCurrentlyScrubbing = false
    
    // for delegate notifications
    var lastSeenProgress: Float? = nil
    
    let player: AGAudioPlayer
    
    required public init(player: AGAudioPlayer) {
        self.player = player
        
        let bundle = Bundle(path: Bundle(for: AGAudioPlayerViewController.self).path(forResource: "AGAudioPlayer", ofType: "bundle")!)
        super.init(nibName: String(describing: AGAudioPlayerViewController.self), bundle: bundle)
        
        self.transitioningDelegate = AGAudioPlayerViewController.defaultTransitionDelegate
        
        setupPlayer()
        
        dismissInteractor.viewController = self
        openInteractor.viewController = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        setupStretchyHeader()
        setupColors()
        setupPlayerUiActions()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppear_StretchyHeader()
        viewWillAppear_Table()
        updateUI()
        
        uiSliderVolume.isHidden = false
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        uiSliderVolume.isHidden = true
    }
}

extension AGAudioPlayerViewController : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let pt = touch.location(in: uiHeaderView)
        
        return uiHeaderView.frame.contains(pt);
    }
}

extension AGAudioPlayerViewController : AGAudioPlayerDelegate {
    func setupPlayer() {
        player.delegate = self
    }
    
    public func audioPlayerAudioSessionSetUp(_ audioPlayer: AGAudioPlayer) {
        remoteCommandManager = RemoteCommandManager(player: audioPlayer)
        
        remoteCommandManager?.activatePlaybackCommands(true)
    }
    
    func updateUI() {
        updatePlayPauseButtons()
        updateShuffleLoopButtons()
        updateNonTimeLabels()
        updateTimeLabels()
        updatePlaybackProgress()
        updatePreviousNextButtons()
    }
    
    func updatePlayPauseButtons() {
        guard uiButtonPause != nil, uiButtonPlay != nil,
            uiMiniButtonPause != nil, uiMiniButtonPlay != nil,
            uiSpinnerBuffering != nil, uiMiniSpinnerBuffering != nil else {
            return
        }
        
        if player.isBuffering {
            uiButtonPause.isHidden = true
            uiButtonPlay.isHidden = true
            
            uiMiniButtonPause.isHidden = true
            uiMiniButtonPlay.isHidden = true
            
            uiMiniSpinnerBuffering.isHidden = false
            uiSpinnerBuffering.isHidden = false
            
            return
        }
        
        uiMiniSpinnerBuffering.isHidden = true
        uiSpinnerBuffering.isHidden = true
        
        uiButtonPause.isHidden = !player.isPlaying && !player.isBuffering
        uiButtonPlay.isHidden = player.isPlaying
        
        uiMiniButtonPause.isHidden = uiButtonPause.isHidden
        uiMiniButtonPlay.isHidden = uiButtonPlay.isHidden
    }
    
    func updatePreviousNextButtons() {
        guard uiButtonPrevious != nil, uiButtonNext != nil else {
            return
        }

        uiButtonPrevious.isEnabled = !player.isPlayingFirstItem
        uiButtonNext.isEnabled = !player.isPlayingLastItem
    }
    
    func updateShuffleLoopButtons() {
        guard uiButtonShuffle != nil, uiButtonLoop != nil else {
            return
        }
        
        uiButtonLoop.alpha = player.loopItem ? 1.0 : 0.7
        uiButtonShuffle.alpha = player.shuffle ? 1.0 : 0.7
    }
    
    func updateNonTimeLabels() {
        guard uiLabelTitle != nil, uiLabelSubtitle != nil, uiMiniLabelTitle != nil, uiLabelSubtitle != nil else {
            return
        }
        
        if let cur = player.currentItem {
            uiLabelTitle.text = cur.displayText
            uiLabelSubtitle.text = cur.displaySubtext
            
            uiMiniLabelTitle.text = cur.displayText
            uiMiniLabelSubtitle.text = cur.displaySubtext
        }
    }
    
    func updateTimeLabels() {
        guard uiLabelElapsed != nil, uiLabelDuration != nil else {
            return
        }
        
        uiLabelElapsed.text = player.elapsed.formatted()
        uiLabelDuration.text = player.duration.formatted()
    }
    
    func updatePlaybackProgress() {
        guard uiScrubber != nil, uiMiniProgressPlayback != nil else {
            return
        }

        if !isCurrentlyScrubbing {
            let floatProgress = Float(player.percentElapsed)
            
            uiScrubber.setProgress(progress: floatProgress)
            uiMiniProgressPlayback.progress = floatProgress
            
            updateTimeLabels()
            
            // send this delegate once when it goes past 50%
            if let lastProgress = lastSeenProgress, lastProgress < 0.5, floatProgress >= 0.5, let item = player.currentItem {
                delegate?.audioPlayerViewController(self, passedHalfWayFor: item)
            }
            
            lastSeenProgress = floatProgress
        }
    }
    
    func updateDownloadProgress(pct: Double) {
        guard uiProgressDownloadCompletedContraint != nil, uiMiniProgressDownloadCompletedConstraint != nil else {
            return
        }
        
        var p = pct
        if p > 0.98 {
            p = 1.0
        }
        
        uiProgressDownloadCompletedContraint = uiProgressDownloadCompletedContraint.setMultiplier(multiplier: CGFloat(p))
        uiProgressDownload.layoutIfNeeded()
        
        uiMiniProgressDownloadCompletedConstraint = uiMiniProgressDownloadCompletedConstraint.setMultiplier(multiplier: CGFloat(p))
        uiMiniPlayerContainerView.layoutIfNeeded()
        
        uiMiniProgressDownloadCompletedView.isHidden = p == 0.0
    }
    
    public func audioPlayer(_ audioPlayer: AGAudioPlayer, uiNeedsRedrawFor reason: AGAudioPlayerRedrawReason) {
        publishToNowPlayingCenter()
        
        switch reason {
        case .buffering, .playing:
            updatePlayPauseButtons()
            delegate?.audioPlayerViewController(self, trackChangedState: player.currentItem)
            uiTable.reloadData()
            
        case .stopped:
            uiLabelTitle.text = ""
            uiLabelSubtitle.text = ""
            
            uiMiniLabelTitle.text = ""
            uiMiniLabelSubtitle.text = ""
            
            fallthrough
            
        case .paused, .error:
            updatePlayPauseButtons()
            delegate?.audioPlayerViewController(self, trackChangedState: player.currentItem)
            uiTable.reloadData()
            
        case .trackChanged:
            updatePreviousNextButtons()
            updateNonTimeLabels()
            updateTimeLabels()
            uiTable.reloadData()
            delegate?.audioPlayerViewController(self, changedTrackTo: player.currentItem)
        
        case .queueChanged:
            uiTable.reloadData()
            
        default:
            break
        }
    }
    
    public func audioPlayer(_ audioPlayer: AGAudioPlayer, errorRaised error: Error, for url: URL) {
        print("CRAP")
        print(error)
        print(url)
        
        publishToNowPlayingCenter()
    }
    
    public func audioPlayer(_ audioPlayer: AGAudioPlayer, downloadedBytesForActiveTrack downloadedBytes: UInt64, totalBytes: UInt64) {
        guard uiProgressDownloadCompleted != nil else {
            return
        }
        
        let progress = Double(downloadedBytes) / Double(totalBytes)
        
        updateDownloadProgress(pct: progress)
    }
    
    public func audioPlayer(_ audioPlayer: AGAudioPlayer, progressChanged elapsed: TimeInterval, withTotalDuration totalDuration: TimeInterval) {
        updatePlaybackProgress()
        
        publishToNowPlayingCenter()
    }
    
    public func publishToNowPlayingCenter() {
        guard shouldPublishToNowPlayingCenter else {
            return
        }
        
        if let item = player.currentItem {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyMediaType        : NSNumber(value: MPMediaType.music.rawValue),

                MPMediaItemPropertyTitle            : item.title,
                MPMediaItemPropertyAlbumArtist      : item.artist,
                MPMediaItemPropertyArtist           : item.artist,
                MPMediaItemPropertyAlbumTitle       : item.album,
                
                MPMediaItemPropertyPlaybackDuration : NSNumber(value: item.duration),
                MPMediaItemPropertyAlbumTrackNumber : NSNumber(value: item.trackNumber),
                
                // MPNowPlayingInfoPropertyDefaultPlaybackRate : NSNumber(value: 1.0),
                MPNowPlayingInfoPropertyElapsedPlaybackTime : NSNumber(value: player.elapsed),
                
                MPNowPlayingInfoPropertyPlaybackProgress    : NSNumber(value: Float(player.percentElapsed)),
                MPNowPlayingInfoPropertyPlaybackQueueCount  : NSNumber(value: player.queue.count),
                MPNowPlayingInfoPropertyPlaybackQueueIndex  : NSNumber(value: player.currentIndex),
                MPNowPlayingInfoPropertyPlaybackRate        : NSNumber(value: player.isPlaying ? 1.0 : 0.0)
            ]
        }
        else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
}

extension AGAudioPlayerViewController : ScrubberBarDelegate {
    func setupPlayerUiActions() {
        uiScrubber.delegate = self
        
        uiLabelTitle.trailingBuffer = 32
        uiLabelSubtitle.trailingBuffer = 24
        
        // uiLabelTitle.animationDuration = 2
        uiLabelTitle.animationDelay = 5
        uiLabelTitle.rate = 25
        
        uiLabelSubtitle.animationDelay = 5
        uiLabelSubtitle.rate = 25
        
        uiLabelTitle.isUserInteractionEnabled = true
        uiLabelSubtitle.isUserInteractionEnabled = true
        
        // mini player
        uiMiniLabelTitle.trailingBuffer = 24
        uiMiniLabelSubtitle.trailingBuffer = 16
        
        uiMiniLabelTitle.animationDelay = 5
        uiMiniLabelTitle.rate = 16
        
        uiMiniLabelSubtitle.animationDelay = 5
        uiMiniLabelSubtitle.rate = 16
        
        uiMiniLabelTitle.isUserInteractionEnabled = true
        uiMiniLabelSubtitle.isUserInteractionEnabled = true
        
        updateDownloadProgress(pct: 0.0)
        updatePlaybackProgress()
    }
    
    public func scrubberBar(bar: ScrubberBar, didScrubToProgress: Float, finished: Bool) {
        isCurrentlyScrubbing = !finished
        
        if let elapsed = uiLabelElapsed, let mp = uiMiniProgressPlayback {
            elapsed.text = TimeInterval(player.duration * Double(didScrubToProgress)).formatted()
            mp.progress = didScrubToProgress
        }
        
        if finished {
            player.seek(toPercent: CGFloat(didScrubToProgress))
        }
    }
    
    @IBAction func uiActionToggleShuffle(_ sender: UIButton) {
        player.shuffle = !player.shuffle
        
        updateShuffleLoopButtons()
        uiTable.reloadData()
        updatePreviousNextButtons()
    }
    
    @IBAction func uiActionToggleLoop(_ sender: UIButton) {
        player.loopItem = !player.loopItem
        
        updateShuffleLoopButtons()
    }
    
    @IBAction func uiActionPrevious(_ sender: UIButton) {
        player.backward()
    }
    
    @IBAction func uiActionPlay(_ sender: UIButton) {
        player.resume()
    }
    
    @IBAction func uiActionPause(_ sender: UIButton) {
        player.pause()
    }

    @IBAction func uiActionNext(_ sender: UIButton) {
        player.forward()
    }
    
    @IBAction func uiActionDots(_ sender: UIButton) {
        if let item = self.player.currentItem {
            delegate?.audioPlayerViewController(self, pressedDotsForAudioItem: item)
        }
    }
    
    @IBAction func uiActionPlus(_ sender: UIButton) {
        if let item = self.player.currentItem {
            delegate?.audioPlayerViewController(self, pressedPlusForAudioItem: item)
        }
    }
    
    @IBAction func uiOpenFullUi(_ sender: UIButton) {
        self.presentationDelegate?.fullPlayerRequested()
    }
}

public protocol AGAudioPlayerViewControllerPresentationDelegate {
    func fullPlayerRequested()
    func fullPlayerDismissRequested(fromProgress: CGFloat)
    
    func fullPlayerStartedDismissing()
    func fullPlayerDismissUpdatedProgress(_ progress: CGFloat)
    func fullPlayerDismissCancelled(fromProgress: CGFloat)

    func fullPlayerOpenUpdatedProgress(_ progress: CGFloat)
    func fullPlayerOpenCancelled(fromProgress: CGFloat)
    func fullPlayerOpenRequested(fromProgress: CGFloat)
}

public protocol AGAudioPlayerViewControllerCellDataSource {
    func cell(inTableView tableView: UITableView, basedOnCell cell: UITableViewCell, atIndexPath: IndexPath, forPlaybackItem playbackItem: AGAudioItem, isCurrentlyPlaying: Bool) -> UITableViewCell
    func heightForCell(inTableView tableView: UITableView, atIndexPath: IndexPath, forPlaybackItem playbackItem: AGAudioItem, isCurrentlyPlaying: Bool) -> CGFloat
}

public protocol AGAudioPlayerViewControllerDelegate {
    func audioPlayerViewController(_ agAudio: AGAudioPlayerViewController, trackChangedState audioItem: AGAudioItem?)
    func audioPlayerViewController(_ agAudio: AGAudioPlayerViewController, changedTrackTo audioItem: AGAudioItem?)
    func audioPlayerViewController(_ agAudio: AGAudioPlayerViewController, passedHalfWayFor audioItem: AGAudioItem)

    func audioPlayerViewController(_ agAudio: AGAudioPlayerViewController, pressedDotsForAudioItem audioItem: AGAudioItem)
    func audioPlayerViewController(_ agAudio: AGAudioPlayerViewController, pressedPlusForAudioItem audioItem: AGAudioItem)
}

extension AGAudioPlayerViewController {
    public func switchToMiniPlayer(animated: Bool) {
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) { 
            self.switchToMiniPlayerProgress(1.0)
        }
    }
    
    public func switchToFullPlayer(animated: Bool) {
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) {
            self.switchToMiniPlayerProgress(0.0)
        }
    }
    
    public func switchToMiniPlayerProgress(_ progress: CGFloat) {
        var maxHeight = self.uiMiniPlayerContainerView.frame.height
        
        self.uiMiniPlayerTopOffsetConstraint.constant = -1.0 * maxHeight * (1.0 - progress)
        self.view.layoutIfNeeded()
    }
}

extension AGAudioPlayerViewController {
    @IBAction func handlePanToClose(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3
        let inView = uiHeaderView
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: inView)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        let interactor = dismissInteractor
        
        switch sender.state {
        case .began:
            uiScrubber.scrubbingEnabled = false
            
            interactor.hasStarted = true
            
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
            
        case .cancelled:
            uiScrubber.scrubbingEnabled = true
            
            interactor.hasStarted = false
            interactor.cancel(progress)
            
        case .ended:
            uiScrubber.scrubbingEnabled = true
            
            interactor.hasStarted = false
            
            if interactor.shouldFinish {
                interactor.finish(progress)
            }
            else {
                interactor.cancel(progress)
            }
        default:
            break
        }
    }
    
    @IBAction func handlePanToOpen(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.15
        let inView = uiMiniPlayerContainerView
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: inView)
        let verticalMovement = (-1.0 * translation.y) / view.bounds.height
        let upwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let upwardMovementPercent = fminf(upwardMovement, 1.0)
        let progress = CGFloat(upwardMovementPercent)
        let interactor = openInteractor
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
            
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel(progress)
            
        case .ended:
            interactor.hasStarted = false
            
            if interactor.shouldFinish {
                interactor.finish(progress)
            }
            else {
                interactor.cancel(progress)
            }
        default:
            break
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return !isCurrentlyScrubbing
    }
}

class DismissInteractor {
    var hasStarted = false
    var shouldFinish = false
    
    var viewController: AGAudioPlayerViewController? = nil
    
    var delegate: AGAudioPlayerViewControllerPresentationDelegate? {
        get {
            return viewController?.presentationDelegate
        }
    }
    
    public func update(_ progress: CGFloat) {
        delegate?.fullPlayerDismissUpdatedProgress(progress)
    }
    
    // restore
    public func cancel(_ progress: CGFloat) {
        delegate?.fullPlayerDismissCancelled(fromProgress: progress)
    }
    
    // dismiss
    public func finish(_ progress: CGFloat) {
        delegate?.fullPlayerDismissRequested(fromProgress: progress)
    }
}

class OpenInteractor : DismissInteractor {
    public override func update(_ progress: CGFloat) {
        delegate?.fullPlayerOpenUpdatedProgress(progress)
    }
    
    // restore
    public override func cancel(_ progress: CGFloat) {
        delegate?.fullPlayerOpenCancelled(fromProgress: progress)
    }
    
    // dismiss
    public override func finish(_ progress: CGFloat) {
        delegate?.fullPlayerOpenRequested(fromProgress: progress)
    }
}

extension AGAudioPlayerViewController {
    func setupStretchyHeader() {
        let blk = { [weak self] (fontScale: Double) in
            if let s = self {
                s.uiHeaderView.transform = CGAffineTransform(scaleX: CGFloat(fontScale), y: CGFloat(fontScale))
                
                let h = s.uiHeaderView.bounds.height * CGFloat(fontScale)
                s.uiTable.scrollIndicatorInsets = UIEdgeInsetsMake(h, 0, 0, 0)
            }
        }
        
        headerInterpolate = Interpolate(from: 1.0, to: 1.3, function: BasicInterpolation.easeOut, apply: blk)
        
        interpolateBlock = blk
        
        let insets = UIApplication.shared.keyWindow!.rootViewController!.view.safeAreaInsets
        self.uiConstraintSpaceBetweenPlayers.constant = insets.top
        self.view.layoutIfNeeded()
        
        self.uiConstraintBottomBarHeight.constant += insets.bottom * 2
        self.uiFooterView.layoutIfNeeded()
    }
    
    func viewWillAppear_StretchyHeader() {
        interpolateBlock?(1.0)
        
        let h = self.uiHeaderView.bounds.height
        self.uiTable.contentInset = UIEdgeInsetsMake(h, 0, 0, 0)
        self.uiTable.contentOffset = CGPoint(x: 0, y: -h)
    }
    
    func scrollViewDidScroll_StretchyHeader(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y + uiHeaderView.bounds.height
        
        let base = view.safeAreaInsets.top
        
        let np = CGFloat(abs(y).clamped(lower: CGFloat(base + 0), upper: CGFloat(base + 150))) / CGFloat(base + 150)
        
        if y < 0 && headerInterpolate?.progress != np {
//            headerInterpolate?.progress = np
        }
    }
}

extension AGAudioPlayerViewController {
    func setupColors() {
        applyColors(colors)
    }
    
    public func applyColors(_ colors: AGAudioPlayerColors) {
        self.colors = colors
        
        view.backgroundColor = colors.main
        uiMiniPlayerContainerView.backgroundColor = colors.main
        
        uiMiniLabelTitle.textColor = colors.accent
        uiMiniLabelSubtitle.textColor = colors.accent
        
        uiHeaderView.backgroundColor = colors.main
        uiFooterView.backgroundColor = colors.main
        
        uiLabelTitle.textColor = colors.accent
        uiLabelSubtitle.textColor = colors.accent
        
        uiLabelElapsed.textColor = colors.accentWeak
        uiLabelDuration.textColor = colors.accentWeak
        
        uiProgressDownload.backgroundColor = colors.barNothing
        uiProgressDownloadCompleted.backgroundColor = colors.barDownloads
        uiScrubber.elapsedColor = colors.barPlaybackElapsed
        uiScrubber.dragIndicatorColor = colors.scrubberHandle
        
        uiWrapperEq.isHidden = true
        uiWrapperEq.backgroundColor = colors.main.darkenByPercentage(0.05)
        
        uiSliderVolume.tintColor = colors.accent
        
        /*
         view.layer.masksToBounds = true
         view.layer.cornerRadius = 4
         */
        
        uiSliderEqBass.tintColor = colors.barPlaybackElapsed
        uiSliderEqBass.sliderUnselectedColor = colors.barDownloads
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension AGAudioPlayerViewController {
    func setupTable() {
        uiTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
//        uiTable.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: uiHeaderView.bounds.size.height + 44 * 2))
//        uiTable.backgroundView?.backgroundColor = ColorMain
        
        uiTable.allowsSelection = true
        uiTable.allowsSelectionDuringEditing = true
        uiTable.allowsMultipleSelectionDuringEditing = false
        
        uiTable.setEditing(true, animated: false)
        uiTable.reloadData()
    }
    
    func viewWillAppear_Table() {
    }
    
    public func tableReloadData() {
        if let t = uiTable {
            t.reloadData()
        }
    }
}

extension AGAudioPlayerViewController : UITableViewDelegate {
    /*
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissInteractor.hasStarted = true
    }
    */
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDidScroll_StretchyHeader(scrollView)
        
//        let progress = (scrollView.contentOffset.y - scrollView.contentOffset.y) / view.frame.size.height
//        
//        dismissInteractor.update(progress)
    }

//    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        dismissInteractor.hasStarted = false
//        
//        let progress = (scrollView.contentOffset.y - scrollView.contentOffset.y) / view.frame.size.height
//
//        if progress > 0.1 {
//            dismissInteractor.finish(progress)
//        }
//        else {
//            dismissInteractor.cancel(progress)
//        }
//    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        player.currentIndex = indexPath.row
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("\(indexPath) deselected")
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == SectionQueue
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath != destinationIndexPath {
            player.queue.moveItem(at: sourceIndexPath.row, to: destinationIndexPath.row)
            
            tableView.reloadData()
        }
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
}

extension AGAudioPlayerViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return player.queue.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Queue"
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        guard indexPath.row < player.queue.count else {
            cell.textLabel?.text = "Error"
            return cell
        }
        
        let q = player.queue.properQueue(forShuffleEnabled: player.shuffle)
        let item = q[indexPath.row]
        
        let currentlyPlaying = item.playbackGUID == player.currentItem?.playbackGUID
        
        if let d = cellDataSource {
            return d.cell(inTableView: tableView, basedOnCell: cell, atIndexPath: indexPath, forPlaybackItem: item, isCurrentlyPlaying: currentlyPlaying)
        }
        
        cell.textLabel?.text = (currentlyPlaying ? "* " : "") + item.title
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < player.queue.count else {
            return UITableViewAutomaticDimension
        }
        
        let q = player.queue.properQueue(forShuffleEnabled: player.shuffle)
        let item = q[indexPath.row]
        
        let currentlyPlaying = item.playbackGUID == player.currentItem?.playbackGUID
        
        if let d = cellDataSource {
            return d.heightForCell(inTableView: tableView, atIndexPath: indexPath, forPlaybackItem: item, isCurrentlyPlaying: currentlyPlaying)
        }
        
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates({
                player.queue.removeItem(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
        }
    }
}
