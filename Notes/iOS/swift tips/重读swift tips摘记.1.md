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

### 26.协议和类中的Self

协议和类方法中出现Self 表示的是这个类挥着实现协议的类,所以我们在地方不能直接用实例来映射它（比如其他实现协议的类，子类也会用到），这样会编译报错。一般好的做法是，用type(of：)做一次转换。（有点绕，看下下面的例子吧）

```Swift
protocol Copyable {
    func copy() -> Self
}

class MyClass: Copyable {
    
    var num = 1
    
    func copy() -> Self {
        // 这里如果用MyClass().init()就会编译报错
        // 这样写的好处 还有子类也可以使用copy 方法了
        let result = type(of: self).init()
        result.num = num
        return result
    }
    
    required init() {
        
    }
}

let object = MyClass()
object.num = 100

let newObject = object.copy()
object.num = 1

print(object.num)     // 1
print(newObject.num)  // 100
```

### 27. 动态类型和多方法

Swift 与OC是不同的， swift不能根据对象在动态时的类型，进行合适的重载，而Object-C可以，所以说Object-C是一门动态语言，而swift是一门静态语言。但是可以通过类型判断来完成我们需要的重载：

```swift
class Pet {}
class Cat: Pet {}
class Dog: Pet {}

func printPet(_ pet: Pet) {
    print("Pet")
}

func printPet(_ cat: Cat) {
    print("Meow")
}

func printPet(_ dog: Dog) {
    print("Bark")
}

printPet(Cat()) // Meow
printPet(Dog()) // Bark
printPet(Pet()) // Pet

func printThem(_ pet: Pet, _ cat: Cat) {
    printPet(pet)
    printPet(cat)
}

printThem(Dog(), Cat())

// 输出：
// Pet
// Meow

func printThemAgain(_ pet: Pet, _ cat: Cat) {
    if let aCat = pet as? Cat {
        printPet(aCat)
    } else if let aDog = pet as? Dog {
        printPet(aDog)
    }
    printPet(cat)
}

printThemAgain(Dog(), Cat())
// 输出：
// Bark
// Meow
```

```objective-c
// OC 代码 
@interface ClassA : NSObject

- (void)printThings;

@end
@implementation ClassA

- (void)printThings {
    NSLog(@"A");
}

@end

@interface ClassB : ClassA

- (void)printThings;

@end

@implementation ClassB

- (void)printThings {
    NSLog(@"B");
}

- (void)print:(ClassA *) class {
    [class printThings];
}
// 打印出来是 a 和 b 
ClassA * a = [ClassA new];
[self print:a];
ClassA * b = [ClassB new];
[self print:b];
@end
```

### 28.属性观察

Swift中的属性观察很简单，只要实现willSet或者DidSet 即可，分别会有newValue 和oldValue表示新值和旧值。另外**初始化方法对属性的设定，以及在willSet或者DidSet中对属性的再次设定都不会再次触发属性观察。**另外，在同一个类型中，属性观察与计算属性是不能共存的。计算属性可以通过在set方法中处理达到相应的效果，当然如果不能设置，可以通过继承的方法重写属性来达到设置willSet或者DidSet方法。

```Swift
class A {
    var number :Int {
        get {
            print("get")
            return 1
        }
        
        set {print("set")}
    }
}

class B: A {
    override var number: Int {
        willSet {print("willSet")}
        didSet {print("didSet")}
    }
}

let b = B()
b.number = 0

// 输出
// get
// willSet
// set
// didSet
```

### 29.final

final关键词主要用在class,func 或者var 前，表示不允许对改内容进行继承或者重写。那么在什么情况下会用final呢：1.权限控制 2.类或者方法的功能确实已经完备了 3.子类继承或者修改是一件很危险的事情。4.为了父类中的某些代码一定会被执行。5.性能考虑（不建议）

### 30.lazy 修饰符和lazy方法

Object-C中有一个叫做懒加载的东西，主要是在运用的时候在创建复制。Swift中也有，就是lazy 修饰一个属性。但是要注意lazy修饰只能修饰var,而且还要注意要显式的指定属性类型。Swift中的lazy还可以用到map、filter这类方法中，起到一个延迟处理的用处。（在遍历的或者用的时候再执行map、filter内的代码）

### 31.Reflection 和 Mirror

Reflection（反射），这是一种在运行时检测、访问或者修改类型的行为的特征。Objective-C中，我们基本不会提起这个，因为Objective-C中的运行时比一般的反射还要强大和灵活。比如通过字符串生成类或者方法，然后生成对象或者调用都是反射的一种表现形式。Swift抛开Objective-C的运行时部分，还是一些关于反射的内容的。这里主要要介绍的就是Mirror，这是一个可以获取类型信息的一个类。具体请看下面

```Swift

struct Person {
    let name: String
    let age: Int
}

let xiaoMing = Person(name: "XiaoMing", age: 16)
let r = Mirror(reflecting: xiaoMing) // r 是 MirrorType

print("xiaoMing 是 \(r.displayStyle!)")

print("属性个数:\(r.children.count)")

for child in r.children {
    print("属性名:\(String(describing: child.label))，值:\(child.value)")
}

//for i in r.children.startIndex..<r.children.endIndex {
//    print("属性名:\(r.children[i].0!)，值:\(r.children[i].1)")
//}

// 输出：
// xiaoMing 是 Struct
// 属性个数:2
// 属性名:name，值:XiaoMing
// 属性名:age，值:16

dump(xiaoMing)
// 输出：
// ▿ Person
//  - name: XiaoMing
//  - age: 16

func valueFrom(_ object: Any, key: String) -> Any? {
    let mirror = Mirror(reflecting: object)
    
    for child in mirror.children {
        let (targetKey, targetMirror) = (child.label, child.value)
        if key == targetKey {
            return targetMirror
        }
    }
    
    return nil
}

// 接上面的 xiaoMing
if let name = valueFrom(xiaoMing, key: "name") as? String {
    print("通过 key 得到值: \(name)")
}

// 输出：
// 通过 key 得到值: XiaoMing
```

这里可以实现KVC类似的事情。但是swift的反射不是很强，只能做读取，不能设定，另外这一块因为文档并未完全公开，改动概率大，慎用！

### 32.隐式解包Optional

其实隐式解包与普通的Optional值并没有什么区别，只是在对类变量成员访问的时候编译器会自动为我们在后面插入解包符号！。隐式解包是一个历史原因引起的：因为Objective-C中Cocoa的所有类型变量都是可以指向nil的，所以Cocoa 的API中没有区分哪些会返回nil，所以转成swift方法的时候全部是Optional，那有些是确定不会nil的怎么办呢（都要判断很麻烦）所以隐式解包就出来了。 这里另外提一句，最好少用，尽量不用因为对nil解包是报错的，所以滥用万一出现没值的情况容易崩溃。

### 33.多重Optional

其实仔细想想？不过是Optional类型的语法糖而已，而Optional其实就是一个枚举而已。

```swift
public enum Optional<Wrapped> : ExpressibleByNilLiteral {

    /// The absence of a value.
    ///
    /// In code, the absence of a value is typically written using the `nil`
    /// literal rather than the explicit `.none` enumeration case.
    case none

    /// The presence of a value, stored as `Wrapped`.
    case some(Wrapped)
    // ...下面还有好多方法定义 有兴趣的可以自己去看
}
```

这里其实就一个嵌套的问题，其实也很好理解，一个盒子装了一个nil，另外一个盒子装了这个盒子，那么这个盒子就不是nil。可能表述有点绕，看下下面的代码：

```swift

var string: String? = "string"
var anotherString: String?? = string

var literalOptional: String?? = "string"

var aNil: String? = nil

var anotherNil: String?? = aNil
var literalNil: String?? = nil

if anotherNil != nil {
    // This will output.
    print("anotherNil")
}

if literalNil != nil {
    // This will not output.
    print("literalNil")
}

```

### 34.Optional Map

其实Optional 也定义了一套map 这类的方法，返回的也是可选值。这主要是一种函数式编程的思想。

### 35.Protocal Extension

swift 中标准库的功能基本都是基于protocol来实现的。

协议的扩展有如下规则，如果类型推断得到是实现协议的类型，那么类型中的实现将被调用，如果类型中没有实现，则协议扩展中的默认实现将被调用。如果类型推断是协议，那么如果在协议中有定义且类型中有实现那么调用类型中的实现，如果类型中没有实现那么调用协议扩展中的实现。如果协议中未定义，则直接调用扩展中的实现。（协议扩展方式其实可以实现可选协议）下面是个例子：

```swift
protocol A2 {
    func method1() -> String
}

extension A2 {
    func method1() -> String {
        return "hi"
    }
    
    func method2() -> String {
        return "hi"
    }
}

struct B2: A2 {
    func method1() -> String {
        return "hello"
    }
    
    func method2() -> String {
        return "hello"
    }
}

let b2 = B2()

b2.method1()
// hello
b2.method2()
// hello

let a2 = b2 as A2

a2.method1()
// hello

a2.method2()
// hi

```

### 36.where和模式匹配

where在swift中其实是一个很强大的关键词，但是往往会被忽略。这里主要讲讲这个关键词的用法。

首先在switch中可以作为条件判断：

```Swift
let name = ["王小二","张三","李四","王二小"]

name.forEach {
    switch $0 {
    case let x where x.hasPrefix("王"):
        print("\(x)是笔者本家")
    default:
        print("你好，\($0)")
    }
}
// 输出：
// 王小二是笔者本家
// 你好，张三
// 你好，李四
// 王二小是笔者本家
```

在for in 中也可以做类似的条件限制

```swift
let num: [Int?] = [48, 99, nil]

let n = num.flatMap {$0}
for score in n where score > 60 {
    print("及格啦 - \(score)")
}
// 输出：
// 及格啦 - Optional(99)
```

而在swift3 中if语句中不再使用where语句了：

```swift
num.forEach {
    if let score = $0, score > 60 {
        print("及格啦 - \(score)")
    } else {
        print(":(")
    }
}
// 输出：
// :(
// 及格啦 - 99
// :(
```

其实还有一种情形会是使用where，就是在泛型中想要对方法的类型进行限定的时候，比如Array的排序，这里就不再举例了。

### 37.enum嵌套

像表达链表等问题的时候，可以用enum嵌套 类似：

```swift
indirect enum LinkedList<Element: Comparable> {
    case empty
    case node(Element, LinkedList<Element>)
}
```

