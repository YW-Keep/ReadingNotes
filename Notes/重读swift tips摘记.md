##重读swifter tips摘记
###1.柯里化
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

### 6.