![](./azbouki-logo-dark.svg)

# Azbouki SDK for iOS

[![CI Status](https://img.shields.io/travis/tdermendjiev/azbouki.svg?style=flat)](https://travis-ci.org/tdermendjiev/azbouki)
[![Version](https://img.shields.io/cocoapods/v/azbouki.svg?style=flat)](https://cocoapods.org/pods/azbouki)
[![License](https://img.shields.io/cocoapods/l/azbouki.svg?style=flat)](https://cocoapods.org/pods/azbouki)
[![Platform](https://img.shields.io/cocoapods/p/azbouki.svg?style=flat)](https://cocoapods.org/pods/azbouki)

![](./layout-debugging-low2.gif)



## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

azbouki is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'azbouki'
```

## Initialization
```
import azbouki
// ...

AzboukiClient.configure(
	appId: "<your-azbouki-app-id>",
 	userId: "<any-id-string>")

```

## Usage

### Screenshot layout inspector

To send a screenshot call `takeScreenshot(view: UIView, message: String)`.
Example:

```
let alert = UIAlertController(title: "Send screenshot", message: "Add a description", preferredStyle: .alert)
  
alert.addTextField { (textField) in
    textField.text = ""
}

alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
    let textField = alert?.textFields![0]
    AzboukiClient.takeScreenshot(view: self.view, message: textField?.text ?? "")
}))

self.present(alert, animated: true, completion: nil)
```

## Author

@tdermendjiev

## License

azbouki is available under the MIT license. See the LICENSE file for more info.
