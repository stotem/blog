---
title: Java Script Engine
keywords:
  - ScriptEngine
  - 字符串运行结果
tags:
  - 原创
date: 2018-07-18 16:45:12
---

## Java Script Engine
```java
public static void main(String[] agrs) throws ScriptException {
    final ScriptEngine javascriptEngine = new ScriptEngineManager().getEngineByName("javascript");
    final Bindings globalBindings = javascriptEngine.getBindings(ScriptContext.GLOBAL_SCOPE);
    globalBindings.put("a", 5);
    System.out.println("-------Engine bindings scope--------------");
    final Bindings javascriptEngineBindings = javascriptEngine.getBindings(ScriptContext.ENGINE_SCOPE);
    javascriptEngineBindings.put("x", 20);
    javascriptEngineBindings.put("y", 20.4);
    javascriptEngineBindings.put("z", 1);
    final String[] scriptArray = {"x*y+z", "x*(y+z)", "a+x*(y+z)"};
    eval(scriptArray, javascriptEngine);

    System.out.println("-------Local bindings scope--------------");
    final Bindings localBinding = javascriptEngine.createBindings();
    localBinding.put("x", 2);
    localBinding.put("y", 3);
    localBinding.put("z", 1);
    eval(scriptArray, javascriptEngine, localBinding);
}

private static void eval(String[] scriptArray, ScriptEngine javascriptEngine) throws ScriptException {
    Bindings aBindings = javascriptEngine.getBindings(ScriptContext.GLOBAL_SCOPE);
    for (String key : aBindings.keySet()) {
        System.out.println("Args (Global bindings scope) > " + key + "=" + aBindings.get(key));
    }
    aBindings = javascriptEngine.getBindings(ScriptContext.ENGINE_SCOPE);
    for (String key : aBindings.keySet()) {
        System.out.println("Args (Engine bindings scope) > " + key + "=" + aBindings.get(key));
    }
    for (String script : scriptArray) {
        System.out.println("script > " + script + " = " + javascriptEngine.eval(script));
    }
}

private static void eval(String[] scriptArray, ScriptEngine javascriptEngine, Bindings localBinding) throws ScriptException {
    Bindings aBindings = javascriptEngine.getBindings(ScriptContext.GLOBAL_SCOPE);
    for (String key : aBindings.keySet()) {
        System.out.println("Args (Global bindings scope) > " + key + "=" + aBindings.get(key));
    }
    aBindings = javascriptEngine.getBindings(ScriptContext.ENGINE_SCOPE);
    for (String key : aBindings.keySet()) {
        System.out.println("Args (Engine bindings scope) > " + key + "=" + aBindings.get(key));
    }
    for (String s : localBinding.keySet()) {
        System.out.println("Args (Local bindings scope) > " + s + "=" + aBindings.get(s));
    }
    for (String script : scriptArray) {
        System.out.println("script > " + script + " = " + javascriptEngine.eval(script, localBinding));
    }
}
```
输出结果：
```
-------Engine bindings scope--------------
Args (Global bindings scope) > a=5
Args (Engine bindings scope) > z=1
Args (Engine bindings scope) > y=20.4
Args (Engine bindings scope) > x=20
script > x*y+z = 409.0
script > x*(y+z) = 428.0
script > a+x*(y+z) = 433.0
-------Local bindings scope--------------
Args (Global bindings scope) > a=5
Args (Engine bindings scope) > println=sun.org.mozilla.javascript.internal.InterpretedFunction@45a23f67
Args (Engine bindings scope) > context=javax.script.SimpleScriptContext@1ef0a6e8
Args (Engine bindings scope) > z=1
Args (Engine bindings scope) > print=sun.org.mozilla.javascript.internal.InterpretedFunction@495dd936
Args (Engine bindings scope) > y=20.4
Args (Engine bindings scope) > x=20
Args (Local bindings scope) > z=1
Args (Local bindings scope) > y=20.4
Args (Local bindings scope) > x=20
script > x*y+z = 7.0
script > x*(y+z) = 8.0
script > a+x*(y+z) = 13.0

Process finished with exit code 0
```
__Bindings变量的有效范围__
1. Global对应到ScriptEngineFactory，通过`scriptEngine.getBindings(ScriptContext.GLOBAL_SCOPE)`获得。
2. Engine对应到ScriptEngine，通过`scriptEngine.getBindings(ScriptContext.ENGINE_SCOPE)`获得。
3. Local Binding每一次执行script，通过`scriptEngine.createBindings()`获得。

__使用场景适用于__
1. 规则引擎
2. 流程流转条件判定

-----

*观点仅代表自己，期待你的留言。*
