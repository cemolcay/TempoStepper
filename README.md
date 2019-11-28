TempoStepper
===

Fully customizable stepper that displays increase/decrease buttons on its left side, vertically, lets you auto step if you hold them as well as lets you write the value with keyboard if you tap to its value field.

Demo
----

![alt tag](https://github.com/cemolcay/TempoStepper/raw/master/demo.gif)

Requirements
----

- Swift 3.0+
- iOS 9.0+

Install
----

```
pod 'TempoStepper'
```

Usage
----

`TempoStepper` is an `@IBDesignable` control, so you can design it directly from storyboard or of course you can initialize it with traditional ways by programmatically.
  
Since it's a `UIControl` subclass, you just need to subscribe its `.valueChanged` event by `addTarget` function of `UIControl`. You can define an `@IBAction` function for that as well, if you want to link it from your storyboard.
  
It is highly customizable. You can either tweak its `@IBInspectable` properties in storyboard or change them from your code.

You can turn off tap to change and auto stepping features with `shouldTapToChange` and `shouldAutoStep` properties.

Also, you can edit the auto stepping speeds, min/max values of stepper and displaying decimals or not.

