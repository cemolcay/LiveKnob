LiveKnob
===

Yet another knob for iOS but with IBDesignable and Ableton Live style.  
Horizontal, vertical (or both) and rotary control options.

![alt tag](https://github.com/cemolcay/LiveKnob/raw/master/LiveKnob.gif)

Requirements
----

* iOS 9.0+
* Swift 4.0+

Install
----

```
pod 'LiveKnob'
```

Usage
----

* Drop a UIView from storyboard and change its class to `LiveKnob`.
* Tweak style settings.
* Bind an `IBAction` function to `LiveKnob`s `valueChanged` event.
* Or you can do it programmatically.

![alt tag](https://github.com/cemolcay/LiveKnob/raw/master/LiveKnobStoryboard.gif)

You can change the line width and color of the base ring, progress ring and pointer.   Also you can tweak the start and end angles of the base knob ring.  

### LiveKnobControlType
You can set the `controlType` for changing the knob's touch control behaviour. It supports horizontal and/or vertical slidings as well as rotary slidings.

### LiveKnobMarker
You can create custom marker views in with `LiveKnobMarker` type and set them to LiveKnob's `markers` array in order to draw markers around the knob. You can set individual offset and transform for each marker as well. 

SwiftUI Bridge
---

You can use it with SwiftUI  
https://gist.github.com/cemolcay/caed8e701de775de63ab4ae34b70b256  

AppStore
----

This control used in my apps  

* [ArpBud](https://itunes.apple.com/us/app/arpbud-midi-sequencer-more/id1349342326?ls=1&mt=8) 
* [Euclid Goes to Party](https://apps.apple.com/us/app/euclid-goes-to-party-auv3-bass/id1565732327) (iOS, AUv3, M1)  
* [SnakeBud](https://apps.apple.com/us/app/snakebud-auv3-midi-sequencer/id1568600625) (iOS, AUv3, M1)  
* [MelodyBud](https://apps.apple.com/us/app/melodybud-auv3-midi-sequencer/id1601357369) (iOS, AUv3, M1)  
