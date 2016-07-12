---
title: 类Google分页算法
keywords:
  - 类似Google分页算法
tags:
  - 原创
date: 2016-07-12 16:08:37
---

```
public class Pagination {

    @Test
    public void getPagination() {
        final int[] paginationRegion = getPaginationRegion(6, 5, 10);
        // 进行页码输出
        System.out.println(Arrays.toString(paginationRegion));
        for (int i=paginationRegion[0]; i<= paginationRegion[1];i++) {
            //....
        }
    }

    /**
     * 类Google分页 - 获取需要显示的闭区间页码范围
     * @param currPage 当前页码
     * @param showNum 显示条数，为保持当前页码居中，建议为单数值
     * @param totalPage 总页数
     * @return 闭区间 页码范围
     */
    private static int[] getPaginationRegion(int currPage, int showNum, int totalPage) {
        // 先进行基础运算
        int startNum = currPage - showNum/2;
        int endNum = currPage + showNum/2;
        if (endNum > totalPage) {
            endNum = totalPage;
        }
        if (startNum < 1) {
            startNum = 1;
        }
        // 如果显示页码数量不够则进行补数
        if(endNum - startNum < showNum) {
            int tmp;
            if ((tmp = endNum - showNum + 1) > 0) {
                startNum = tmp;
            }
            else if((tmp = startNum + showNum - 1) < totalPage) {
                endNum = tmp;
            }
        }
        return new int[]{startNum, endNum};
    }
}
```

`注意：`输入的为闭区间(包含两端页码值)范围。

-----

*观点仅代表自己，期待你的留言。*