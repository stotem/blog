---
title: 开源SSO项目cas认证返回更多的attribute信息
keywords:
  - cas sso
  - attribute
  - 更多信息返回
tags:
  - 原创
date: 2016-08-16 18:41:39
---

## CAS项目介绍
介绍网址： https://github.com/apereo/cas
github地址：https://github.com/apereo/cas.git

默认情况下，当用户认证成功后，客户端代码中只能获取到用户的登录名称，不能获取到其它的信息（如：手机号，所属角色，已有授权等），好在提供了一个attribute的map可以进行其它信息的返回。
```
AttributePrincipal ap = AssertionHolder.getAssertion().getPrincipal();
String name = ap.getName();
Map<String,Object> attribute = ap.getAttributes();
```
## 增加attribute信息返回
### 修改ticket验证接口返回的xml信息
找到WEB-INF/view/jsp/protocol/2.0/casServiceValidationSuccess.jsp，在</cas:authenticationSuccess>节点之前添加以下内容。
```
<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationSuccess>
    	//...原有信息..//
		<c:if test="${fn:length(assertion.chainedAuthentications[fn:length(assertion.chainedAuthentications)-1].principal.attributes) > 0}">
            <cas:attributes>
                <c:forEach var="attr" items="${assertion.chainedAuthentications[fn:length(assertion.chainedAuthentications)-1].principal.attributes}">
                    <cas:attribute>
                        <cas:${fn:escapeXml(attr.key)}>${fn:escapeXml(attr.value)}</cas:${fn:escapeXml(attr.key)}>
                    </cas:attribute>
                </c:forEach>
            </cas:attributes>
        </c:if>
    </cas:authenticationSuccess>
</cas:serviceResponse>
```
### 在用户登录验证时增加attribute关联

在deployerConfigContext.xml配置文件中，默认采用AcceptUsersAuthenticationHandler类的users属性（以key为登录名value为密码）进行系统用户的设定。
而通过PersonDirectoryPrincipalResolver的attributeRepository属性进行attribute映射和配置。默认由NamedStubPersonAttributeDao类的backingMap属性进行key-value配置，针对所有的用户都生效。
提示：IPersonAttributeDao有很多的子类实现，可以通过源码查看各自实现的方式，我这里主要介绍json,xml和数据库三种方式实现。

#### json配置的方式
而在实际业务系统设计中针对不同的用户需要返回不同的attribute这个需求似乎不太适用，经过查看可能配置JsonBackedComplexStubPersonAttributeDao来在json中针对单个用户attribute进行配置。`指定init-method为init方法`
配置如下：
```
<bean id="attributeRepository" class="org.jasig.services.persondir.support.JsonBackedComplexStubPersonAttributeDao" init-method="init">
    <constructor-arg index="0" value="classpath:users.json" />
</bean>
```
_users.json_
```
{
  "user1":{
    "id":["1001"],
    "firstName":["View"],
    "lastName":["Jack"],
    "roles":["view"],
    "permissions":["support:*:view"]
  },
  "user2":{
    "id":["1002"],
    "firstName":["Admin"],
    "lastName":["One"],
    "roles":["admin"],
    "permissions":["support"]
  }
}
```
#### xml配置的方式
配置attributeRepository为XmlPersonAttributeDao来在xml中针对单个用户的attribute进行配置。
配置如下：
```
<bean id="attributeRepository" class="org.jasig.services.persondir.support.xml.XmlPersonAttributeDao">
    <property name="mappedXmlResource" value="classpath:users.xml" />
</bean>
```
#### database读取的方式
配置attributeRepository为NamedParameterJdbcPersonAttributeDao来在数据库按用户名进行attribute的配置加载。
```
<bean id="attributeRepository" class="org.jasig.services.persondir.support.jdbc.SingleRowJdbcPersonAttributeDao">
    <property name="dataSource" ref="datasource" />
    <property name="sql" value="select email,name,username,password from cas_user where {0}" />
    <!-- 组装sql用的查询条件属性 -->	
	<property name="queryAttributeMapping">
		<map>
		    <!-- key必须是uername而且是小写否则会导致取不到用户的其它信息，value对应数据库用户名字段,系统会自己匹配 -->
			<entry key="username" value="username" />
		</map>
	</property>
	<property name="resultAttributeMapping">
		<map>
		    <!-- key为对应的数据库字段名称，value为提供给客户端获取的属性名字，系统会自动填充值 -->
			<entry key="username" value="username" />
			<entry key="email" value="email" />
			<entry key="name" value="name" />
			<entry key="password" value="password" />
		</map>
	</property>
</bean>
```
## 密码加密方式配置
在实际开发中不能任由密码明文进行传输，一般来讲会进行加密。而cas可直接通过配置的方式进行加密方式的确定。
在配置的AcceptUsersAuthenticationHandler中继承了父类中的一个名为passwordEncoder的PasswordEncoder类型属性。通过给这个属性配置加密方式值就能实现。默认为PlainTextPasswordEncoder加密方式。
如配置md5的方式：
```
<bean id="primaryAuthenticationHandler" class="org.jasig.cas.authentication.AcceptUsersAuthenticationHandler">
	<property name="passwordEncoder" ref="passwordEncoder" />
	<property name="users">
        <map>
            <entry key="user1" value="123" />
            <entry key="user2" value="123" />
        </map>
    </property>
</bean>
<bean id="passwordEncoder" class="org.jasig.cas.authentication.handler.DefaultPasswordEncoder">
	<property name="characterEncoding" value="utf-8" />
	<property name="encodingAlgorithm" value="MD5" />
</bean>
```

`提示：`配置了密码方式之后，所有配置文件或数据库中所存储的密码则应修改为密文。

## 重要发现
用户登录验证采用的AuthenticationHandler接口的子类实现，当我们自定义实现类完成验证时，不要妄想在通过HandlerResult的getPrincipal()获取到Principal然后给它设置attribute,因为cas在调用认证方式后会针对Principal的数据进行name的复制，所以即使你的认证方式进行了attribute的设置，在进行对象复制时也会丢掉。

详见：PolicyBasedAuthenticationManager的authenticateInternal方法中的逻辑。
![PolicyBasedAuthenticationManager-authenticateInternal](/images/QQ20160817-0.png)

-----

*观点仅代表自己，期待你的留言。*