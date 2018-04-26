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

