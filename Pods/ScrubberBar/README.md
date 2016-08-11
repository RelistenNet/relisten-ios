# ScrubberBar

A customizable scrubber bar, inspired by Apple Music.

Usage:

Add a UIView to a storyboard and change its class to ScrubberBar. 

Appearance can be tweaked using the IBInspectable properties

Progress can be set by invoking `setProgress(progress: Float)`

Scrubbing events can be detected by adopting the `ScrubberBarDelegate` protocol and monitoring values from `scrubberBar(bar: ScrubberBar, didScrubToProgress: Float)`
