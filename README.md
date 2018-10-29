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

AppStore
----

This control used in my app [ArpBud](https://itunes.apple.com/us/app/arpbud-midi-sequencer-more/id1349342326?ls=1&mt=8) in App Store, check it out!
