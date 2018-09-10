### CocoaPods的一些思考

#### 1.CocoaPods 导入的是动态库还是静态库

其实默认情况下pods导入的是静态库，但是静态库导入经常会有一些冲突问题。当加入use_frameworks!之后打出来的就是动态库了。可以在编译后在framework里找到相应的动态库。

#### 2.CocoaPods 是如何把库加载到主工程去的？

pod 会依据 Podfile 文件里面的依赖库，把这些库的源代码下载下来，并创建好 Pods workspace。当程序编译的时候，会预先执行2个 pod 设置进来的脚本。

配置分别在Embed Pods Frameworks与Copy Pods Resources中。前者会打包相应的库，后者会打包相应的资源（这里是静态库还是动态库看怎么导入了）。

#### 3.CocoaPods的基础工作原理是什么？

其实Cocapods 有一个仓库，而这个仓库维护的就是一份份的podspec，可以理解为配置文件。我们每次更新仓库其实更新的就是这个配置文件的仓库，当我们需要某个库的时候就可以通过这份配置文件获取到相应的三方库代码。当我们编译的在打包成相应的库供我们使用。

#### 4.CocoaPods库如何创建？

1.通过`pod lib create ProjectName` 创建一个模板（其实是远程拉下来的模板）。

2.修改podspec相应的信息,放入相应的代码(库代码),可以用`pod install `更新 然后在demo项目里调试。

3.把相应的代码提交到一个git仓库。

4.通过`pod lib lint`来验证Podspec的正确性，这里要注意下 pod lib lint不会连接网络只会检查文件格式，而如果使用`会读取线上的`repo`并检查相应的`tag。 检查的时候可以增加`--allow-warnings`取消警告以及通过`--verbose`查看详细的情况。

到这里其实你的一个可以通过Cocoapods共享的仓库已经完成了，但是还有点你现在只是一个你自己的仓库还需要推送到一个总仓库去，让大家能搜到使用。当然你可以推送的共享的pod的公共仓库，也可以自己创建仓库

命令如下：

`pod repo push SPEC_REPO *.podspec --verbose` SPEC_REPO 就是仓库名。

#### 5.如何创建以及使用自己的私有仓库

1.需要有一个git仓库，然后通过`pod repo add 仓库名 仓库地址`通过这个命令来创建私有仓库地址。

2.`open ~/.cocoapods/repos/`这个命令可以打开仓库地址

3.如果推上去总仓库已经有podspec文件了那么最后只需要把私有仓库地址与总仓库地址共同设置在Podfile顶部即可，例如：

source 'https://github.com/CocoaPods/Specs.git' #官方仓库地址
source ‘xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx’ #私有仓库地址

这样就可以像用一般的库一样使用私有库了。