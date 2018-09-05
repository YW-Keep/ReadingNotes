# git 指南

##git操作

### 本地操作

``git add <file>`` 
暂存工作区的修改到暂存区

``git commit`` 
将暂存区的修改提交到本地仓库 
参数：-m 备注提交描述 
e.g.  *git commit -m "this is a commit"*

``git status`` 
查看本地当前分支文件状态

``git diff`` 
查看本地当前分支修改(注意是未暂存的修改)。 *git diff README* 查看指定文件的修改

``git log`` 
查看当前分支的历史提交情况 
参数： 
--pretty=oneline 单行形式显示 
--graph 显示分支树

``git reset HEAD <file>``
回退暂存区的修改到工作区

``git reset <commit id>``
重置当前分支到commit id指定的提交，保留源码


``git reset --hard <commit id>``
重置当前分支到指定提交，不保留源码
e.g.  *git reset --hard 123456 * 强制重置到commit id为123456的提交

> HEAD默认指向当前分支末尾节点，HEAD^表示当前分支的倒数第二个提交，HEAD^^表示倒数第3个提交，HEAD~n表示倒数第n+1个提交。因此将版本重置到上一个提交可以使用命令 *git reset --hard HEAD^*

``git reflog`` 

列出版本修改历史，通常重置版本后要回到未来提交版本时，用该命令获取到对应提交的版本号

``git checkout -- <file>`` 
撤销工作区指定文件的修改，该文件必须是暂存过的文件，即不能是未跟踪的文件

``git revert <commit id>``
创建一个撤销某个提交的新提交

> 通常用于已经push到远程的提交的版本回退，因为使用revert会产生一个新的提交，这样版本回退后直接push即可回退远程提交。若使用reset，本地回退之后版本落后于远程版本，push将不被允许(可以用force强推)。然而即便强推后回退了远程版本，在公共分支上回退版本是很危险的，如果别的开发者在此之前就拉取了分支并做了新的提交，而你又把版本回退了，就会造成别人的分支和远程的分支出现分叉，同步两个分支的唯一办法就是把这他们merge到一起。这在和公共分支上做rebase操作道理是一样的。

``git blame <filename>``
查看指定文件中每一行的修改信息(修改人 修改信息等)

``git cherry-pick <commit id>``
获取指定id的commit提交到当前分支

### 远程操作

``git clone <远程仓库路径>`` 
克隆远程仓库到本地 

``git checkout -b <本地分支名> origin/<远程分支名>`` 
检出远程分支到本地

``git remote add origin <远程仓库路径>`` 
将远程仓库与本地仓库关联，origin为远程主机名

``git remote -v``
查看远程主机地址

``git remote rm <远程主机名>``
取消与远程主机的关联

``git remote rename <原主机名> <新主机名字>
修改远程主机名

``git push origin <远程分支名>`` 
推送当前本地分支到远程分支 
note：若远程不存在相应的分支时会自动创建 
>git push -u origin <远程分支名> 该命令执行后本地分支会跟踪远程分支，下次提交直接 *git push* 即可

``git push origin --delete <远程分支名>`` 
删除远程分支

``git pull origin <远程分支名>`` 
拉取远程分支到当前本地分支

### 分支操作

``git branch`` 
说明：列出本地分支
> git  branch -r 列出远程分支

``git branch <分支名>`` 
创建新的分支

``git checkout <分支名>`` 
切换到指定分支
>git checkout -b <分支名> 当分支不存在时创建，然后checkout

``git merge <分支名>`` 
合并指定分支到当前分支

``git branch -d <分支名>`` 
删除指定分支 
note：如果要删除一个未合并修改的分支，git会给出提示，此时可用`git branch -D <分支名>`强制删除分支即可

``git stash`` 
临时存储未提交的修改（工作现场），包括工作区的修改以及暂存区的修改。通常用于临时切换到别的分支前保存当前分支的修改。

``git stash list`` 
查看当前分支保存的工作现场

``git stash pop`` 
恢复当前分支的工作现场。 
note：原先保存的暂存区的修改会被恢复到工作区。

> 工作现场可以多次stash，可以用*git stash apply <stash索引>* 恢复指定stash，只不过恢复后该stash依旧保存在stash列表中，需要用*git stash drop <stash索引>*将其从列表中移除

### 标签

``git tag <tagname>``
创建本地标签

``git tag <tagname> <commit id>``
指定在某个提交上打标签

``git tag``
列出所有标签

``git push origin <tagname>``
推送本地标签到远程

``git push origin --tags``
推送所有本地未推送的标签到远程

``git tag -d <tagname>``
删除本地标签

``git push origin :refs/tags/<tagname>``
删除远程标签

### 变基(git rebase)

[Git-rebase 小筆記](https://blog.yorkxin.org/2011/07/29/git-rebase)

``git rebase <upstream>``
将当前分支变基到upstream节点，若upstream为分支则变基到该分支的HEAD节点。

> 执行过程：获取当前分支HEAD节点与upstream节点的差集，暂存差集中的commit，然后把当前分支reset到upstream节点上，然后依次取出暂存的commit节点，顺序提交。因此rebase之后commit内容不变，但commit的hash值会变。

``git rebase <upstream> <branch>``
先checkout到branch分支，然后执行``git rebase <upstream>``

``git rebase --onto <newbase> <upstream> <branch>``
先checkout到branch分支，然后获取branch分支与upstream节点的差集，将差集中的节点重新commit到newbase节点。

``git rebase --continue``
rebase的过程中出现冲突，解决后执行完成变基

``git rebase --abort``
rebase的过程中出现冲突，放弃变基

> git rebase的黄金法则：切勿对公共分支rebase，这会造成本地分支和远程分支交叉！

### rebase交互模式 

> rebase的交互式可以用来自定义修改已提交的commit，例如切换两个commit的顺序、合并commit、需要commit message等。主要原理：rebase在执行过程中要暂存当前HEAD结点与upstream结点的差集，然后reset当前分支到指定节点，再依次重新提交暂存的commit。暂存时，git会维护一份commit列表的档案，通过修改该档案，可以自定义重新提交的过程，从而实现对commit的“重新布局”。

核心命令行为：
``git rebase -i <upstream>``

执行之后会用vim打开一个档案，主要内容示例如下：

```bash
pick 51cc620 dev-1
pick 1236928 dev-2
pick b2a910e dev-3
```

其中，pick是一种操作指令。相关指令集如下：

```bash
# p, pick = use commit (保留提交，什么都不改)
# r, reword = use commit, but edit the commit message (保留提交，重写commit message)
# e, edit = use commit, but stop for amending (用于重写commit内容或拆分提交)
# s, squash = use commit, but meld into previous commit (与上一个提交合并，并能重写commit message)
# f, fixup = like "squash", but discard this commit's log message (与上一个提交合并，并保留上一个提交的commit message)
# x, exec = run command (the rest of the line) using shell 
# d, drop = remove commit (移除提交)
```

- 关于edit指令来**重写**commit内容实现偷天换日：
  edit指令执行后，git会将状态停留在对应节点执行完commit之后。这时候可以修改相关的文件内容，修改完成add到暂存区后，通过git rebase —continue来将暂存区的修改与对应节点修改的内容合并后一起重新提交。
- 关于edit指令**拆分**commit：
  edit指令执行后，git会将状态停留在对应节点执行完commit之后。这时通过git reset HEAD^把节点聚焦到前一个节点，这时commit的内容就倒出到工作区了，然后根据拆分的需求一次一次提交，全部提交完后执行git rebase —continue即可，原先的commit会被移除。



##git工作流

[常见工作流比较](https://github.com/geeeeeeeeek/git-recipes/wiki/3.5-%E5%B8%B8%E8%A7%81%E5%B7%A5%E4%BD%9C%E6%B5%81%E6%AF%94%E8%BE%83#mary%E6%88%90%E5%8A%9F%E5%8F%91%E5%B8%83%E4%BA%86%E5%A5%B9%E7%9A%84%E5%88%86%E6%94%AF)

###中心化的工作流

1. 远程只保留一个master分支
2. 通过标签来标识版本发布
3. 开发者克隆远程仓库到本地，开发时在本地checkout出的dev分支上编辑、添加、提交后，在push前，rebase到master。这里有几个注意点：
   + 不要push本地分支到远程
   + 将dev分支的commit并入到master分支之前，需要先切到master分支，拉取远程更新。若直接并入后拉取，若远程有更新，master分支和dev又会分离，后续又要合并。
   + 并入dev分支的commit到master时，不要使用merge方式，务必使用rebase，这能保持master分支的线性提交。而merge则不是线性的，并且有冲突时还会生成一个多余的合并冲突的提交。
   + 若dev分支在并入master分支前忘记拉取远程更新了，这时候本地master和远程master会出现分叉。这时不要git pull拉取代码，因为会产生一个额外的“合并提交”。同样应该用rebase方式拉取更新：``git pull --rebase origin master``   这种pull方式的执行过程和rebase过程很相似，会先暂存本地更改，然后拉取远程更新，再将暂存本地更改按照rebase的方式重新按顺序重新提交。这种方式的好处是：1.不存在额外的“合并提交”；2.当存在冲突时，由于rebase本质是重新所有本地commit，因此能够细致定位到冲突发生在哪个commit。
   + 始终对dev分支rebase，切勿将master分支rebase到dev分支，这会造成master分支本地和远程分叉！
   + 最后，勿忘将dev分支合并到master分支。完事具备后 ``git push origin master``
4. master分支使用保持线性提交，这对于历史提交的追溯和分析是大有裨益的（擅用rebase，摒弃merge，只为更清晰）
5. 此工作流适用于业务线单一的工程，适合小团队。


简单而言，中心化的工作流方式分为为这几步：开发者从master分支checkout开发分支，编辑、添加、提交后，checkout到master分支，拉取远程更新，然后rebase开发分支到master分支，再合并dev中的提交到master分支，最后push master到远程。

### feature分支的工作流

feature分支的工作流面向功能模块，项目开发中面向需求。区别于中心化的工作流，这种模式的工作流远程会存在多个分支，其中一个master分支，属于稳定版本的分支。其余分支，均为feature分支，对应一个功能模块，或者一个需求。feature分支中的提交经过pull request或者code review之后最终都将被合到master分支成为稳定版本的一部分。

相比中心化的工作流方式，feature分支的工作流主要有以下两点好处：

1. 便于开发者之间的协作交流。开发者可以通过pull request来让其他开发者协作开发，也可以方便leader review代码。
2. 开发者在功能分支上开发时，操作流程和中心化的工作流一致，只不过公共分支变成了feature分支而非master分支。这能使得开发者更专注于开发，只在最终功能开发完毕后才将feature分支并入master分支，确保master分支的稳定性。

值得注意的几点：

1. feature分支应当是面向功能模块或者面向需求的，每个分支都应该有一个能描述其职能的名称。
2. feature分支开发完毕合到master分支后，应当从远程移除。
3. feature是需要多人协作开发的分支，必然是公共分支，开发过程中往往会在feature份上中checkout出本地分支，这些分支纯属个人分支，不要push到远程，扰乱远程分支结构。
4. 用rebase，不要用merge。（只为更清晰）


### git flow 工作流 

待补充

### 集成管理工作流

待补充



### 项目组git工作流

采用feature分支的工作流模式。

考量：

1. 项目面向需求周期性迭代，适合用feature分支来管理每一期的需求开发。
2. 通过master分支来管理版本，通过feature分支来管理开发，比起中心化的工作流更能方便开发者之间的协作开发，避免在master分支上频繁提交，开发更专注，管理更安全。
3. 简单考量过git glow工作流，流程非常严谨，分支结构稍显复杂，对于小工程小团队而言个人认为有点杀鸡用牛刀了。至于fork工作流（集成管理工作流），对于当前工程体量而言根本不在考量范围内。

具体工作流：

1. 远程保持两条分支（在单一需求的情况下），master分支+feature分支。
2. 每次需求迭代，从master最新提交checkout出feature分支。所有开发在feature分支进行，开发者本地可以checkout feature分支的本地个人开发分支，但不允许将个人分支push到远程，务必保持远程分支结构的清晰。
3. 工作流程：在本地个人开发分支中开发，执行编辑、添加、提交的流程。开发完毕后准备提交时，checkout到feature分支，pull远程更新（若有更新），然后checkout回个人分支并rebase到feature分支（不要用merge）。最后checkout到feature分支，执行push。
4. 要发布版本时，确保所有开发者的代码都已提交到feature分支并经过系列测试后，合并feature分支到master分支，并打标签标记版本。
5. 版本发布后，移除feature分支。
6. 线上bug紧急修复：从master分支checkout出bug分支，进行bug修复，修复后并入（同样通过rebase）master。

> note：
>
> 此工作流用rebase来并入提交，而不使用merge，目的在于保持线性的提交历史，使提交历史清晰，可追溯、可分析。但是千万注意的是，千万不要对公共分支，即master分支和feature分支做rebase，否则必然产生交叉的提交，别怪我没提醒你！