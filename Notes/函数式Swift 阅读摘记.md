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

