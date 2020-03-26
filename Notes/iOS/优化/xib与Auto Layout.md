### xib与Auto Layout

#### 1.什么是xib

首先xib的前生就是nib,我们可以基本理解为xib == nib。

通俗的说就是故事板(storyboard)，可以用图形化的方式，使用鼠标拖拉来创建界面。

####2.什么是Auto Layout

Auto Layout是一种“自动布局”技术，是苹果公司提供的一个基于约束布局，动态计算视图大小和位置的库。最早在iOS6引入。

在iOS9，苹果公司推出了在 Auto Layout 基础上模仿前端 Flexbox 布局思路的 UIStackView 工具，提高了开发体验和效率。

Auto Layout 不只有布局算法 Cassowary，还包含了布局在运行时的生命周期等一整套布局引擎系统，用来统一管理布局的创建、更新和销毁。

引擎简单的说就是监听约束变化，然后重新计算布局然后做容错处理然后输出。

iOS 12 将大幅提高 Auto Layout 性能，使滑动达到满帧。

我们使用比较多的Masonry和SnapKit其实就是就是基于Auto Layout的方便使用。

综上，其实就是应该使用Auto Layout，基本没有性能问题。

