# Swiftache

A [Mustache](http://mustache.github.io) template renderer for iOS (and OS X soon) implemented in pure Swift.


## Installation

In Xcode, create a workspace for your project if it doesn't have one already. Add the Swiftache project to the workspace, then link your project with the Swiftache framework.


## Usage

String input, string output:

```swift
let stache = Swiftache()
if stache.render("A{{#a}}{{b}}{{/a}}C", context: ["a": true, "b": "B"]) {
    println(stache.target!.text) // ABC
}
```

File input, string output:

```swift
let inUrl = NSURL(fileURLWithPath: "path/to/infile") // "A{{#a}}{{b}}{{/a}}C"
let stache = Swiftache()
if stache.render(inUrl, context: ["a": true, "b": "B"]) {
    println(stache.target!.text) // ABC
}
```

String input, file output:

```swift
let outUrl = NSURL(fileURLWithPath: "path/to/file")
let stache = Swiftache()
if stache.render("A{{#a}}{{b}}{{/a}}C",
                 context: ["a": true, "b": "B"],
                 target: FileRenderTarget(fileURL: url)) {
    println(stache.target!.text) // ABC
}
```

File input, file output:

```swift
let inUrl = NSURL(fileURLWithPath: "path/to/infile") // "A{{#a}}{{b}}{{/a}}C"
let outUrl = NSURL(fileURLWithPath: "path/to/outfile")
let stache = Swiftache()
if stache.render(inUrl,
                 context: ["a": true, "b": "B"],
                 target: FileRenderTarget(fileURL: url)) {
    println(stache.target!.text) // ABC
}
```

Lambda usage:

```swift
let stache = Swiftache()
let lowerABC: RenderLambda = { (text, render) -> String in
    return "a" + render(text).lowercaseString + "c"
}
if stache.render("{{#a}}{{b}}{{/a}}", context: ["a": Lambda(lowerABC), "b": "B"]) {
    println(stache.target!.text) // abc
}
```

## Contact

Twitter: [@BjornRuud](https://twitter.com/BjornRuud)


## License

Swiftache is licensed under the [MIT License (MIT)](http://opensource.org/licenses/MIT).
