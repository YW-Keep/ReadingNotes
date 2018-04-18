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