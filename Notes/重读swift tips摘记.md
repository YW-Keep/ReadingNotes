## 重读swifter tips摘记 
## Swift中的新元素

### 1.柯里化

swift是可以将方法进行柯里化的,类似如下代码

```swift
func addTo(_ adder: Int) -> (Int) -> Int {
    return {
        num in
        return num + adder
    }
}
```

这种方式可以量产类似的方法。回头想想target-ation的实现，通过传入target与action 这里的action传入就可以用柯里化的方式实现。[具体思路看这里](https://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/?utm_campaign=iOS_Dev_Weekly_Issue_157&utm_medium=email&utm_source=iOS%252BDev%252BWeekly)

### 2.protocol中方法申明mutating

因为swift中的protocol可用于struct、enum，而他们又是值类型，所以要在方法内修改其内部的值需要方法前用mutating修饰（实现方法与协议方法都是需要的）。而class(它是引用类型)则不需要了。

### 3.Sequence

swift中的for…in 可以用在所有实现了Sequence协议中，而这个协议其实是序列协议，需要实现一个迭代器协议（IteratorProtocol）的迭代器。当然map，filter,reduce这些方法都是是现在Sequence协议的扩展中，你实现了该协议也就可以用了。思考：swift的for…in实现，map等方法的实现。

### 4.多元组

多元组有很好的易用性，比如：

```swift
func swapMe2<T>( a: inout T, b: inout T) {
    (a,b) = (b,a)
}
```

这样写方法交换是不是就很精髓。还有就是多元组能很好的解决返回问题，在OC中，不少CocoaAPI中的方法是通过指针来完成回调的（OC返回值只能有一个）。而使用元祖后就没有这类问题了。

### 5.@autoclosure

@autoclosure 可以把一段代码自动转化为一个闭包。这种写法可以使代码变的很优雅。这里有个??中使用@autoclosure 的例子。当然这里使用不单单是为了代码优雅，还可以使用闭包延迟调用值来提高性能的用处（如果传入值是复杂计算后的结果，这样闭包就可以在有值的情况下不计算来提高性能），代码如下：

```Swift
func ??<T>(optional: T?, defaultValue: @autoclosure () -> T) -> T {
    switch optional {
        case .Some(let value):
            return value
        case .None:
            return defaultValue()
        }
}
```

### 6.@escaping
这个是闭包的逃逸标签，所谓逃逸就是在传入后这个闭包可能在方法结束后调用。这里有段代码十分有意思：

```Swift
func doWork(block: ()->()) {
    block()
}

func doWorkAsync(block: @escaping ()->()) {
    DispatchQueue.main.async {
        block()
    }
}

class S {
    var foo = "foo"
    
    func method1() {
        doWork {
            print(foo)
        }
        foo = "bar"
    }
    
    func method2() {
        doWorkAsync {
            print(self.foo)
        }
        foo = "bar"
    }
    
    func method3() {
        doWorkAsync {
            [weak self] in
            print(self?.foo ?? "nil")
        }
        foo = "bar"
    }
}

S().method1()
// foo
S().method2()
// bar
S().method3()
// nil
let test = S()
test.method3()
// bar
```

到这里应该是可以理解逃逸闭包了，另外还有一点需要说明，如果协议中用到了逃逸闭包，对应的方法也必须申明为逃逸闭包，不然他们的函数签名不同。

### 7.可选值链条

可选值有些时候使用会很方便，但是你要时刻警惕，因为你可选值无论是计算还是调用方法等等得到的结果一定也是可选值。（可选值可不是nil 所以要保持警惕！时刻注意可选值）

### 8. 操作符

与Object-C不同，swift支持重载操作符，比如你要对一个向量相加，想重载加操作符：

```SWIFT
struct Vector2D {
    var x = 0.0
    var y = 0.0
}

let v1 = Vector2D(x: 2.0, y: 3.0)
let v2 = Vector2D(x: 1.0, y: 4.0)
let v3 = Vector2D(x: v1.x + v2.x, y: v1.y + v2.y)
// v3 为 {x 3.0, y 7.0}

func +(left: Vector2D, right: Vector2D) -> Vector2D {
    return Vector2D(x: left.x + right.x, y: left.y + right.y)
}
let v4 = v1 + v2
// v4 为 {x 3.0, y 7.0}
```

而有时候单单重载可能不够，比如向量操作里有乘积和的概念。而我们swift没有+*这样的操作符，所以不能重载，这时候只能进行添加了。

```Swift
// associativity 是结合律 多个同类的操作符顺序出现的计算顺序 比如常见的加法、减法都是left 这里的点乘返回的是double所以不用考虑结合律了
// precedencegroup 是定义操作符的优先级别比如 加法优先级 (AdditionPrecedence) 和乘法优先级 (MultiplicationPrecedence) 等
precedencegroup DotProductPrecedence {
    associativity: none
    higherThan: MultiplicationPrecedence
} 
// infix 表示中位操作符。
infix operator +*: DotProductPrecedence

func +* (left: Vector2D, right: Vector2D) -> Double {
    return left.x * right.x + left.y * right.y
}

let result = v1 +* v2
```

这里要警告下，Swift操作符是不能定义在局部域中的，还有来自不同的modeule的操作符是可能冲突的。所以当你用操作符的重载和自定义的时候一定要考虑清楚！

### 9.func 的参数修饰

方法传入的值默认是let的，如果你想变一个方法的值，那么需要用inout这个修饰符修饰。注意这个修饰符修饰后，传入的值前面需要加上&符号。但这里&还是很有玄机的，我们知道swift值类型不能直接修改他的地址来让它指向新值。那么这个&到底做了什么呢？其实对于值类型来说，inout相当于在函数内部创建了一个新的值，然后在函数返回的时候将这个值赋给&修饰的变量，这与引用类型的行为是不同的。

### 10.字面量表达

所谓字面量，就是能够直截了当地指出自己的类型并为变量进行赋值的值。例如：

```swift
let aNumber = 3
let aString = "Hello"
let aBool = true
// 其中3 hello true 就是字面量
```

Swift提供了一套非常神奇的字面量协议，可以让你的类使用字面量赋值，具体用法如下:

```swift
enum MyBool: Int {
    case myTrue, myFalse
}

extension MyBool: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self = value ? .myTrue : .myFalse
    }
}

let myTrue: MyBool = true
let myFalse: MyBool = false

myTrue.rawValue    // 0
myFalse.rawValue   // 1
// 这里是实现Bool的字面量协议方式
```

这里再提醒一句我们暂时无法为现有的非final(关键字可以用在class,func或者var前面修饰表示不允许进行继承或者重写)的class添加字面量表达式。（这句话好绕啊 原因是class协议里有一些required的初始化方法，而这些方法不能写在扩展中。） 最后 我想说的是字面量，表面上很强大，对缩短代码有很大的帮助，但是容易对阅读的人产生迷惑，到底有啥用等你开发吧！

### 10.下标

用下标取值是一种很方便的做法。但是要注意字典取到的值是Optional类型的，因为取到可能是没值的。（另外提一句，数组越界是直接奔溃的。） 这里要说下一种黑科技，就是自定义下标（不单单可以对自己的类型，对			Array Dictionay同样可以）。关键词就是subscript 代码如下

```swift
extension Array {
    subscript(input: [Int]) -> ArraySlice<Element> {
        get {
            var result = ArraySlice<Element>()
            for i in input {
                assert(i < self.count, "Index out of range")
                result.append(self[i])
            }
            return result
        }
        
        set {
            for (index,i) in input.enumerated() {
                assert(i < self.count, "Index out of range")
                self[i] = newValue[index]
            }
        }
    }
}
var arr = [1,2,3,4,5]
arr[[0,2,3]] = [-1,-3,-4]
print(arr[[1,2]])

```

### 11.方法嵌套

swift中方法终于是一等公民啦，我们可以将方法当做变量或者参数使用啦。那方法嵌套方法之类的完全没问题呀。这里可能会有个疑问为什么要这么做。这里举例两种试用场景其他的大家自己去想：1.方法很大，做方法拆分，但是其实这些拆分出来的方法也就这个方法内用到。2.隐藏实现。

### 12.命名空间

Objective-C在编译后会把所有的代码和引用的静态库编译成同一个域和二进制中。这回有个一个弊端一旦有同一个类名就会有编译冲突以及奔溃。

而Swift中可以使用命名空间，命名空间不同的名字相同的类型是可以和平共处的。Swift的命名空间是基于module的也就是说同一个target里的类型名字还是不能相同的。使用的时候要加上空间名。（其实个人感觉还是挺麻烦的，没多大用。）

### 13.typealias

大家都知道，typealias主要是用于为已经存在的类型重新定义新名字，主要让代码更易读。但是要注意在给泛型重命名时只能也是泛型的名字。

### 14.associatedtype

swift 有个很吊的功能，就是可以使用associatedtype来作为类型占位符。让实现协议的类型来指定具体的类型。具体来看这段例子

```swift
protocol Food { }
// 这里就用了食物的类型 占位符，如果不用的话 下面老虎吃肉必须判断是不是肉了不然报错。
protocol Animal {
    associatedtype F: Food
    func eat(_ food: F)
}

struct Meat: Food { }
struct Grass: Food { }

struct Tiger: Animal {
    func eat(_ food: Meat) {
        print("eat \(food)")
    }
}

let meat = Meat()
Tiger().eat(meat)

struct Sheep: Animal {
    func eat(_ food: Grass) {
        print("eat \(food)")
    }
}
// 这里要注意，当有占位符后 这个协议不是一个独立的协议了 是一个泛型了所以不能这么用了。只能像下面那样使用了
//func isDangerous(animal: Animal) -> Bool {
//    return false
//}
func isDangerous<T: Animal>(animal: T) -> Bool {
    if animal is Tiger {
        return true
    } else {
        return false
    }
}

isDangerous(animal: Tiger())
isDangerous(animal: Sheep())
```

### 15.可变参数

可变参数在swift中变得十分简单，只需要在参数后面加上… 就可以了,在方法中得到就是该参数的数组。但是其实它是有限制的。1.一个方法中只能有一个可变参数。2.可变参数的类型必须是相同的。

### 16.初始化方法顺序

swift对初始化的顺序很严格，要先初始化子类中的属性，然后再调用父类init方法，最后（如果需要）修改父类属性。当如你不需要修改父类属性的话，调用父类init方法也可以不写，系统会帮我们自动调用。（其实我还是建议写上清楚一些。）

### 17.Designated,Convenience ,Required

这里主要接着上一个初始化，聊一聊构造器了。Designated指定构造器，Convenience便利构造器。这里主要说下构造器的原则：1.指定构造器向上代理2.遍历构造器横向代理3.遍历构造器导致一个指定构造器被调用。 然后是构造器的继承规则：1.子类没有定义任何意义的构造器，将自动继承父类所有的构造器。2.父类指定构造器被实现（重写或者由于方式一），相应的便利构造器被自动继承。 最后聊一聊Required,这个关键词主要的作用是需要子类必须实现。主要的做用有2个：1.修饰指定构造器，那么依赖于它的便利构造器就可以一直使用了。2.修饰便利构造器（目的不让子类使用父类便利构造器。）。

### 18.初始化返回nil

如果遇到初始化可能失败的方法只需要在指定构造器init后面加上？就可以了。这样返回的就是可选值。

### 19.static 和 class

static 修饰方法，属性时其实是静态属性（便于理解可以理解为类属性），类方法，在Class 中可以使用class进行修饰也可以使用static修饰，效果一样。而枚举，结构体，甚至是协议中则需要使用static。结论是，任何时候使用static应该都是没有问题的。

### 20.多类型和容器

Swift 中常用的容器有三种分别是：Array、Dictionay和Set。他们都是泛型，即一个集合中只能放同一个类型的元素。

那么怎么存储多类型呢。第一个方式做转化：

```swift
// Any 类型可以隐式转换
let mixed: [Any] = [1, "two", 3]

// 转换为 [NSObject]
let objectArray = [1 as NSObject, "two" as NSObject, 3 as NSObject]
```

这种方式肯定不是一种很好的方式。第一，会在转化过程中造成部分信息的损失。第二使用时还要再转化一次。第三任意类型也危险，并不安全。

第二个方式，用协议约束

```Swift
// CustomStringConvertible  是打印的那个协议description
let mixed: [CustomStringConvertible] = [1, "two", 3]
for obj in mixed {
    print(obj.description)
}
```

相对第一种，能明显安全很多，也不需要做过多的转化，但是丢失信息的问题还是没有解决。

第三个方式，因为enum可以存贮值，所以我们可以把信息分装到enum中，例如：

```Swift
enum IntOrString {
    case IntValue(Int)
    case StringValue(String)
}

let mixed = [IntOrString.IntValue(1),
             IntOrString.StringValue("two"),
             IntOrString.IntValue(3)]
// 去的时候可以用switch 判断。
```

这种方式相对合理一些，因为不会造成数据的丢失。所以多容器尽量使用这种方式吧。

### 21.default 参数

swift 的方法 是可以有默认值的，这种方式很好用，再也不用像OC一样类似的方法写一堆了。

### 22.正则表达式

Swift 正则表达式可以用NSRegularExpression实现，具体代码如下：

```swift
struct RegexHelper {
    let regex: NSRegularExpression
    
    init(_ pattern: String) throws {
        try regex = NSRegularExpression(pattern: pattern,
            options: .caseInsensitive)
    }
    
    func match(_ input: String) -> Bool {
        let matches = regex.matches(in: input,
                    options: [],
                    range: NSMakeRange(0, input.utf16.count))
        return matches.count > 0
    }
}

let mailPattern =
"^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"

let matcher: RegexHelper
do {
    matcher = try RegexHelper(mailPattern)
}

let maybeMailAddress = "onev@onevcat.com"

if matcher.match(maybeMailAddress) {
    print("有效的邮箱地址")
}
// 输出:
// 有效的邮箱地址
```

前面说过可以自定义操作符这里就可以吧这个做为一个操作符自定义：

```Swift
precedencegroup MatchPrecedence {
    associativity: none
    higherThan: DefaultPrecedence
}

infix operator =~: MatchPrecedence

func =~(lhs: String, rhs: String) -> Bool {
    do {
        return try RegexHelper(rhs).match(lhs)
    } catch _ {
        return false
    }
}

if "onev@onevcat.com" =~
    "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$" {
        print("有效的邮箱地址")
}
// 输出:
// 有效的邮箱地址
```

### 23.模式匹配

虽然Swift中没有内置的正则表达支持，但是有个相似的特性那就是模式匹配。Swift的switch就是使用了~=操作符进行模式匹配，case指定的模式作为左参数输入，而等待匹配的被switch的元素作为操作符的又参数。所以我们可以重载~=操作符来做正则表达式：

```Swift

func ~=(pattern: NSRegularExpression, input: String) -> Bool {
    return pattern.numberOfMatches(in: input,
        options: [],
        range: NSRange(location: 0, length: input.count)) > 0
}

prefix operator ~/

prefix func ~/(pattern: String) throws -> NSRegularExpression {
    return try NSRegularExpression(pattern: pattern, options: [])
}

let contact = ("http://onevcat.com", "onev@onevcat.com")

let mailRegex: NSRegularExpression
let siteRegex: NSRegularExpression

mailRegex = try ~/"^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
siteRegex = try ~/"^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"

switch contact {
    case (siteRegex, mailRegex): print("同时拥有有效的网站和邮箱")
    case (_, mailRegex): print("只拥有有效的邮箱")
    case (siteRegex, _): print("只拥有有效的网站")
    default: print("嘛都没有")
}

// 输出
// 同时拥有网站和邮箱
```

### 24. …与..<

其实我们经常把这个用在数组的获取上，其实仔细看它的定义，它其实是泛型的。这个操作符还有一个接受 Comparable 的输入，并返回 ClosedInterval 或 HalfOpenInterval 的重载。比如

```Swift
let test = "helLo"
let interval = "a"..."z"
for c in test {
    if !interval.contains(String(c)) {
        print("\(c) 不是小写字母")
    }
}
```

### 25.AnyClass，元类型和 .self

其实AnyClass 就是，一个typealias的定义,定义如下：

```swift
public typealias AnyClass = Swift.AnyObject.Type
```

其实.tpye表示的是这个类型的类型。获取方式也很简单，即在类型后面加上.self就可以了。如果你在实例后面加上.self获取的就是实例本身。

```swift
class A {
}
// 获取类的类名
let typeA = A.self

let myA = A()
// 这样获取是本身
let selfA = myA.self
// 获取实例的类名
let typeB = type(of: myA)

```

如果是协议的话可以用.Protocol获取协议元 用法与.Type类似。

其实这东西用处还是很多的，举例子工厂化创建类似：

```swift
import UIKit
class MusicViewController: UIViewController {}

class AlbumViewController: UIViewController {}

let usingVCTypes: [AnyClass] = [MusicViewController.self,
    AlbumViewController.self]

func setupViewControllers(_ vcTypes: [AnyClass]) {
    for vcType in vcTypes {
        if vcType is UIViewController.Type {
            let vc = (vcType as! UIViewController.Type).init()
            print(vc)
        }
        
    }
}
```

