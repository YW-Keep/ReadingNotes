## Swift 与开发环境及一些实践

### 1.Swift 命令行工具

Swift 其实是有Read-Eval-Print Loop环境（直接运行代码，能查看中间变量，输出值-- **应答式编程器**）。要指出的是，REPL 环境只是表现得像是即时的解释执行，但是其实质还是每次输入代码后进行编译再运行。这就限制了我们不太可能在 REPL 环境中做很复杂的事情。

另一个用法是直接将一个 .swift 文件作为命令行工具的输入，这样里面的代码也会被自动地编译和执行。我们甚至还可以在 .swift 文件最上面加上命令行工具的路径，然后将文件权限改为可执行，之后就可以直接执行这个 .swift 文件了：

```swift
#!/usr/bin/env swift
print("hello")
// Terminal
> chmod 755 hello.swift
> ./hello.swift

// 输出：
hello
```

相对于直接用 swift 命令执行，Swift 命令行工具的另一个常用的地方是直接脱离 Xcode 环境进行编译和生成可执行的二进制文件。我们可以使用 swiftc 来进行编译，比如下面的例子：

```swift
// MyClass.swift
class MyClass {
    let name = "XiaoMing"
    func hello() {
        print("Hello \(name)")
    }
}

// main.swift
let object = MyClass()
object.hello()
// 生成一个名叫 main的可执行文件
> swiftc MyClass.swift main.swift

> ./main
// 输出：
// Hello XiaoMing
```

利用这个方法，我们就可以用 Swift 写出一些命令行的程序了。这也算一个Swift的应用方向吧。

### 2.随机数生成

arc4random 是一个非常优秀的随机数算法，并且在 Swift 中也可以使用。但是在iPhone 5 以及以下手机有一半概率会崩，因为Swift的In与架构有关在32位的CPU上是Int32而64位是Int64,而arc4random返回的是UInt32，所以在转化的过程中是有一半的概率会崩溃的。这种情况下，一种相对安全的做法是使用一个 arc4random 的改良版本：arc4random_uniform,这个改良版本接受一个UInt32的数字n作为n  讲结果归一化到0到n - 1 之间。这里有一个比较好的版本：

```swift
func random(in range: Range<Int>) -> Int {
    let count = UInt32(range.endIndex - range.startIndex)
    return  Int(arc4random_uniform(count)) + range.startIndex
}

for _ in 0...100 {
    let range = Range<Int>(1...6)
    print(random(in: range))
}
```

### 3.print 和debugPrint

description  与debugDescription  方法重写 ，就可以改变print ，debugPrint输出。当你断点调试是用po打出来的内容就是debugDescription的内容。 另外值得要提的是debugPrint()方法只是输出debugDescription内容而不是只在debug环境下输出。如果要提高性能，值在debug环境下输出还是需要自己封装的。

### 4.错误和异常处理

一般说的异常是程序出错引起的，比如数组越界等等。而错误是指在用户操作过程中出现的问题，比如登录时账号密码错误等。

在Objective-C中我们调用会发生错误的一般是这样的

```objective-c
NSError *error;
BOOL success = [data writeToFile: path options: options error: &error];
if(error) {
    // 发生了错误
}
// 但是很多人并不关心错误，也没遇到过错误。。所以为像下面这样调用
[data writeToFile: path options: options error: nil];
// 其实这样是不合理，其实是会出错的，比如磁盘空间满了
```

而在Swift中变成了下面这种样式：

```Swift
let d = NSData()

do {
    try d.write(toFile: "Hello", options: [])
} catch let error as NSError {
    print ("Error: \(error.domain)")
}
```

其实这么写也是对之前的一种妥协，如果，你自己写一般下面这种方式比较合理：

```swift
enum LoginError: Error {
    case UserNotFound, UserPasswordNotMatch
}

func login(user: String, password: String) throws {
    let users = [String: String]()

    if !users.keys.contains(user) {
        throw LoginError.UserNotFound
    }
    
    if users[user] != password {
        throw LoginError.UserPasswordNotMatch
    }
    
    print("Login successfully.")
}

do {
    try login(user: "onevcat", password: "123")
} catch LoginError.UserNotFound {
    print("UserNotFound")
} catch LoginError.UserPasswordNotMatch {
    print("UserPasswordNotMatch")
}
```

其实这样也有点问题。比如在调用该方法时，我们并不知道错误了会有什么东西被抛出。另外就是对于非同步的API抛出异常是不可以用的。那么非同步的使用应该用什么呢？（比如网络请求）其实答案也很简单，那就是用枚举。

另外try 可以增加？表示来进行尝试性的运行。try? 会返回一个 Optional 值：如果运行成功，没有抛出错误的话，它会包含这条语句的返回值，否则将为 nil。

### 5.断言

断言 (assertion) 在 Cocoa 开发里一般用来在检查输入参数是否满足一定条件，并对其进行“论断”。断言主要用在API中一些条件的控制，比如水温，因为是水不是冰所以不会低于零下一度。当然你可以用if else进行判断，但是它会增大开销，而断言不同，它是一个开发时的特性，只有在 Debug 编译的时候有效，而在运行时是不被编译执行的，因此断言并不会消耗运行时的性能。

```swift

let absoluteZeroInCelsius = -273.15
func convertToKelvin(_ celsius: Double) -> Double {
    assert(celsius > absoluteZeroInCelsius, "输入的摄氏温度不能低于绝对零度")
    return celsius - absoluteZeroInCelsius
}

let roomTemperature = convertToKelvin(27)
// roomTemperature = 300.15

let tooCold = convertToKelvin(-300)
// 运行时错误:
// assertion failed:
// 输入的摄氏温度不能低于绝对零度 : file {YOUR_FILE_PATH}, line {LINE_NUMBER}
```

另外要提一句，原本在Objective-C中使用的断言函数NSAssert在swift中已经被移除了。

### 6.fatalError

在调试时我们可以使用断言来排除类似这样的问题，但是断言只会在 Debug 环境中有效，而在 Release 编译中所有的断言都将被禁用。在遇到确实因为输入的错误无法使程序继续运行的时候，我们一般考虑以产生致命错误 (fatalError) 的方式来终止程序。下面是fatalError的定义：

```Swift
// @noreturn 正如其名 就是不需要返回值的。
@noreturn func fatalError(@autoclosure message: () -> String = default,
                                          file: StaticString = default,
                                          line: UInt = default)
```

还有一个地方fatalError 会比较常见 就是在重写init方法后 要求重写init(coder:NSCoder)方法，默认实现就是：

```swift
required init(coder: NSCoder) {
  fatalError("NSCoding not supported")
}
```

### 7.代码组织和FrameWork

swift不稳定，制作framwork….嗯 还是算了吧 。要做还是可以做的，只是做了之后，swift不保证向下兼容，所以如果改了就会很麻烦比如只能XXX版本的 用XXX版本的framework。所以暂时最好的实践还是用Objective-C做框架吧。当然等swift稳定了，也可以用swift做。

### 8.安全的资源组织方式

Objective-C一般用宏定义把资源文件放在一起方便修改。而Swift没有宏的概念，用enum或者struct是一个很好的选择。但是这确实也没有解决，资源文件改变找不到的问题。

### 9.Playground延迟运行

在playground上是顺序执行的，执行完了一般就结束了，所以不能进行异步操作，如果你需要异步操作，那么需要加上"扩展包" PlaygroundSupport框架。也就是说在需要在playground上面加上如下代码：

```Swift
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
```

一般来说开启后默认时间是30秒，也就是30秒后会停止，如果你想修改时间可以通过Alt + Cmd + 回车 来打开辅助编辑器。在这里你会看到控制台输出和时间轴，将右下角的 30 改成你想要的数字，就可以对延时运行的最长时间进行设定了。

### 10.Playground与项目协作

其实playground是可以导入到项目中的，支持framework的module导入使用。主要这么用的目的是做一些测试。（ps:其实感觉也不是很方便。）

### 11.Playground可视化开发

我们只要把我们想要显示的View给PlaygroundPage的liveView，并且打开Assistant Editor (Alt + Shift + Command + Return)就能看到View了。其实liveView只要满足PlaygroundLiveViewable协议就可以了那么UIViewController 其实同样也是可以的。表面上很美好，感觉我们可以在这里边写代码边看到UI的状态了，其实不行除非你把代码写在Playground上，从上面一条中我们知道，不能直接导入一个控制器的。所以感觉还是没什么用。

### 12.数学和数字

Darwin 里的 math.h 定义了很多和数学相关的内容，它在 Swift 中也被进行了 module 映射，因此在 Swift 中我们是可以直接使用的。有了这个保证，我们就不需要担心在进行数学计算的时候会和标准有什么差距。

Double中有个很神奇的东西可以表示无穷大：Double.infinity，当然这也不是真正的无穷大，它只是swiftDouble最大值大的的数1.797693134862315e+308 ，还有个计算错误时会出现的数叫做NaN表示没有这个数，这个NaN不能进行判等，只能用isNaN来判断。

### 13.JSON 和 Codable

看标题我们就能知道，这里主要聊json的解析和转化，确实Codable协议是一个很好的方式：

```swift
struct Obj: Codable {
    let menu: Menu
    struct Menu: Codable {
        let id: String
        let value: String
        let popup: Popup
    }
    
    struct Popup: Codable {
        let menuItem: [MenuItem]
        enum CodingKeys: String, CodingKey {
            case menuItem = "menuitem"
        }
    }
    
    struct MenuItem: Codable {
        let value: String
        let onClick: String
        
        enum CodingKeys: String, CodingKey {
            case value
            case onClick = "onclick"
        }
    }
}

let data = jsonString.data(using: .utf8)!
do {
    let obj = try JSONDecoder().decode(Obj.self, from: data)
    let value = obj.menu.popup.menuItem[0].value
    print(value)
} catch {
    print(error)
}
```

### 14.NSNull

在 Objective-C 中，因为 NSDictionay 和 NSArray 只能存储对象，对于像 JSON 中可能存在的 null 值，NSDictionay 和 NSArray 中就只能用 NSNull 对象来表示。

在 Objective-C 中，我们一般通过严密的判断来解决这个问题：即在每次发送消息的时候都进行类型检查，以确保将要接收消息的对象不是 NSNull 的对象。另一种方法是添加 NSNull 的 category，让它响应各种常见的方法 (比如 integerValue 等)，并返回默认值。

而在 Swift 中，这个问题被语言的特性彻底解决了。因为 Swift 所强调的就是类型安全，无论怎么说都需要一层转换。

### 15.文档注释

Xcode 8 中自带了注释文档生成的工具，你可以在想要添加注释的方法或者属性上方使用快捷键 (默认是 Alt + Cmd + /)，它就能够帮助你快速并且自动地生成符合格式的文档注释模板，你需要做的只是填上你需要的描述。

### 16.性能考虑

因为OC调用方法是进行时分发，而Swift是在编译时基本确定调用方法，所以Swift的性能会好于OC，所以减少NSObject的使用多实用Swift类能得到更多的性能提升。

### 17.Log输出

在swift中比较好的Log输出是自己写一个方法：

```swift
// 其中 #file 表示包含这个符号的文件的路径  string
// #line 符号出现处的行号 int
// #column 符号出现的列 int
// #function 包含这个符号的方法名字  string
func printLog<T>(_ message: T,
                    file: String = #file,
                  method: String = #function,
                    line: Int = #line)
{
    #if DEBUG
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}
```

### 18.溢出

开发的时候有时候要考虑设备的位数。