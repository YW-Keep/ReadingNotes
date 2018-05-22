#### runtime问题集

##### 1.分类为什么可以加方法不能加属性？

##### 2.为什么分类加方法会覆盖之前的方法？

##### 3.super和self

下面代码输出什么：

```objective-c
@interface Man : Person

@end

@implementation Man

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"1.%@",[self class]);
        NSLog(@"2.%@",[super class]);
    }
    return self;
}

@end
```

##### 4.isa

下面代码的值是多少：

```objective-c
    BOOL res1 = [[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res2 = [[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res3 = [[Person class] isMemberOfClass:[Person class]];
    BOOL res4 = [[Person class] isKindOfClass:[Person class]];
```

##### 5.地址

下面代码输出什么：

```objective-c
@interface Person : NSObject

@property (nonatomic, strong) NSString *name;

- (void)tellName;

@end

@implementation Person

- (void)tellName {
    NSLog(@"my name is %@",self.name);
}

@end

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *hello = @"hello";
    Class cls  = [Person class];
    void *obj = &cls;
    [(__bridge id)obj tellName];

}
```

##### 6.重载

下面代码可以编译通过吗？

```objective-c
// 第一种情况
- (void)tellName;
- (void)tellName:(NSString *)name;
// 第二种情况
- (void)tellName:(NSString *)name;
- (void)tellName:(NSArray *)name;
```

##### 7.为什么给nil发送消息不会崩溃

##### 8.NSObject

下面代码会发什么？

```objective-c
@interface NSObject (DoSomething)

+ (void) doThings1;
- (void) doThings2;

@end

@implementation NSObject (DoSomething)

- (void) doThings1 {
    NSLog(@"1");
}
+ (void) doThings2 {
    NSLog(@"2");
}

@end

[NSObject doThings1];
[[NSObject new] doThings2];
```

##### 9.OC有多继承吗？那如果要实现一个多继承，该怎么办？

##### 10.为什么runtime可以实现方法替换？方法替换常用在什么地方？ 使用过程中需要注意什么？

##### 11.KVO是怎么实现的？ KVC与KVO之间有啥关系？

##### 12.关联对象怎么写的，有啥用？

##### 13.一般字典转模型，模型转字典是怎么实现的？