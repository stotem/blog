---
title: Java对中国夏令时的展示
tags:
  - 原创
  - cdt
date: 2018-08-24 19:14:57
---

## 中国夏令时制度实行时间
中华人民共和国在1986年~1991年实行了夏令时制度，每年夏令时实行时间如下：
```text
1986年5月4日至9月14日（1986年因是实行夏令时的第一年，从5月4日开始到9月14日结束）
1987年4月12日至9月13日，
1988年4月10日至9月11日，
1989年4月16日至9月17日，
1990年4月15日至9月16日，
1991年4月14日至9月15日。
```
## JDK已有对夏令时的处理
Java的jdk在Date的toString中已经包含夏令时的计算，以下代码可以印证：
```java
public static void main(String[] args) throws Exception {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    String sTime = "1986-09-13 22:00:00";
    sdf.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
    TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"));
    Date time = sdf.parse(sTime);
    System.out.println(time.getTime());
    System.out.println(time);
    Calendar cd = Calendar.getInstance();
    cd.setTime(time);
    // 2小时以后是几点？
    cd.add(Calendar.HOUR, 2);
    time = cd.getTime();
    System.out.println("------------------------------");
    System.out.println(time.getTime());
    System.out.println(time);
}
```
打印结果:
```text
527000400000
Sat Sep 13 22:00:00 CDT 1986
------------------------------
527007600000
Sat Sep 13 23:00:00 CST 1986
```
`分析`: 上面代码中1986-09-1322:00:00加上2小时，应该变为1986-09-13 24:00:00（或者1986-09-14 00:00:00），但由于在9月14日零点退出夏令时，时钟向后调整1小时，实际变为1986-09-13 23:00:00。
注意：从9月14日零点退出夏令时，java的Date.toString打印的时区也从CDT恢复为CST( ChinaStandard Time UT+8:00)。

又如：
```bash
wujianjun@work ~ $ date
2018年 08月 24日 星期五 19:20:41 CST
wujianjun@work ~ $ date -d @579279600
1988年 05月 11日 星期三 00:00:00 CDT
wujianjun@smzc ~ $ date -d @599587200
1989年 01月 01日 星期日 00:00:00 CST

```
`结论`: 只要是在实行夏令时的时段都是`CDT`时间，其它都是`CST`

-----

*观点仅代表自己，期待你的留言。*
