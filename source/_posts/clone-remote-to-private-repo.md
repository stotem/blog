---
title: Clone开源项目到私有Git服务器
tags:
  - 原创
date: 2021-10-12 19:10:18
---

## 内容

1. 在clone的工程下增加私有仓库地址：`git remote add PrivateRepo http://xxx/repo/myproj.git`
2. 从私有仓库checkout分支到本地: `git checkout PrivateRepo/master`
3. 从远端仓库分支合并代码到私有仓库分支： `git merge master --allow-unrelated-histories`
4. push代码: `git push`


-----

*观点仅代表自己，期待你的留言。*
