##  从 Objective-C/C 到 Swift

### 1.Selector

selector在Objective-C中，其实是runtime里的东西。但是在swift也可以这么用：

```SWIFT
class MyObject: NSObject {
    @objc func callMe() {
        //...
    }
    
    @objc func callMeWithParam(obj: AnyObject!) {
        //...
    }
    
    @objc func turn(by angle: Int, speed: Float) {
        //...
    }
    
    func selectors() -> [Selector] {
        let someMethod = #selector(callMe)
        let anotherMethod = #selector(callMeWithParam(obj:))
        let method = #selector(turn(by:speed:))

        return [someMethod, anotherMethod, method]
    }
    
    func otherSelectors() -> [Selector] {
        let someMethod = #selector(callMe)
        let anotherMethod = #selector(callMeWithParam)
        let method = #selector(turn)
        
        return [someMethod, anotherMethod, method]
    }
    
    
    @objc func commonFunc() {
        
    }
    
    @objc func commonFunc(input: Int) -> Int {
        return input
    }
    
    func sameNameSelectors() -> [Selector] {
        let method1 = #selector(commonFunc as ()->())
        let method2 = #selector(commonFunc as (Int)->Int)
        return [method1, method2]
    }
}

```

上面的例子有两点需要补充：

1.大家看到  @objc了，其实就是转成Objective-C的方法。这里有人会觉得很疑惑，为什么我在swift3中时候好像可以不用写，到swift4就要写了呀，其实原理也很简单，在swift3 和之前的版本中，Apple为了更好的Objective-C兼容性，会自动对NSObject的子类的非私有方法进行推断并，自动加上@objc。而在swift4中，默认情况下所有的swift方法在Objective-C中都是不可见的，所以需要加上 @objc关键词。

2.如果在同一个作用域中存在同样名字的两个方法，即使他们的函数签名不相同，编译器也不允许编译通过（见例子下半部分）。我们可以通过将方法进行强制转换来使用。

### 2.实例方法的动态调用

这快其实之前讲过，就是柯里化的方法。这里要注意，如果类方法与对象方法签名相同，默认是类方法获取的（见例子下面）。

```swift
class MyClass {
    func method(number: Int) -> Int {
        return number + 1
    }
}

let object = MyClass()
let result = object.method(number: 1)
// result = 2


let f = MyClass.method
let object1 = MyClass()
let result1 = f(object)(1)


class MyClass1 {
    func method(number: Int) -> Int {
        return number + 1
    }
    
    class func method(number: Int) -> Int {
        return number
    }
}

let f1 = MyClass1.method
// class func method 的版本

let f2: (Int) -> Int = MyClass1.method
// 和 f1 相同

let f3: (MyClass1) -> (Int) -> Int = MyClass1.method
// func method 的柯里化版本
```

### 3.单例

在Objective-C中，我们的单例一般是这么写的：

```objective-c
@implementation MyManager
+ (id)sharedManager {
    static MyManager * staticInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}
@end
```

这段代码其实也很简单dispatch_once_t保证了创建方法只调用一次，在swift3.0之前你可以完全仿照这个写个swift版本。（swift3.0移除dispatch_once，当然你也可以自己写一个）

其实用swift中的let属性我们就能很简单的写个单利了：

```swift
class MyManager  {
    static let shared = MyManager()
    private init() {}
}
```

### 4.条件编译

swift中系统自带的条件编译比较少，只有os():macOS, iOS, tvOS, watchOS, Linux,arch():x86_64, arm, arm64, i386,swifr():>=某个版本。用法类似于：

```Swift
#if os(macOS)
    typealias Color = NSColor
#else
    typealias Color = UIColor
#endif
```

当然也可以自定义编译条件，只需要在项目的编译选项中进行设置，在项目的 Build Settings 中，找到 Swift Compiler - Custom Flags,在其中进行设置就可以了。

### 5. 编译标记

swift中可以标记// MARK: 可以注释当然需要加线 可以加上-。另外如果想要获得类似于#warning效果可以自己在编译时加上。例如加入TODO:与FIXME:警告可以在Build Phases 中的Run Script中加入如下代码：

```Shell
TAGS="TODO:|FIXME:"
echo "searching ${SRCROOT} for ${TAGS}"
find "${SRCROOT}" \( -name "*.swift" \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "($TAGS).*\$" | perl -p -e "s/($TAGS)/ warning: \$1/"
```

### 6.@UIApplicationMain

在Objective-C中APP启动其实一般都会有个main方法调用:

```objective-c
int main(int argc, char * argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

而在swift项目中，你可能找不到main.m该文件。但是细心的你肯定会发现@UIApplicationMain。这个标签做的事情就是将被标注的类作为委托，去创建一个 UIApplication 并启动整个程序。在编译的时候，编译器将寻找这个标记的类，并自动插入像 main 函数这样的模板代码。当然，如果你想自己实现，也是可以，只要加入main.swift文件就可以了。 比如你要复写发送事件方法，打印事件，你就可以自己写一个main.swift ，传入自己的AppDelegate子类。（当然，你也可以直接在这个子类上加上）

### 7.@objc 和 dynamic

Objective-C与Swift混合开发(需要桥接)，如果暴露给OC用可以加上@objc，@objc还可以写在方法内修改在oc调用时的方法名，但是要注意**添加@objc并不意味着这个方法或者属性会动态派发**，如果需要用运行时特性就需要使用dynamic修饰符。

```SWIFT
@objc(MyClass)
class 我的类 {
    @objc(greeting:)
    func 打招呼(名字: String) {
        print("哈喽，\(名字)")
    }
}
```

### 8.可选协议与协议扩展

其实在Objective-C中很多协议是有可选协议的，而Swift中并没有一个类似于optional 修饰符修饰可选方法。这样的话。如果你要实现可选方法就有两条路：1.转化为Objective-C中的协议（都加上@objc ），然后用optional修饰可选。这种方式有个缺点，就是只能用于class中了，struct 与enum中是没办法用的。2.扩展协议，在扩展中给出默认实现（第一篇中有类似的代码）。这样就必须的协议就变成可选协议了。我个人更喜欢第二种方式，更swift一些，哈哈。

### 9.内存管理，weak和unowned

Swift是自动管理内存的。（自动引用计数ARC） 所以一般情况下我们不需要去关心内存问题。但是特殊情况还是需要自己注意和手动处理的，就是循环引用。这是用需要用weak、unowned去解循环引用。那么这两个修饰符有什么区别呢。其实weak和Objective-C的weak是一样的，而unowned和Objective-C的unsafe_unretained其实是一样的。就是说当用weak修饰时，内存被释放了，它会自动变成nil，而unowned不会。**(因此swift被标记为 @weak 的变量一定需要是 Optional 值。)**关于两者使用的选择，Apple 给我们的建议是如果能够确定在访问时不会已被释放的话，尽量使用 unowned，如果存在被释放的可能，那就选择用 weak。另外在闭包参数的位置进行标注的语法结构是将要标注的内容放在原来参数的前面，并使用中括号括起来。

### 10.@autoreleasepool

其实自动释放池基本已经没有了使用的场景，当然如果你某些地方需要使用时，也是可以使用的，用法与Objective-C不同，改成了autoreleasepool这样一个方法。

这里需要列出一个使用场景，就是在循环过程中，创建了大量占据内存的Autorelease的对象时候，就需要用自动释放池来嵌在循环内，从而降低内存。（PS：这种方式创建和释放自动释放时会损耗大量性能，所以说权衡这两个之间的关系十分重要。比如说，我可以创建一个自动释放池,10次循环后释放。）

聊到这里可以在考虑下 什么是Autorelease的对象。其实Autorelease的对象就是自动释放池会持有的对象，也就是说只有自动释放池释放时才会释放的对象。

那么哪些创建出来的是Autorelease的对象呢？其实也很简单，一般来说**除了**alloc/new/copy/mutableCopy以外的方法创建的都是Autorelease的对象。可能会有人问为什么答案也很简单，上述几个方法创建完是开辟空间直接赋值。而其他方法创建是在另外的方法中，先会在局部区域（方法中创建（一般用alloc创建)）创建一个局部变量，如果他只是局部变量它就传不出来了，所以需要加入到autoreleasepool中让它持有，这样就可以传出来赋值了。

### 11.值类型与引用类型

值类型与引用类型的区别主要在于传递和赋值时，值类型是复制一个而引用类型是引用一个。swift中所有的内建类型都是值类型（包括String Array Dictionary struct enum…）而使用值类型的一个好处就是减少了堆上内存的分配和回收次数。swift中也是在必要时候才进行值类型的复制，从而减小消耗。当然值类型最大的好处就是安全。另外因为值类型的增删都会引起赋值，所以这种情况下内存消耗也不容忽视。所以在变动多数据大的情况下数组字典还是用NSMutableArray、NSMutableDictionary 这种引用类型比较好。

### 12.String 与NSString

在string与NSString的选择上，更倾向于string。主要原因有1.Cocoa的API都接受和返回String。2.string是struct更符合不变的特性。而NSString是NSObject。3.string实现了Collection等协议可以用for…in 而NSString 没有。当然string也有其不好的地方，那就是在字符串的截取上，它需要使用String.Index，没有NSString方便。例如：

```swift
let nsRange = NSMakeRange(1, 4)
// 编译错误
// Cannot convert value of type `NSRanve` to expected argument type 'Range<Index>'
//levels.replacingCharacters(in: nsRange, with: "AAAA")

let indexPositionOne = levels.index(levels.startIndex, offsetBy: 1)
let swiftRange = indexPositionOne ..< levels.index(levels.startIndex, offsetBy: 5)
levels.replacingCharacters(in: swiftRange, with: "AAAA")
// 输出：
// AAAAA

(levels as NSString).replacingCharacters(in: nsRange, with: "AAAA")
```

### 13.UnsafePointer

swift中其实也有一套与C打交道的东西就是UnsafePointer，即指针操作。而C中的 const Type* 就是UnsafePointer 而C中的 Type*就是UnsafeMutablePointer。而因为NSArray里是可以放任何东西的所以需要一个强制转化的方法unsafeBitCast，它会将第一个参数的内容按照第二个参数的类型进行转换，而不去关心实际是不是可行，这也正是 UnsafePointer 的不安全所在，因为我们不必遵守类型转换的检查，而拥有了在指针层面直接操作内存的机会。总而言之，这些东西能不用就别用，可以在高级抽象层编写代码就在高级抽象层，保证高效与正确。

```Swift
func method(_ num: UnsafePointer<CInt>) {
    print(num.pointee)
}

// Swift
var a: CInt = 123
method(&a)    // 输出 123

let arr = NSArray(object: "meow")
let str = unsafeBitCast(CFArrayGetValueAtIndex(arr, 0), to: CFString.self)
// str = "meow"
```

### 14.C指针的内存管理

之所以C指针在Swift中被冠名为unsafe,还有个很大的原因是它需要手动管理内存。而管理的基本原则就是谁创建谁释放。deallocate 与 deinitialize 应该要和 allocate 与 initialize 成对出现，如果不是你创建的指针，那么一般来说你就不需要去释放它。其实也可以使用 malloc 或者 calloc 来完成内存申请，这种情况下在释放时我们需要对应使用 free 而不是 deallocate。

```swift
class MyClass {
    var a = 1
    deinit {
        print("deinit")
    }
}

var pointer: UnsafeMutablePointer<MyClass>!

pointer = UnsafeMutablePointer<MyClass>.allocate(capacity: 1)
pointer.initialize(to: MyClass())

print(pointer.pointee.a)
pointer.deinitialize(count:1)
pointer.deallocate()
pointer = nil
```

### 15.COpaquePointer 和 C convention

在 C 中有一类指针，你在头文件中无法找到具体的定义，只能拿到类型的名字，而所有的实现细节都是隐藏的。这类指针在 C 或 C++ 中被叫做不透明指针 (Opaque Pointer)，顾名思义，它的实现和表意对使用者来说是不透明的。

在 Swift 中对应这类不透明指针的类型是 COpaquePointer，它用来表示那些在 Swift 中无法进行类型描述的 C 指针。COpaquePointer，现在已经很少见到了，最多的地方可能是和特定的Unsafe之间转化了。

另外一种重要的指针形式是指向函数的指针，在 C 中这种情况也并不少见，即一块存储了某个函数实际所在的位置的内存空间。从 Swift 2.0 开始，与这类指针可以被转化为闭包，不过和其他普通闭包不同，我们需要为它添加上 @convention 标注。在没有歧义的情况下，我们甚至可以省掉这个标注。

```swift
int cFunction(int (callback)(int x, int y)) {
    return callback(1, 2);
}
let callback: @convention(c) (Int32, Int32) -> Int32 = {
    (x, y) -> Int32 in
    return x + y
}

let result = cFunction(callback)
print(result)
// 输出：
// 3

let result = cFunction {
    (x, y) -> Int32 in
    return x + y
}
print(result)
// 输出：
// 3
```

### 16.GCD 和延迟调用

swift 中可以无缝使用GCD的API而且比Objective-C更加简单方便，下面就是一个最经典的例子：

```Swift
// 创建目标队列
let workingQueue = DispatchQueue(label: "my_queue")

// 派发到刚创建的队列中，GCD 会负责进行线程调度
workingQueue.async {
    // 在 workingQueue 中异步进行
    print("努力工作")
    Thread.sleep(forTimeInterval: 2)  // 模拟两秒的执行时间
    
    DispatchQueue.main.async {
        // 返回到主线程更新 UI
        print("结束工作，更新 UI")
    }
}
```

日常开发过程中经常会遇到延迟调用的问题，而swift创建一个selector并不是一件安全的事情，所以performSelector:这套就不太好用。其实GCD有一套很好用的延迟调用。在 iOS 8 中 GCD 得到了惊人的进化，现在我们可以通过将一个闭包封装到 DispatchWorkItem 对象中，然后对其发送 cancel，来取消一个正在等待执行的 block。取消一个任务这样的特性，这在以前是 NSOperation 的专利，但是现在我们使用 GCD 也能达到同样的目的了。这里我们不使用这个方式，而是通过捕获一个 cancel 标识变量来实现 delay call 的取消。代码都在下面例子中有兴趣的可以看一下：

```Swift
import Foundation

typealias Task = (_ cancel : Bool) -> Void

func delay(_ time: TimeInterval, task: @escaping ()->()) ->  Task? {
    
    func dispatch_later(block: @escaping ()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    
    
    
    var closure: (()->Void)? = task
    var result: Task?
    
    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    
    return result;
    
}

func cancel(_ task: Task?) {
    task?(true)
}

delay(2) { print("2 秒后输出") }

let task = delay(5) { print("拨打 110") }

// 仔细想一想..
// 还是取消为妙..
cancel(task)
```

### 17.获取对象类型

Swift中无论是纯Swift的clss还是NSObject的子类，都没有了class()方法了。而NSObject的子类其实例的存储方式并没有发生变换，所以还是可以通过Objective-C的运行时来获取：

```Swift
let date1 = NSDate()
let name1: AnyClass! = object_getClass(date1)
print(name1)
// 输出：
// __NSDate
//其中 object_getClass 是一个定义在 ObjectiveC 的 runtime 中的方法，它可以接受任意的 AnyObject! 并返回它的类型 AnyClass! (注意这里的叹号，它表明我们甚至可以输入 nil，并期待其返回一个 nil)
```

而在Swift中其实有更好看的写法来获取一个NSObject 或其子类的对象的实际类型：

```Swift
let date2 = NSDate()
let name2 = type(of: date2)
print(name2)
// 输出：
// __NSDate
```

其实上面的方法对于一个Swift内建类型（即不用Objective-C的动态特性）比如String也是可以的。

```swift
let string = "Hello"
let name = type(of: string)
print(name)
//输出： String
debugPrint(name)
// 输出：
// Swift.String
```

### 18.自省

向一个对象发出询问，以确定它是不是属于某个类，这种操作就称为自省。

在Objective-C中自省方法有两个isKindOfClass判断是不是其或其子类的实例对象，isMemberOfClass是不是该类（子类实例对象是不行的）。

Swift中也有类似的方法：

```Swift
class ClassA: NSObject { }
class ClassB: ClassA { }

let obj1: NSObject = ClassB()
let obj2: NSObject = ClassB()

obj1.isKind(of: ClassA.self)    // true
obj2.isMember(of: ClassA.self)  // false
```

这是用于判断NSObject子类的方法，那些原生的Swift类型该怎么判断呢，其实可以用is

```Swift
let obj: AnyObject = ClassB()

if (obj is ClassA) {
    print("属于 ClassA")
}

if (obj is ClassB) {
    print("属于 ClassB")
}
```

is 在功能上相当于原来的 isKindOfClass，可以检查一个对象是否属于某类型或其子类型。is 和原来的区别主要在于亮点，首先它不仅可以用于 class 类型上，也可以对 Swift 的其他像是 struct 或 enum 类型进行判断。

另外，编译器将对这种检查进行必要性的判断：如果编译器能够唯一确定类型，那么 is 的判断就没有必要，编译器将会抛出一个警告，来提示你并没有转换的必要。

### 19.KeyPathh 和 KVO

和属性观察不同，KVO 的目的并不是为当前类的属性提供一个钩子方法，而是为了其他不同实例对当前的某个属性 (严格来说是 keypath) 进行监听时使用的。其他实例可以充当一个订阅者的角色，当被监听的属性发生变化时，订阅者将得到通知。

这是一个很强大的属性，通过 KVO 我们可以实现很多松耦合的结构，使代码更加灵活和强大：像通过监听 model 的值来自动更新 UI 的绑定这样的工作，基本都是基于 KVO 来完成的。

其实KVO的实现是基于KVC(Key-ValueCoding)以及动态派发技术实现的，这些都是Objective-C的运行时的东西。所以KVO仅限在于NSObject的子类中。

Swift为了效率是默认警用动态派发的，所以想要Swift来实现KVO。需要把观测的对象标记为dynamic和@objc。

```Swift
class MyClass: NSObject {
    @objc dynamic var date = Date()
}

private var myContext = 0
// 这是swift 4 之前的写法
class Class: NSObject {
    
    var myObject: MyClass!
    
    override init() {
        super.init()
        myObject = MyClass()
        print("初始化 Class，当前日期: \(myObject.date)")
        myObject.addObserver(self,
         forKeyPath: ("date"),
            options: .new,
            context: &myContext)

        delay(1) {
            self.myObject.date = Date()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                            of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                              context: UnsafeMutableRawPointer?)
    {
        if let change = change, context == &myContext {
            if let newDate = change[.newKey] as? Date {
                print("Class 日期发生变化 \(newDate)")
            }
        }
    }
}

_ = Class()

// 这是swift4 的写法 更加简洁方便
class AnotherClass: NSObject {
    var myObject: MyClass!
    var observation: NSKeyValueObservation?
    override init() {
        super.init()
        myObject = MyClass()
        print("初始化 AnotherClass，当前日期: \(myObject.date)")
        observation = myObject.observe(\MyClass.date, options: [.new]) { (_, change) in
            if let newDate = change.newValue {
                print("AnotherClass 日期发生变化 \(newDate)")
            }
        }
        
        delay(1) { self.myObject.date = Date() }
    }
}

delay(2) {
    _ = AnotherClass()
}
// 这是一种方式来观察之前没有增加 @objc dynamic的属性的。
class MyClass1: NSObject {
    var date = Date()
}
class MyChildClass: MyClass1 {
    @objc dynamic override var date: Date {
        get { return super.date }
        set { super.date = newValue }
    }
}
```

而如果遇到观察的无法修改源码的时候可以用子类的方式重载。当然那些非NSObject类型的就只能同属性观察来实现了。（还可以通过把swift类型进行引用封装，然后利用 KeyPath 也可以用在 Swift 类型上的显示来引入观察的机制。）

###  20.局部scope

C 系语言中在方法内部我们是可以任意添加成对的大括号 {} 来限定代码的作用范围的。这么做一般来说有两个好处，首先是超过作用域后里面的临时变量就将失效，这不仅可以使方法内的命名更加容易，也使得那些不被需要的引用的回收提前进行了，可以稍微提高一些代码的效率；另外，在合适的位置插入括号也利于方法的梳理，对于那些不太方便提取为一个单独方法，但是又应该和当前方法内的其他部分进行一些区分的代码，使用大括号可以将这样的结构进行一个相对自然的划分。

Swift中也同样可以用类似的方法：

```Swift
func local(_ closure: ()->()) {
    closure()
}

func loadView() {
    
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    view.backgroundColor = .white
    
    local {
        let titleLabel = UILabel(frame: CGRect(x: 150, y: 30, width: 200, height: 40))
        titleLabel.textColor = .red
        titleLabel.text = "Title"
        view.addSubview(titleLabel)
    }
    
    local {
        let textLabel = UILabel(frame: CGRect(x: 150, y: 80, width: 200, height: 40))
        textLabel.textColor = .red
        textLabel.text = "Text"
        view.addSubview(textLabel)
    }
    
    PlaygroundPage.current.liveView = view
}
```

其实也不需要用自定定义的local，用do这个关键词就可以了。

### 21.判等

在Object中判等一般使用isEqual: 方法。这个方法在很多类是需要重写的，如果不重写则会默认使用NSObject中的版本，那就是Objective-C的==判等（就是判断两个对象是否指向同一块内存地址）。

而Swift中的== 与Objective-C中的是不一样的 ，他是一个操作符的声明。可以实现Equatable重载操作符来实现各种判等（感觉与Objective-C中的isEqual：有些相近）。另外Swift的基本类型都重载了自己的==。而对于NSObject == 没有重载会调用isEqual：()方法，所以用==重载和 isEqual:是一样的。

另外Swift中判断指针用的是另外一个操作符：===

### 22.哈希

Swift中提供一个Hashable的协议，这个协议可以给该类型提供哈希支持。Swift的原生Dictionary中，key一定是要实现了Hashable协议的类型，而像Int或者String这样的基础类，已经实现了这个协议，因此可以做为key来使用。（可以通过hashValue查看。）

Objective-C也有一个-hash方法，重写isEqual的时候一般也要重写该方法。而在Swift中，NSObject也默认实现了Hashble，和判等一样，当访问hashValue时候会返回对应的 -hash值。

### 23.类簇

类簇 (class cluster) 确实是 Cocoa 框架中广泛使用的设计模式之一。简单来说类簇就是使用一个统一的公共的类来订制单一的接口，然后在表面之下对应若干个私有类进行实现的方式。这么做最大的好处是避免公开很多子类造成混乱，一个最典型的例子是 NSNumber。

Swift可以用工厂的方式来实现，下面有个酒的例子：

```Swift
class Drinking {
    typealias LiquidColor = UIColor
    var color: LiquidColor {
        return .clear
    }
    
    class func drinking(name: String) -> Drinking {
        var drinking: Drinking
        switch name {
        case "Coke":
            drinking = Coke()
        case "Beer":
            drinking = Beer()
        default:
            drinking = Drinking()
        }
        
        return drinking
    }
}

class Coke: Drinking {
    override var color: LiquidColor {
        return .black
    }
}

class Beer: Drinking {
    override var color: LiquidColor {
        return .yellow
    }
}

let coke = Drinking.drinking(name: "Coke")
coke.color // Black

let beer = Drinking.drinking(name: "Beer")
beer.color // Yellow

let cokeClass = NSStringFromClass(type(of: coke)) //Coke
let beerClass = NSStringFromClass(type(of: beer)) //Beer
```

### 24.调用C动态库

因为Objective-C是 C 的超集，因此在以前我们可以无缝地访问 C 的内容，只需要指定依赖并且导入头文件就可以了。但是骄傲的 Swift 的目的之一就是甩开 C 的历史包袱，所以现在在 Swift 中直接使用 C 代码或者 C 的库是不可能的。

那么问题来了 真的要用C某个库里的东西怎么办。其实办法还是有的，那就是桥接 Objective-C 就可以了。当然你也可以用Swift实现一遍库，造轮子。这边多说一句其实很多东西已经有Swift版本了，你也可以用别人造的轮子，不过建议还是用C的库，毕竟它已经经过了时间的考验了。

### 25.输出格式化

与Objective-C不同Swift不需要用占位符进行格式化输出，直接拼接就可以了，但是这样往往也会有弊端，例如在输出固定几位小数的时候，只能用string去转了。

```Swift
let a = 3;
let b = 1.234567  // 我们在这里不去区分 float 和 Double 了
let c = "Hello"
print("int:\(a) double:\(b) string:\(c)")
// 输出：
// int:3 double:1.234567 string:Hello

let format = String(format:"%.2f",b)
print("double:\(format)")
// 输出：
// double:1.23

extension Double {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

let f = ".2"
print("double:\(b.format(f))")
```

### 26.Options

Objective-C中的Options,确切的说是NS_OPTIONS，其实是枚举的一种大概的样式就是这样：

```objective-c
typedef NS_OPTIONS(NSUInteger, UIViewAnimationOptions) {
    UIViewAnimationOptionLayoutSubviews            = 1 <<  0,
    UIViewAnimationOptionAllowUserInteraction      = 1 <<  1,
    UIViewAnimationOptionBeginFromCurrentState     = 1 <<  2,

    //...

    UIViewAnimationOptionTransitionFlipFromBottom  = 7 << 20,
}
[UIView animateWithDuration:0.3
                      delay:0.0
                    options:UIViewAnimationOptionCurveEaseIn |
                            UIViewAnimationOptionAllowUserInteraction
                 animations:^{
    // ...
} completion:nil];
```

但是我们都知道，其实Swift中enum与Objective-C的已经是两个概念了（即原来的NS_ENUM对应enum）。 而NS_OPTIONS在Swift中其实是没有原生类型定义的，用的是满足OptionSetType协议的struct。使用和创建大概是这样的：

```swift
UIView.animate(withDuration: 0.3,
    delay: 0.0,
    options: [.curveEaseIn, .allowUserInteraction],
    animations: {},
    completion: nil)

struct YourOption: OptionSet {
    let rawValue: UInt
    static let none = YourOption(rawValue: 0)
    static let option1 = YourOption(rawValue: 1)
    static let option2 = YourOption(rawValue: 1 << 1)
    //...
}

YourOption.option1

[YourOption.option1, YourOption.option2]
```

### 27.数组 enumerate

在使用数组时候常常需要在枚举数组内元素同事也需要下标索引，在Objective-C中常用的是enumerateObjectsUsingBlock：这个方法。其实swift中有更好的方法，那就是enumerated方法，它可以快速的举某个数组的 EnumerateGenerator，它的元素是同时包含了元素下标索引以及元素本身的多元组。（其实这里也是一个遍历的过程，如果在算法中对时间要求较高还是遍历数组去取值比较快。）

### 28.类型编码@encode

在 Objective-C 中 @encode 使用起来很简单，通过传入一个类型，我们就可以获取代表这个类型的编码 C 字符串:

```Objective-c
char *typeChar1 = @encode(int32_t);
char *typeChar2 = @encode(NSArray);
// typeChar1 = "i", typeChar2 = "{NSArray=#}
```

这个关键字最常用的地方是在 Objective-C 运行时的消息发送机制中，在传递参数时，由于类型信息的缺失，需要类型编码进行辅助以保证类型信息也能够被传递。

因为swift使用元类型来处理类型，并且在运行时保留了这些类型的信息，所以 Swift 并没有必要保留这个关键字。我们现在不能获取任意类型的类型编码了，但是在 Cocoa 中我们还是可以通过 NSValue 的 objcType 属性来获取对应值的类型指针。

```swift
let int: Int = 0
let float: Float = 0.0
let double: Double = 0.0

let intNumber: NSNumber = int as NSNumber
let floatNumber: NSNumber = float as NSNumber
let doubleNumber: NSNumber = double as NSNumber

String(validatingUTF8: intNumber.objCType)
String(validatingUTF8: floatNumber.objCType)
String(validatingUTF8: doubleNumber.objCType)

// 结果分别为：
// {Some "q"}
// {Some "f"}
// {Some "d"}
// 注意，fromCString 返回的是 `String?`


let p = NSValue(cgPoint: CGPoint(x: 3, y: 3))
String(validatingUTF8: p.objCType)
// {Some "{CGPoint=dd}"}

let t = NSValue(cgAffineTransform: .identity)
String(validatingUTF8: t.objCType)
// {Some "{CGAffineTransform=dddddd}"}
```

### 29.C 代码调用和@asmname

如果我们导入了Darwin的C库的话，我们就可以在 Swift 中无缝地使用Darwin中定义的C函数了。我们平时开发的时候其实是不需要导入的因为UIKit或者Cocoa框架是导入了Foundation框架的。而Foundation框架包含了Darwin的导入。这里有一点要说明，在导入Darwin时，Swift为我们做了类型的自动转换对应。而用其他的第三方C代码，就需要桥接了。其实还有个方式，那就是用隐藏的符号@asmname。除了作为非头文件方式的导入之外，@asmname 还承担着和 @objc 的 “重命名 Swift 中类和方法名字” 类似的任务，这可以将 C 中不认可的 Swift 程序元素字符重命名为 ascii 码，以便在 C 中使用。

```swift
//File.swift
//将 C 的 test 方法映射为 Swift 的 c_test 方法
@asmname("test") func c_test(a: Int32) -> Int32

func testSwift(input: Int32) {
    let result = c_test(input)
    print(result)
}

testSwift(1)
// 输出：2
```

### 30.delegate

在使用delegate的时候一般与delegate会在申明的时候将其指定为weak，在这个 delegate 实际的对象被释放的时候，会被重置回 nil。（也可以间接的防止循环引用）Swift里你直接用weak修饰是不会通过的。因为 Swift 的 protocol 是可以被除了 class 以外的其他类型遵守的，而对于像 struct 或是 enum 这样的类型，本身就不通过引用计数来管理内存，所以也不可能用 weak 这样的 ARC 的概念来进行修饰。 当然 想要使用 weak delegate，也很简单，可以用@bject 转成Objective-C中的协议，还有一种在协议后面加上:class声明限定成类协议。

