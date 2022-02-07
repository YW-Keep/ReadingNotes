### 用Swift实现优雅的前缀效果

这次分享主要是通过一个例子来说明如何封装一个前缀调用。

首先我们需要一个案例：我们需要实现一个方法，统计字符串中数字。

那么很快就有思路遍历1.通过ascii2.通过字符串比对。

代码如下：

```swift
    func numsNum(_ str: String) ->(Int) {
        var num = 0
        for char in str {
// ascii  方式先忽略 只要一种实现方式就可以
//            if let ascii = char.asciiValue {
//                if( ascii >= 48 && ascii <= 58) {
//                    num += 1
//                }
//            }
            if ("0123456789".contains(char)) {
                num += 1
            }
        }
        return num
    }

```

写到这里，你可能觉得不够优雅。1.这个方法是给字符串用的，理论上可以写扩展。2.好像不够Swift？于是我们有了优化版本2.0

```swift
extension String {
    func numsNum() ->(Int) {
        var num = 0
        for char in self where ("0"..."9").contains(char) {
            num += 1
        }
        return num
    }
}
```

到这里，很多人可能就觉得可以了，这样很不错了。当然，在项目中可能是差不多了，但是到组件层面可能还差点意思。首先，这样方法名很容易冲突，其次扩展也比较难。可能我们需要类似于"1234".kh.numsNum 这种调用方式就很优雅，那我们怎么实现呢。1.首先需要kh这么一个类，2.可能需要在这个类里实现方法。于是3.0版本如下：

```swift
struct Base {
    let str: String
    var numsNum: Int {
            var num = 0
            for char in str where ("0"..."9").contains(char) {
                num += 1
            }
            return num
        }
}
extension String {
    var kh: Base  {
        return Base.init(str:self)
    }
}
```

至此，可能觉得已经很棒了，但是比如我数组也要实现类似的功能该怎么办呢？可能有人拍拍脑袋会说，在搞一个Base呗里面是数组不就完了么。或者想的在多点的人会说，直接在Base里增加一个属性，可以通过Array 初始化，好像都不太友好。那么还有什么思路呢？没错，泛型。于是乎有了4.0版本：

```swift
struct KH<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

extension String {
    var kh: KH<String>  {
        return KH.init(self)
    }
}

extension KH where Base == String {
    var numsNum: Int {
            var num = 0
            for char in base where ("0"..."9").contains(char) {
                num += 1
            }
            return num
        }
}
```

这样情况下我们要给比如数组加方法就很简单了。

```swift
extension Array {
    var kh: KH<Array>  {
        return KH.init(self)
    }
}

extension KH where Base == Array<Any> {
    var numsNum: Int {
        return base.count
        }
}

```

到这里，可能又有人会说差不多已经很完美了，但是真的完美吗，答案是否定的。很明显，当我们新加一个类型的时候，每次都要扩展一个类型。好像这个代码也是重复的。那有没有方法可以解决这个问题呢？答案是有，那就是协议。这样我们的5.0版本就完成了：

```swift
protocol KHExtension {}
extension KHExtension {
    var kh: KH<Self>  {
        return KH.init(self)
    }
}
extension String: KHExtension {}
extension KH where Base == String {
    var numsNum: Int {
            var num = 0
            for char in base where ("0"..."9").contains(char) {
                num += 1
            }
            return num
        }
}
extension Array: KHExtension {}
```

这样，需要使用前缀的类只需要遵循这个协议就可以了。到这里，感觉基本完成了。其实没有还有个问题，如果我要扩展类方法呢？还有如果里面的方法要变base呢？即mutating方法呢？所以我们就有了6.0版本：

```swift
struct KH<Base> {
    var base: Base
    init(_ base: Base) {
        self.base = base
    }
}
protocol KHExtension {}
extension KHExtension {
    var kh: KH<Self>  {
        get { KH(self)}
        set {}
    }
    static var kh:KH<Self>.Type {
        get {KH<Self>.self}
        set {}
    }
}

extension String: KHExtension {}
extension KH where Base == String {
    var numsNum: Int {
        var num = 0
        for char in base where ("0"..."9").contains(char) {
            num += 1
        }
        return num
    }
    mutating func addStr()->(String) {
        base = base + "Str"
        return base
    }
    static var myKey: String {
        "12345"
    }
}
```

到这里，基础类就是我们的完全体了。但是等下，还有最后一个小细节。我们在Swift与OC的混合开发的地方其实经常返回的是NSString 之类的。那有没有办法让NSString  NSMutableString(这个其实就是继承自NSString)也支持呢？有人会说在写一遍。那也太麻烦了。其实这个问题也好解决，那就是找共同点，其实共同点就是他们都遵循一个字面量初始化协议。那这个问题就很简单了。

```swift
extension String: KHExtension {}
extension NSString: KHExtension {}
extension KH where Base: ExpressibleByStringLiteral {
    var numsNum: Int {
        var num = 0
        for char in base as! String where ("0"..."9").contains(char) {
            num += 1
        }
        return num
    }

}
  let str3: NSString = "1234"
  let num = str3.kh.numsNum
```

到这个我们整个前缀封装就全部结束了。这其实是一步步用Swift与协议优化代码的思路。也让实现更加优雅，撇开例子里的方法，其他代码如果需要其实可以直接用到你自己的项目中去。

#### 这类手法在三方库里的应用

最后我这里简单看了几个三方库，其实实现方法可以说是完全一样。首先我们看下RxSwift:

```swift
public struct Reactive<Base> {
    /// Base object to extend.
    public let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    public init(_ base: Base) {
        self.base = base
    }
}

extension ReactiveCompatible {
    /// Reactive extensions.
    public static var rx: Reactive<Self>.Type {
        get { Reactive<Self>.self }
        // this enables using Reactive to "mutate" base type
        // swiftlint:disable:next unused_setter_value
        set { }
    }

    /// Reactive extensions.
    public var rx: Reactive<Self> {
        get { Reactive(self) }
        // this enables using Reactive to "mutate" base object
        // swiftlint:disable:next unused_setter_value
        set { }
    }
}public struct Reactive<Base> {
    /// Base object to extend.
    public let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    public init(_ base: Base) {
        self.base = base
    }

    /// Automatically synthesized binder for a key path between the reactive
    /// base and one of its properties
    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Property>) -> Binder<Property> where Base: AnyObject {
        Binder(self.base) { base, value in
            base[keyPath: keyPath] = value
        }
    }
}

/// A type that has reactive extensions.
public protocol ReactiveCompatible {
    /// Extended type
    associatedtype ReactiveBase

    /// Reactive extensions.
    static var rx: Reactive<ReactiveBase>.Type { get set }

    /// Reactive extensions.
    var rx: Reactive<ReactiveBase> { get set }
}

extension ReactiveCompatible {
    /// Reactive extensions.
    public static var rx: Reactive<Self>.Type {
        get { Reactive<Self>.self }
        // this enables using Reactive to "mutate" base type
        // swiftlint:disable:next unused_setter_value
        set { }
    }

    /// Reactive extensions.
    public var rx: Reactive<Self> {
        get { Reactive(self) }
        // this enables using Reactive to "mutate" base object
        // swiftlint:disable:next unused_setter_value
        set { }
    }
}

```

完...完全一样是不是。

再看下大名鼎鼎的SnapKit

```swift
    var snp: ConstraintViewDSL {
        return ConstraintViewDSL(view: self)
    }
    
    public struct ConstraintViewDSL: ConstraintAttributesDSL {
       public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        ConstraintMaker.makeConstraints(item: self.view, closure: closure)
       }
        internal init(view: ConstraintView) {
           self.view = view
        }
    }
```

这里我截取了一小段，其实思路也是大相庭径的。通过返回另外一个类把本类传进去在做相应的处理。至此大家应该知道前缀调用如何实现了吧。

###### 注：本文部分参考李明杰的一个视频分享。

