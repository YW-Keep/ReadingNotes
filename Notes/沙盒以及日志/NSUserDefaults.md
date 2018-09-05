#细看NSUserDefaults、NSFileManager、NSFileHandle
##沙盒路径
iOS也有自己的沙盒机制，每一个APP只能访问自己沙盒下的资源文件。每一个APP的沙盒有3个文件夹：Documents、Library（下面有Preference和Caches两个目录）、tmp，下面简单介绍下每一个文件夹放一些什么东西。
Documents:苹果建议把程序创建产生的文件以及应用浏览产生的文件数据保存在该目录下，itunes备份和恢复使包含该目录。
Libarary/Preference:存储一些偏好设置等，不应该直接在这里创建文件，所有存取创建都应该通过NSUserDefault这个类。也就是说所有通过NSUserDefault中的东西都保存在该目录下。
Library/Caches:放缓存文件，例如图片视频等，在应用升级或关闭后数据还在，但是并不会被itunes备份。所以经常用于放一些比较大的又不需要备份的文件。
tmp:临时的文件目录，没有数据持久化的功能，在应用关闭或者不运行时会把该目录下的数据清除。
下面介绍下获取沙盒路径的方式：
```
1.获取沙盒根路径
NSString *homePath = NSHomeDirectory();
2.获取Documents路径
方法一：
可以在沙盒根路径下拼接Documents
方法二：
NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
3.获取Libarary/Preference路径
NSString *preferencesPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
4.获取Library/Caches路径
NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];’
5.获取tmp路径
NSString *tmpPath = NSTemporaryDirectory();
```

##NSUserDefaults(用户默认设置)
NSUserDefauly是一种轻量级的数据持久化方法，主要用于保存用户配置信息。主要简单介绍下。 
首先初始化，初始化方法主要有三个。 
如下
```
NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
NSUserDefaults *userDefault = [[NSUserDefaults alloc] init];
NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:@"dddd"];
```
其实三个都是有联系的，第一个其实很多人好奇为什么叫重置，原因很简单，它会重新创建这个对象，主要去的区别是KVO监听会无效。第二个方法则其实就是调用了第三个方法Name为nil。那么问题全部集中在第三个方法里了，第三方法是啥呢我们来看下官方的说明
```
-initWithSuiteName: initializes an instance of NSUserDefaults that searches the shared preferences search list for the domain 'suitename'. For example, using the identifier of an application group will cause the receiver to search the preferences for that group. Passing the current application's bundle identifier, NSGlobalDomain, or the corresponding CFPreferences constants is an error. Passing nil will search the default search list.
```
其实可以简单的理解为创建一个xxx名字的list文件。用来保存你所需要报存的数据。而这里说了，如果传入nil就是默认的plist。默认的是哪个呢，就是bundle identifier名字的plist文件。这里有个系统的方法，但是iOS7后弃用了可以打印出NSUserDefaults 所有列表：
```
 NSLog(@"%@",userDefault.persistentDomainNames);
 结果：
 (
    dddd,
    "com.test.rest1"
 )
```
而这里com.test.rest1 正是我测试项目的bundle identifier，再细看文档他说，当你使用 bundle identifier、NSGlobalDomain、CFPreferences constants会报错，返回nil。从bundle identifier中不难猜出这些是系统自带的list文件，所以不能重名。
创建完成后就是存了，NSUserDefauly能存的东西也比较多，主要有这么几类，string,array,data,integer,float,double,bool,URL其实基本已经涵盖了我们所使用的全部数据类型，存与取删也十分的简单，当然只能存取不可变数据。
```
   [userDefault setObject:@[@"1",@"2",@"3"] forKey:@"userArray"];
   [userDefault arrayForKey:@"userArray"];
   [userDefault removeObjectForKey:@"userArray"];
```
主要注意的点如下：
1.NSUserDefaults的沙盒路径在Library/Preferences/ 如果拆包，导出plist文件这里的数据是只接能看到的，所以不要在这里保存敏感的信息。
2.NSUserDefaults是保存在APP本地，更新不会删除该文件内信息，所以如果你要做引导页等类似功能需要升级后变更的需要增加版本判断。
3.synchronize之前同步的方法已经被弃用了，当然你要兼容老版本可以加上。
4.iOS8之后加入了App Groups功能，可以通过NSUserDefaults进行APP之间小量的数据共享，只要开启设置一个groupName,就可以用这个group名作为suitename进行app间的数据共享了。
5.NSUserDefault中存在域的概念，包含5个部分NSArgumentDomain，Application，NSGlobalDomain，Languages，NSRegistrationDomain。
NSArgumentDomain：代表的是命令行参数，可以在Edit Scheme->Arguments->Arguments Passed On Launch中添加，格式是-key value。
Application：应用程序域，设置的方法默认数据保存是在这里
NSGlobalDomain：全局域，所有应用程序都将公用该域
Languages：国际化语言版本域
NSRegistrationDomain：临时域，- (void)registerDefaults:(NSDictionary*)registrationDictionary方法被调用是数据是保存在这里。
在读取数据时，都会在底层的存储结构中进行一次搜索，搜索的顺序是这样：NSArgumentDomain->Application->NSGlobalDomain->Languages->NSRegistrationDomain
##NSFileManager
这是一个用于操作系统文件的类，主要的功能有：判断文件是否存在，创建文件，写入文件，删除文件，复制文件，移动文件，比较文件内容，读取更改文件属性等。下面简单介绍一下一些常用的用法。
```
1.创建一个默认的对象
NSFileManager *fileManger = [NSFileManager defaultManager];
2.判断在某个目录下是否存在该文件
BOOL ishave = [fileManger fileExistsAtPath:filePath];
3.创建一个目录下的文件夹
 [fileManger createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
4.写入文件
[writeData writeToFile:filePath atomically:NO];（其实严格来说跟NSFileManager 无关）
[fileManager createFileAtPath:path contents:myData attributes:dic];//向一个文件中写入数据，属性字典允许自己制定
5.读取一个文件
NSData *myData = [fileManager contentsAtPath:path];
6.获取某一个路径下所有文件名的数组
NSArray *nameArray = [fileManger contentsOfDirectoryAtPath:self.baseLogPath error:nil];
7.删除某个文件或文件夹
[fileManger removeItemAtPath:[NSString stringWithFormat:@"%@/%@",path,file] error:nil];
8.判断一个文件路径是否为文件夹
BOOL isFolders = YES;
[fileManger fileExistsAtPath:filePath isDirectory:&isFolders];
9.获取文件夹信息 //[fileAttributes objectForKey:NSFileCreationDate] 创建日期 //[fileAttributes objectForKey:NSFileOwnerAccountName]所有者 //[fileAttributes objectForKey:NSFileModificationDate] 修改日期
NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:path traverseLink:YES];
10.复制文件夹到别处
[fileManager copyItemAtPath:path1 toPath:path2 error:error];
```
##NSFileHandle
这是一个专门管理文件的类，主要可以实现的操作有：对文件进行读写与更新，可以找到特定的位置进行修改。下面简单介绍一下常用的方法。
```
1.创建该对象
NSFileHandle* fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
2.跳转到文件末尾
[fileHandler seekToEndOfFile];
3.追加数据
[fileHandler writeData:writeData];（若在顶端填写则会覆盖之前的内容）
4.关闭文件
[fileHandler closeFile];
5.截断内容至某个字节
[fileHandler truncateFileAtOffset:0];（0即为清空该文件内容了）
6.读取全部内容
NSData *  data = [fileHandler readDataToEndOfFile];
7.读取固定长度内容
NSData *data = [fileHandler readDataOfLength:3];
```


