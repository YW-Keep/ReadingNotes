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