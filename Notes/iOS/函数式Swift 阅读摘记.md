## 函数式Swift 阅读摘记

### 引言

面向对象编程专注于类和对象的设计，每个类和对象都有它们自己的封装状态。然而，函数式编程强调基于值编程的重要性，这能使我们免受可变状态或其他一些副作用的困扰。

我们先构建一系列简单却具有一定功能的小函数，然后再将这些函数进行组装以实现完整的逻辑和复杂的运算，这是函数式编程的基本思想。

### 1.函数式思想

函数在 Swift 中是一等值 (first-class-values)，换句话说，函数可以作为参数被传递到其它函数，也可以作为其它函数的返回值。

**函数式编程的核心理念就是函数是值，它和结构体、整型或是布尔型没有什么区别** —— 对函数使用另外一套命名规则会违背这一理念。

我们应该谨慎地选择类型，这比其他任何事都重要，因为类型将左右开发流程。

案例：Battleship

思考，如何设计一个模块表示，能打到敌方战舰又不打到己方战舰。

函数式改造核心概念，定义一个区域为传入一个位置返回是否的方法。

```Swift
typealias Distance = Double
struct Position {
var x: Double
var y: Double
}
typealias Region = (Position) -> Bool
```

那么从原点开始的圆的表示则为如下所示

```swift
func circle(radius: Distance) -> Region {
return { point in point.length <= radius }
}


// 偏移函数 其中minus定义在Position扩展中为坐标相减 其实用类似的我们已经可以得到交集并集等相应的函数了
func shift(_ region: @escaping Region, by offset: Position) -> Region {
return { point in region(point.minus(offset)) }
}
let shifted = shift(circle(radius: 10), by: Position(x: 5, y: 5))

```

这样就可以一步一步解决之前的问题了。

与之前相比，这种方式是**装配式**的，通过定义我们之前提出的辅助函数将这些关注点进行分离，显著提高了复杂区域的组合性和易读性。同时也提高了代码的复用性。

### 案例探究：封装Core Image

这里主要探究滤镜，大家知道滤镜功能很强大（美图秀秀的基本呀），但是使用起来也十分不方便，大概是这样的的：

```swift
// 1.获取本地图片路径
let fileURL = NSBundle.mainBundle().URLForResource("image", withExtension: "png") 
// 2.创建CIImage对象
let beginImage = CIImage(contentsOfURL: fileURL!) 
// 3. 创建滤镜
// 创建一个棕榈色滤镜
let filter = CIFilter(name: "CISepiaTone")!
filter.setValue(beginImage, forKey: kCIInputImageKey)
// 设置输入的强度系数
filter.setValue(0.5, forKey: kCIInputIntensityKey)
// 4.将CIImage转换为UIImage 
//  其实在这个API内部用到了CIContext，而它就是在每次使用的使用去创建一个新的CIContext，比较影响性能
let newImage = UIImage(CIImage: filter.outputImage!)
self.imageView.image = newImage
```

那每次这么写是不是很不方便，所以我们自己顶一个滤镜：

```swift
// 选取对象是关键呀！
typealias Filter = (CIImage) -> CIImage 
// 那各种滤镜应该为
func myFilter(...) -> Filter
// 比如说模糊滤镜
func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String: Any] = [
        kCIInputRadiusKey: radius,
        kCIInputImageKey: image
        ]
        guard let filter = CIFilter(name: "CIGaussianBlur",
        withInputParameters: parameters)
        else { fatalError() }
        guard let outputImage = filter.outputImage
        else { fatalError() }
        return outputImage
    }
}
```

这样其实就可以嵌套使用了，如果为了好看，我们可以在写一个滤镜复合的方法：

```swift
func compose(filter filter1: @escaping Filter,
with filter2: @escaping Filter) -> Filter
{
    return { image in filter2(filter1(image)) }
}
// 还可以定义运算符，来使代码更易懂
infix operator >>>
func >>>(filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
return { image in filter2(filter1(image)) }
}
```

其实这些能实现的基础就是**柯里化**

可能会有人问Core Image已经封装的很好了呀，为什么还要在封装呢？但是你从封装中可以看出来，我们这么做明显比之前更安全，更模块化，也更清晰易懂。（我不需要关心KVC中的K值了，滤镜之间相互叠加也很方便。）

### Map、Filter和Reduce

map的定义如下：

```SWIFT
extension Array {
    func map<T>(_ transform: (Element) -> T) -> [T] {
        var result: [T] = []
        for x in self {
            result.append(transform(x))
        }
        return result
    }
}
```

Filter定义如下：

```Swift
extension Array {
    func filter(_ includeElement: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        for x in self where includeElement(x) {
            result.append(x)
        }
        return result
    }
}
```

Reduce定义如下：

```swift
extension Array {
    func reduce<T>(_ initial: T, combine: (T, Element) -> T) -> T {
        var result = initial
        for x in self {
            result = combine(result, x)
        }
        return result
    }
}
```

其实想想我们可以用Reduce重新定义map以及Filter

```swift
extension Array {
    func mapUsingReduce<T>(_ transform: (Element) -> T) -> [T] {
    return reduce([]) { result, x in
        return result + [transform(x)]
    }
}
func filterUsingReduce(_ includeElement: (Element) -> Bool) -> [Element] {
    return reduce([]) { result, x in
        return includeElement(x) ? result + [x] : result
    }
}
```

我们能够使用 reduce 来表示所有这些函数，这个事实说明了 reduce 能够通过通用的方法来体现一个相当常见的编程模式：遍历数组并计算结果。(ps：其实这并不是一个好主意，因为这样做代码最终会在运行期间大量复制生成的数组，换句话说，它会反复分配内存，释放内存，以及复制大量内存中的内容。)

**使用泛型允许你无需牺牲类型安全就能够在编译器的帮助下写出灵活的函数；如果使用 Any 类型，那你就真的就孤立无援了。**

### 可选值

在标准库中??定义如下

```Swift
infix operator ??
func ??<T>(optional: T?, defaultValue: @autoclosure () throws -> T)
rethrows -> T
{
    if let x = optional {
        return x
    } else {
        return try defaultValue()
    }
}
```

这里有几个问题1.为什么要用闭包。答案也很简单，当你的默认值通过计算得到的时候其实我期望的是在nil的时候才去执行计算代码，所以这里要使用闭包。2.为什么要使用@autoclosure，这个其实就是自动闭包为了书写好看。3.为什么使用throws。这个不确定，应该是为了防止内部有错误吧。

选择显式的可选类型更符合 Swift 增强静态安全的特性。强大的类型系统能在代码执行前捕获到错误，而且显式可选类型有助于避免由缺失值导致的意外崩溃。

Objective-C 采用的默认取零的做法有其弊端，可能你会想要区分失败的字典查询 (键不存在于字典) 和成功但返回 nil 的字典查询 (键存在于字典，但关联值是 nil) 两种情况。若要在 Objective-C 中做到这一点，你只能使用 NSNull。

### 案例探究：QuickCheck

测试通常由一些代码片段和预期结果组成。执行代码之后，将它的结果与测试中定义的预期结果相比较。不同的库测试的层次会有所不同 —— 有的测试独立的方法，有的测试类，还有一些执行集成测试 (运行整个应用)。在本章中，我们将通过迭代的方法，一步一步完善并最终构建一个针对 Swift 函数进行“特性测试 (property-based testing)”的小型库。

QuickCheck (Claessen and Hughes 2000) 是一个用于随机测试的 Haskell 库。相较于独立的单元测试中每个部分都依赖特定输入来测试函数是否正确，QuickCheck 允许你描述函数的抽象特性并生成测试来验证这些特性。当一个特性通过了测试，就没有必要再证明它的正确性。更确切地说，QuickCheck 旨在找到证明特性错误的临界条件。在本章中，我们将用 Swift (部分地) 移植 QuickCheck 库。

下面举例子叙述使用比如需要检查加法交换律:

```swift
func plusIsCommutative(x: Int, y: Int) -> Bool {
    return x + y == y + x
}

check("Plus should be commutative", plusIsCommutative)
// "Plus should be commutative" passed 10 tests.
//如果用尾随闭包，就更简单了
check("Additive identity") { (x: Int) in x + 0 == x }
// "Additive identity" passed 10 tests.
```

从上面的测试代码中可以看出来核心问题就是构建QuickCheck，而构建QuickCheck我们需要做下面几件事情：

1.首先需要有方法生成不同类型的随机数

2.有了随机数我们需要实现check函数，然后把随机数传递给他的特性参数

3.测试失败，我们会希望测试的输入值尽可能精准。

4.最后需要适用带有泛型的类型的函数。

#### 生成随机数

```Swift
// 用arc4random生成随机数
extension Int: Arbitrary {
    static func arbitrary() -> Int {
        return Int(arc4random())
   ji
}
// 加入范围的随机数
extension Int {
static func arbitrary(in range: CountableRange<Int>) -> Int {
        let diff = range.upperBound  - range.lowerBound
        return range.lowerBound + (Int.arbitrary() % diff)
    }
}
// 生成随机字符串
extension UnicodeScalar: Arbitrary {
    static func arbitrary() -> UnicodeScalar {
        return UnicodeScalar(Int.arbitrary(in: 65..<90))!
    }
}
extension String: Arbitrary {
    static func arbitrary() -> String {
        let randomLength = Int.arbitrary(in: 0..<40)
        let randomScalars = (0..<randomLength).map { _ in
        UnicodeScalar.arbitrary()
        }
        return String(UnicodeScalarView(randomScalars))
    }
}
```

#### 实现check函数

```Swift
// check函数第一版
func check1<A: Arbitrary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        guard property(value) else {
            print("\"\(message)\" doesn't hold: \(value)")
            return
        }
    }
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}
```

#### 缩小范围

```swift
protocol Arbitrary: Smaller {
    static func arbitrary() -> Self
}
// 迭代函数来缩小范围
func iterate<A>(while condition: (A) -> Bool, initial: A, next: (A) -> A?) -> A {
    guard let x = next(initial), condition(x) else {
        return initial
    }
    return iterate(while: condition, initial: x, next: next)
}
// 那么check就有第二个版本了
func check2<A: Arbitrary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        guard property(value) else {
            let smallerValue = iterate(while: { !property($0) }, initial: value) {
            $0.smaller()
            }
            print("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}
```

#### 数组扩展

我们想做的是让 Array 本身遵循 Arbitrary 协议。不过，只有数组的每一项都遵循 Arbitrary 协议，数组本身才会遵循 Arbitrary 协议。理想情况下，我们我们会像下面这样来表示数组的每一项都应该遵循：

```swift
extension Array: Arbitrary where Element: Arbitrary {
    static func arbitrary() -> [Element] {
    // ...
    }
}
```

很遗憾，目前还无法将这个限制表示为类型约束，并不可能编写一个让 Array 遵循 Arbitrary 协议的扩展。所以我们又只能修改check方法。

首先我们定义一个包含两个所需函数的辅助结构体：

```Swift
struct ArbitraryInstance<T> {
    let arbitrary: () -> T
    let smaller: (T) -> T?
}
func checkHelper<A>(_ arbitraryInstance: ArbitraryInstance<A>,
_ property: (A) -> Bool, _ message: String) -> ()
{
    for _ in 0..<numberOfIterations {
        let value = arbitraryInstance.arbitrary()
        guard property(value) else {
            let smallerValue = iterate(while: { !property($0) },
            initial: value, next: arbitraryInstance.smaller)
            print("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}
//如果我们知道Arbitrary 那么我们就可以重新写check了
func check<X: Arbitrary>(_ message: String, property: (X) -> Bool) -> () {
    let instance = ArbitraryInstance(arbitrary: X.arbitrary,
    smaller: { $0.smaller() })
    checkHelper(instance, property, message)
}
//如果我们有一个类型，无法对它定义所需的 Arbitrary 实例，就像数组的情况一样，我们可以重载 check 函数并自己构造所需的 ArbitraryInstance 结构体
func check<X: Arbitrary>(_ message: String, _ property: ([X]) -> Bool) -> () {
    let instance = ArbitraryInstance(arbitrary: Array.arbitrary,
    smaller: { (x: [X]) in x.smaller() })
    checkHelper(instance, property, message)
}
```

也许出乎你的意料，不过有确凿的证据表明，测试技术会影响你的代码设计。依赖测试驱动设计的人们使用测试并不仅仅是为了验证他们的代码是否正确，他们还根据测试来指导编写测试驱动的代码，这样一来，代码的设计将会变得简单。这非常有意义 —— 如果不需要复杂的构建流程就能够容易地为类编写测试代码的话，说明这个类的耦合度很低。

#### 展望

1.缩小的方法很傻很天真。

2.Arbitrary实例相当简单。

3.将生成的测试数据分类

4.我们也许会希望能更好地控制生成的随机输入值的个数

5.我们可能想用确定的种子来初始化随机生成器，以使它能够重现测试用例所生成的值。这将会使失败的测试更容易被复现

目前，有很多实现了特性测试的 Swift 库。比如说 SwiftCheck 就是其中之一。如果你想在 Objective-C 上进行特性测试，可以考虑 Fox。

### 不可变性的价值

以我们的智力，更适合掌控静态关系，而把随时间不断发展的过程形象化的能力相对不那么发达。

当把一个值类型赋值给新的变量，或者传递给函数时，值类型总是会被复制，而引用类型并不会被复制。

对引用类型的对象来说，只有对于对象的引用会被复制，而不是对象本身。对于对象本身的任何修改都会在通过另一个引用访问相同对象时被反映出来。

Swift 为结构体也提供了 mutating 方法，它们只能在被声明为 var 的结构体变量上被调用。这可以让我们在不存在全局副作用的情况下，允许我们拥有局部可变性。

耦合度通常被用来描述代码各个独立部分之间彼此依赖的程度。耦合度是衡量软件构建好坏的重要因素之一。最坏的情况下，所有类和方法都错综复杂相互关联，共享大量可变变量，甚至连具体的实现细节都存在依赖关系。这样的代码难以维护和更新：你无法理解或修改一小段独立的代码片段，而是需要一直站在整体的角度来考虑整个系统。

像这样只要输入值相同则得到的输出值一定相同的函数有时被称为引用透明函数。

引用透明化在各个层面都使代码更加模块化。

**学会在可能的时候避免使用可变状态和对象，将有助于降低耦合度，从而改善你的代码结构。**

### 枚举

Swift 函数式编程中的一条核心原则：高效地利用类型排除程序缺陷。

不同于 Objective-C，枚举在 Swift 中创建了新的类型，与整数或者其他已经存在的类型没有任何关系。

```Swift
// 枚举在一些不太确定数据结构的情况下的一种很好回调方式(比如请求返回)
enum Result<T> {
    case success(T)
    case error(Error)
}
```

我们可以在我们自己的 Result 类型中定义一些用于操作可选值的函数。通过在 Result 中重新定义 ?? 运算符，我们可以对 Result 进行运算：

```swift
func ??<T>(result: Result<T>, handleError: (Error) -> T) -> T {
    switch result {
        case let .success(value):
            return value
        case let .error(error):
            return handleError(error)
    }
}
```

其实，我们希望说明的问题，并不是 “Result 类型是 Swift 中处理错误的最好的方案”。我们只是试图阐述，如何使用枚举去定义你自己的类型，来解决你的具体需求。通过让类型更加严密，我们可以在程序测试或运行之前，就利用 Swift 的类型检验优势，来避免许多错误。

### 纯函数式数据结构

所谓纯函数式数据结构 (Purely Functional Data Structures) 指的是那些具有不变性的高效的数据结构。

这里主要封装了二叉搜索数以及字典树

### 探究案例：图标（未细看代码）

在本章中，我们会看到一种描述图表的函数式方式，并讨论如何利用 Core Graphics 来绘制它们。通过对 Core Graphic 进行一层函数式的封装，可以得到一个更简单且易于组合的 > API。

本章会更进一步：不再立刻执行绘制指令，而是构造一个中间层数据结构来对图表进行描述。

当我们将本章中构建的库与第二章中的库进行对比时，可以看到很多相似点。两者都是针对某个问题领域 (区域和图表)，并且创建了一个小巧的函数库来描述这个领域。两个库都通过函数提供了一个高度可组合的接口。这两个库都定义了一种领域特定语言 (domain-specific language，简称 DSL)，并将其嵌入在 Swift 中。每种 DSL 都具有针对性，它们是用于解决特定问题的小型编程语言。

### 迭代器和序列

迭代器 (Iterators) 和序列 (Sequences)组成了Swift中 for循环的基础体系。

从概念上来说，一个迭代器是每次根据请求生成数组新元素的“过程”。任何类型只要遵守以下协议，那么它就是一个迭代器：

```swift
protocol IteratorProtocol {
    associatedtype Element
    mutating func next() -> Element?
}
```

举个例子，下面的迭代器会从数组末尾开始生成序列值。(其中这里生成的是index也就是位置)

```swift
struct ReverseIndexIterator: IteratorProtocol {
    var index: Int
    init<T>(array: [T]) {
        index = array.endIndex-1
    }
    mutating func next() -> Int? {
        guard index >= 0 else { return nil }
        defer { index -= 1 }
        return index
    }
}
// 使用如下
let letters = ["A", "B", "C"]
()
var iterator = ReverseIndexIterator(array: letters)
while let i = iterator.next() {
    print("Element \(i) of the array is \(letters[i])")
}
/*
Element 2 of the array is C
Element 1 of the array is B
Element 0 of the array is A
*/
```

通过这种定义迭代器的方式，我们将数据的生成与使用分离开来。

基于为迭代器定义的协议，我们还可以编写一些适用于所有迭代器的泛型函数。（例如find方法）

```swift
extension IteratorProtocol {
    mutating func find(predicate: (Element) -> Bool) -> Element? {
        while let x = next() {
            if predicate(x) {
                return x
            }
        }
        return nil
    }
}
```

**迭代器为 Swift 另一个协议提供了基础类型，这个协议就是序列。**

迭代器提供了一个“单次触发”的机制以反复地计算出下一个元素。这种机制不支持返查或重新生成已经生成过的元素，我们想要做到这个的话就只能再创建一个新的迭代器。协议 SequenceType 则为这些功能提供了一组合适的接口：

```swift
protocol Sequence {
    associatedtype Iterator: IteratorProtocol
    func makeIterator() -> Iterator
    // ...
}
```

每一个序列都有一个关联的迭代器类型和一个创建新迭代器的方法。我们可以据此使用该迭代器来遍历序列。

```swift
struct ReverseArrayIndices<T>: Sequence {
    let array: [T]
    init(array: [T]) {
        self.array = array
    }
    func makeIterator() -> ReverseIndexIterator {
        return ReverseIndexIterator(array: array)
    }
}
// 使用
var array = ["one", "two", "three"]
let reverseSequence = ReverseArrayIndices(array: array)
var reverseIterator = reverseSequence.makeIterator()
while let i = reverseIterator.next() {
    print("Index \(i) is \(array[i])")
}
/*
Index 2 is three
Index 1 is two
Index 0 is one
*/
```

对比之前仅仅使用迭代器的例子，同一个序列可以被第二次遍历 —— 为此我们只需要调用 makeIterator() 来生成一个新的迭代器就可以了。通过在 Sequence 的定义中封装迭代器的创建过程，开发者在使用序列时不必再担心潜在的迭代器创建问题。这与面向对象理念中的将使用和创建进行分离的思想是一脉相承的，代码亦由此具有了更高的内聚性。

上面的代码你也可以用for循环调用：

```Swift
for i in ReverseArrayIndices(array: array) {
    print("Index \(i) is \(array[i])")
}
/*
Index 2 is three
Index 1 is two
Index 0 is one
*/
```

Swift 所做的只是使用 makeIterator() 方法生成了一个迭代器，然后重复地调用其 next 方法直到返回 nil。

序列也具有标准的 map 和 filter 方法：

```swift
public protocol Sequence {
    public func map<T>(
    _ transform: (Iterator.Element) throws -> T)
    rethrows -> [T]
    public func filter(
    _ isIncluded: (Iterator.Element) throws -> Bool)
    rethrows -> [Iterator.Element]
}
```

这些 map 和 filter 方法不会返回新的序列，而是遍历序列来生成一个数组。

### 案例研究：解析器组合算子

在试图将一系列符号 (通常是一组字符) 转换为结构化的数据时，解析器 (parser) 是一个非常有用的工具。

###### 在实现这个解析器组合算子库的核心部分之前，我们需要先思考一个解析器实际上都要做些什么。通常而言，一个解析器会接收一组字符 (一个字符串) 作为输入，如果解析成功，则返回一些结果值与剩下的字符串。如果解析失败，则什么也不返回。我们可以将整个过程总结为一个像下面这样的函数类型：

```swift
typealias Parser<Result> = (String) -> (Result, String)?
// 因为性能问题 所以用 Stream
typealias Stream = String.CharacterView
typealias Parser<Result> = (Stream) -> (Result, Stream)?

struct Parser<Result> {
    typealias Stream = String.CharacterView
    let parse: (Stream) -> (Result, Stream)?
    // 这是一个便利构造器
    func character(matching condition: @escaping (Character) -> Bool)
    -> Parser<Character> {
        return Parser(parse: { input in
        // ...
        })
    }
    //比如这里判断第一个字符是否匹配 condition 中的条件
    func character(condition: @escaping (Character) -> Bool) -> Parser<Character> {
        return Parser { input in
            guard let char = input.first, condition(char) else { return nil }
            return (char, input.dropFirst())
        }
    }
}
// 测试方便在加入一个run扩展方法
extension Parser {
    func run(_ string: String) -> (Result, String)? {
        guard let (result, remainder) = parse(string.characters) else { return nil }
        return (result, String(remainder))
    }
}
one.run("123") // Optional(("1", "23"))

// 我们目的是检查数字而不是1，所以还需要写一个扩展
// 为了检查某个字符是不是十进制数字，我们要用到标准库中的 CharacterSet 类。CharacterSet 的 contains 方法希望接收的是一个类型为 UnicodeScalar 的值，但我们希望检查的值的类型却是一个 Character。
extension CharacterSet {
    func contains(_ c: Character) -> Bool {
        let scalars = String(c).unicodeScalars
        guard scalars.count == 1 else { return false }
        return contains(scalars.first!)
    }
}
// 然后就变成这样了
let digit = character { CharacterSet.decimalDigits.contains($0) }
digit.run("456") // Optional(("4", "56"))
```

这样 一个原子的解析器就完成了，接下来就需要把它们组合起来变为更强大的解析器。首先，我们会创建一个组合算子 many，用于多次执行某个解析器并将解析结果作为一个数组返回。

```swift
extension Parser {
    var many: Parser<[Result]> {
    // ...
    }
}

extension Parser {
    var many: Parser<[Result]> {
        return Parser<[Result]> { input in
            var result: [Result] = []
            var remainder = input
            while let (element, newRemainder) = self.parse(remainder) {
                result.append(element)
                remainder = newRemainder
            }
        return (result, remainder)
        }
    }
}
digit.many.run("123") // Optional((["1", "2", "3"], ""))
```

既然我们可以将多个数字解析为一个字符串数组，那仅剩的步骤只是将字符数组转换为一个整数。为了完成这个任务，我们将为 Parser 定义一个 map 方法:

```swift
extension Parser {
    func map<T>(_ transform: @escaping (Result) -> T) -> Parser<T> {
        return Parser<T> { input in
            guard let (result, remainder) = self.parse(input) else { return nil }
            return (transform(result), remainder)
        }
    }
}

```

那现在就可以完成我们想要的解析了

```swift
let integer = digit.many.map { Int(String($0))! }
integer.run("123") // Optional((123, ""))
integer.run("123abc") // Optional((123, "abc"))
```

#### 顺序解析

其实我们有时候需要的是想要解析一个像 "2*3" 这样的乘法表达式，我们需要解析的是一个整数，接下来的符号 "*"，以及另一个整数。

出于这个目的，我们将引入一个顺序组合算子 followed(by:)。就像实现 many 那样，我们将这个组合算子作为 Parser 的一个方法来实现。

```swift
extension Parser {
    func followed<A>(by other: Parser<A>) -> Parser<(Result, A)> {
        return Parser<(Result, A)> { input in
            guard let (result1, remainder1) = self.parse(input) else { return nil }
            guard let (result2, remainder2) = other.parse(remainder1)
            else { return nil }
            return ((result1, result2), remainder2)
        }
    }
}
let multiplication = integer
.followed(by: character { $0 == "*" })
.followed(by: integer)
multiplication.run("2*3") // Optional((((2, "*"), 3), "")
let multiplication2 = multiplication.map { $0.0 * $1 }
multiplication2.run("2*3") // Optional((6, ""))
```

