---
title: Spring多视图配置及源码剖析
keywords:
  - "ContentNegotiatingViewResolver"
  - "Spring多视图配置"
  - "Spring源码剖析"
tags:
  - 原创
date: 2016-06-29 15:56:16
---

## 简介
在MVC架构中，Controller被用于连接Model与View，同时控制View的显示与跳转。在以往的开发实践中常常是直接将View与Controller放置在同一个Project中，如果此时想要真正实现Controller与View的分离，View与Controller的交互就只能通过HTTP+数据格式或者ajax实现。那么Controller所需要做的就是将数据通过api的方式提供给View。此时针对Controller就需要将数据进行api和view的两种完全不同的视图呈现。好在Spring已经给我们提供了`org.springframework.web.servlet.view.ContentNegotiatingViewResolver`来实现。

## Spring多视图配置
_spring-web.xml_
```
<!--配置消息转换器-->
<mvc:annotation-driven>
    <mvc:message-converters register-defaults="true">
        <bean class="org.springframework.http.converter.StringHttpMessageConverter">
            <constructor-arg value="UTF-8"/>
            <property name="supportedMediaTypes">
               <list>
                   <value>application/xml;charset=UTF-8</value>
                   <value>text/html;charset=UTF-8</value>
                   <value>text/plain;charset=UTF-8</value>
                   <value>application/json;charset=UTF-8</value>
               </list>
           </property>
        </bean>
        <bean class="org.springframework.http.converter.json.MappingJackson2HttpMessageConverter">
            <property name="prettyPrint" value="true"/>
        </bean>
    </mvc:message-converters>
</mvc:annotation-driven>
<!--多视图解析配置-->
<bean class="org.springframework.web.servlet.view.ContentNegotiatingViewResolver">
	<property name="defaultContentType" value="text/html;charset=UTF-8" />
	<!-- not by accept header -->
	<property name="ignoreAcceptHeader" value="true"/>
	<property name="favorPathExtension" value="true"/>
	<property name="favorParameter" value="true"/>
    <property name="useNotAcceptableStatusCode" value="true" />
	<!-- by extension -->
	<property name="mediaTypes">
		<map>
		    <entry key="xml" value="application/xml" />
			<entry key="json" value="application/json" />
            <entry key="httl" value="text/html" />
		</map>
	</property>
	<property name="viewResolvers">
		<list>
            <ref bean="httlViewResolver"/>
		</list>
	</property>
		<property name="defaultViews">
		<list>
            <bean class="org.springframework.web.servlet.view.json.MappingJackson2JsonView" />
           	<bean class="org.springframework.web.servlet.view.xml.MappingJackson2XmlView" />
		</list>
	</property>
</bean>

<!-- 视图解析器配置 -->
<bean id="httlViewResolver" class="httl.web.springmvc.HttlViewResolver">
    <property name="suffix" value=".view"/>
    <property name="contentType" value="text/html;charset=UTF-8"/>
    <property name="attributesMap" ref="viewTools" />
</bean>
```
_Controller.java_
```
@Controller
@RequestMapping("/")
public class CommonController {
	@RequestMapping("index")
    public ModelAndView indexPage() {
        Map<String, Object> param = new HashMap<>();
        param.put("_model_", new Example());
        return getView("index", param);
    }
}
```
以上为多视图配置的全部内容，配置中我们提供了三种视图。
1. httl的页面视图。 通过访问/index或/index.httl就可以得到。
![](/images/spring-mutiview-0.png)
2. json的数据视图。 通过访问/index.json就可以得到。
![](/images/spring-mutiview-1.png)
3. xml的数据视图。 通过访问/index.xml就可以各到。
![](/images/spring-mutiview-2.png)
这里需要注意的是，由于xml只有一个根节点，所以返回的param的Map中只能包含一个元素。如果配置多个map元素，则会抛出异常java.lang.IllegalStateException: Model contains more than one object to render, only one is supported
![](/images/spring-mutiview-4.png)

`useNotAcceptableStatusCode`：这个配置表示，当配置为true且不能找到你需要的配置时返回HttpStatus 406. 默认值为false
![](/images/spring-mutiview-3.png)

## Spring源码剖析
首先当然是org.springframework.web.servlet.view.ContentNegotiatingViewResolver类，经过断点跟踪后，发现是通过resolveViewName()来定位的显示View。
![](/images/spring-mutiview-5.png)
从图上可以看出，先通过request获取到requestedMediaTypes。
### 获取请求的视图格式
![](/images/spring-mutiview-6.png)
再深入一层查看，发现这里是针对requestedMediaTypes的过滤，而获取请求格式有三个途径，
ServletPathExtensionContentNegotiationStrategy（继承自PathExtensionContentNegotiationStrategy），
ParameterContentNegotiationStrategy
FixedContentNegotiationStrategy
而这恰好对应了Spring中针对识别多视图标识的配置
```
<property name="ignoreAcceptHeader" value="true"/>
<property name="favorPathExtension" value="true"/>
<property name="favorParameter" value="true"/>
```
所以可以得出结论：
1、HeaderContentNegotiationStrategy对应ignoreAcceptHeader的配置，此处配置为false,那么ContentNegotiatingViewResolver.contentNegotiationManager属性里则会多出一个元素。通过其源码可以得到它是通过在request header中增加Accept消息头获取视图格式。
2、ServletPathExtensionContentNegotiationStrategy（或者PathExtensionContentNegotiationStrategy）对应favorPathExtension的配置。通过请求后缀获取视图格式。
3、ParameterContentNegotiationStrategy对应favorParameter的配置，通过在request uri中增加format=?获取视图格式。

### 按requestdMediaTypes获取到支持的ViewResolver
```
List candidateViews = this.getCandidateViews(viewName, locale, requestedMediaTypes);
```
![](/images/spring-mutiview-7.png)
这里所做的事，就是将controller处理完成的view名称拿到配置的ViewResolver里去查找（视图名称和加了后缀的视图名称两步搜索），最后再将配置的defaultViews直接加入到返回结果的List中。此处忽略掉了视图格式标识。 

### 获取匹配度最高的View
```
View bestView = this.getBestView(candidateViews, requestedMediaTypes, attrs);
```
此方法所做的事：将包含视图名称的ViewResolver按requestedMediaTypes找到匹配度最高的View。
如果没有找到，则按useNotAcceptableStatusCode返回HttpCode 406.或者通过candidateViews的第一个进行视图渲染。__这里的顺序可以通过配置viewResolvers的order属性确定__。

## Velocity与Httl视图工具类实例处理方案

由于在页面视图中我们需要用到很多的工具类来对Controller返回的数据进行判断以及转换等操作，所以一般来讲我们会在Map存入工具类的实例对象以便能在Page中直接使用。
但是当返回的为xml视图时，由于元素数据限制为1个，所以这些工具类将会导致多视图不能返回xml的数据格式。

在Velocity中可以配置toolbox等工具组件来实现，但是Httl并未支持。所以我找到另一个实现方式。

经过源码的查看，UrlBasedViewResolver类中包含一个staticAttributes的Map类型属性，这里完全可以拿来存放工具类对象实例，staticAttributes属性的get和set方法名称为：setAttributesMap()和getAttributesMap(). 所以配置的时候要注意配置名为__attributesMap__。
而HttlViewResolver与VelocityLayoutViewResolver都间接继承自UrlBasedViewResolver，所以可以通过配置attributesMap属性来实现工具类实例的配置。

-----

*观点仅代表自己，期待你的留言。*