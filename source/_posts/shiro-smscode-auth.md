---
title: Shiro完成短信验证码登录的实例
tags:
  - 原创
  - shiro
keywords:
  - 短信验证码登录
  - shiro
  - RestfulApi
  - 身份校验
date: 2018-08-30 17:44:47
---

## 分析
Shiro通过`org.apache.shiro.realm.Realm`进行身份与权限的校验，通过`org.apache.shiro.realm.jdbc.JdbcRealm`来查看，
我决定继承自`org.apache.shiro.realm.AuthorizingRealm`来实现身份校验逻辑和权限标识符获取的逻辑。

`org.apache.shiro.realm.AuthorizingRealm`
两个抽象方法：
1、 `protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principalCollection)`:
  主要用于通过当前身份来获取Permissions。

2、 `protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken authenticationToken) throws AuthenticationException`
  主要是用户在登录时调用此方法完成用户身份初步校验，注意：校验凭证(密码、验证码等)由Shiro进行校验不需要手动在此进行校验。

## 源码
`spring-shiro.xml`

```xml
<bean id="securityManager" class="org.apache.shiro.web.mgt.DefaultWebSecurityManager">
    <property name="realm">
       <bean class="com.smzc.apps.order.web.auth.OrderAuthorizingRealm" />
    </property>
    <property name="cacheManager">
       <bean class="org.apache.shiro.cache.ehcache.EhCacheManager" />
    </property>
    <property name="sessionManager">
       <bean class="org.apache.shiro.web.session.mgt.DefaultWebSessionManager">
           <property name="sessionIdCookie">
               <bean class="org.apache.shiro.web.servlet.SimpleCookie">
                   <constructor-arg value="SESSIONID"/>
                   <property name="httpOnly" value="true"/>
                   <property name="maxAge" value="-1"/>
               </bean>
           </property>
       </bean>
    </property>
</bean>

<bean class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
    <property name="staticMethod" value="org.apache.shiro.SecurityUtils.setSecurityManager" />
    <property name="arguments">
        <list>
            <ref bean="securityManager"/>
        </list>
    </property>
</bean>

<!-- shiroFilter -->
<bean id="shiroFilterFactoryBean" class="org.apache.shiro.spring.web.ShiroFilterFactoryBean">
    <!-- Shiro的核心安全接口,这个属性是必须的 -->
    <property name="securityManager" ref="securityManager" />
    <!-- 要求登录时的链接,非必须的属性,默认会自动寻找Web工程根目录下的"/login.jsp"页面 -->
    <property name="loginUrl" value="/views/login" />
    <!-- 登录成功后要跳转的连接 -->
    <property name="successUrl" value="/views/index" />
    <!-- 用户访问未对其授权的资源时,所显示的连接 -->
    <property name="unauthorizedUrl" value="/views/common/unauthorized" />
    <property name="filters">
        <map>
            <entry key="logout">
                <bean class="org.apache.shiro.web.filter.authc.LogoutFilter">
                    <property name="redirectUrl" value="/views/login"/>
                </bean>
            </entry>
        </map>
    </property>
    <!-- 配置Shiro过滤链 -->
    <property name="filterChainDefinitions">
        <value>
            /api/user/login/** = anon
            /api/** = authc
            /logout = logout
            /** = anon
        </value>
    </property>
</bean>
```

`OrderAuthorizingRealm.java`
```java
public class OrderAuthorizingRealm extends AuthorizingRealm implements InitializingBean {
    @Resource
    private AuthorizingService authorizingService;
    @Value("${app.role.permissions:}")
    private String rolePermissionsString;
    private Map<String, Set<String>> rolePermissions;

    @Override
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principalCollection) {
        final SysUser sysUser = (SysUser)super.getAvailablePrincipal(principalCollection);
        final String role = sysUser.getUserRole().getRole();
        final SimpleAuthorizationInfo authorizationInfo = new SimpleAuthorizationInfo(Sets.newHashSet(role));
        authorizationInfo.setStringPermissions(rolePermissions.get(role));
        return authorizationInfo;
    }

    @Override
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken authenticationToken) throws AuthenticationException {
        final UsernamePasswordToken usernamePasswordToken = (UsernamePasswordToken) authenticationToken;
        final String mobile = usernamePasswordToken.getUsername();
        final String validateCode = authorizingService.getCodeByMobile(mobile);
        if (StringUtils.isBlank(validateCode)) {
            throw new ExpiredCredentialsException("验证码已失效#[" + mobile + "]");
        }
        final List<SysUser> sysUserList = authorizingService.getUserByMobile(mobile);
        if (CollectionUtils.isEmpty(sysUserList)) {
            throw new UnknownAccountException("用户账户不存在#[" + mobile + "]");
        }
        if (sysUserList.size() > 1) {
            throw new ConcurrentAccessException("用户存在多个账户#[" + mobile + "]");
        }
        final SysUser sysUser = sysUserList.iterator().next();
        if (!sysUser.getStatus().isAllowLogin()) {
            throw new DisabledAccountException("用户账户不可用#[" + mobile + "]");
        }
        // 注意：SimpleAuthenticationInfo中principal表示验证主体，供后续获取权限标识符和当前登录用户信息使用， credentials表示正确的凭证串，shiro会自动与用户登录时填入的值进行密钥匹配后进行对比。
        // credentials也可以通过setCredentialsSalt设置加密的salt
        return new SimpleAuthenticationInfo(sysUser, validateCode.toCharArray(), super.getName());
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        if (StringUtils.isBlank(rolePermissionsString)) {
            throw new NullPointerException("未初始化权限配置");
        }
        rolePermissions = Maps.newHashMap();
        final JSONObject jsonObject = JSON.parseObject(rolePermissionsString);
        final Iterator<Map.Entry<String, Object>> entryIterator = jsonObject.entrySet().iterator();
        while (entryIterator.hasNext()) {
            final Map.Entry<String, Object> objectEntry = entryIterator.next();
            rolePermissions.put(objectEntry.getKey(), Sets.newHashSet(objectEntry.getValue().toString().split(",")));
        }
    }
}
```

`UserApiController.java`
```java
@RestController
@RequestMapping(value = "/api/user", produces = MediaType.APPLICATION_JSON_UTF8_VALUE)
public class UserApiController extends BasicApiController {

    @Resource
    private SysUserService userService;

    /**
    * 用户登录
    */
    @RequestMapping(value = "/login/{mobileNo}/{code}", method = RequestMethod.GET)
    public Output login(@PathVariable String mobileNo, @PathVariable String code) throws ServiceException {
        Subject subject = SecurityUtils.getSubject();
        UsernamePasswordToken token = new UsernamePasswordToken(mobileNo, code);
        subject.login(token);
        token.clear();
        return MapOutput.createSuccess();
    }

    /**
    * 用户登出
    */
    @RequestMapping(value = "/logout/{mobileNo}", method = RequestMethod.GET)
    public Output logout(@PathVariable String mobileNo) throws ServiceException {
        SecurityUtils.getSubject().logout();
        return MapOutput.createSuccess();
    }
}
```
## Shiro凭证匹配器配置
加密方式都为`org.apache.shiro.authc.credential.CredentialsMatcher`的实现类
通过`org.apache.shiro.realm.AuthenticatingRealm`的`private CredentialsMatcher credentialsMatcher`设置凭据的匹配实现类
如：
```xml
<bean id="securityManager" class="org.apache.shiro.web.mgt.DefaultWebSecurityManager">
    <property name="realm">
<!--BEGIN: 设置凭证器------------------>
       <bean class="com.smzc.apps.order.web.auth.OrderAuthorizingRealm">
         <property name="credentialsMatcher">
           <bean class="org.apache.shiro.authc.credential.PasswordMatcher" />
         </property>
       </bean>
<!--END: 设置凭证器------------------>
    </property>
    <property name="cacheManager">
       <bean class="org.apache.shiro.cache.ehcache.EhCacheManager" />
    </property>
    <property name="sessionManager">
       <bean class="org.apache.shiro.web.session.mgt.DefaultWebSessionManager">
           <property name="sessionIdCookie">
               <bean class="org.apache.shiro.web.servlet.SimpleCookie">
                   <constructor-arg value="SESSIONID"/>
                   <property name="httpOnly" value="true"/>
                   <property name="maxAge" value="-1"/>
               </bean>
           </property>
       </bean>
    </property>
</bean>
```

## Shiro内置的FilterChain
1. Shiro验证URL时,URL匹配成功便不再继续匹配查找(所以要注意配置文件中的URL顺序,尤其在使用通配符时)
 故filterChainDefinitions的配置顺序为自上而下,以最上面的为准
2. 当运行一个Web应用程序时,Shiro将会创建一些有用的默认Filter实例,并自动地在[main]项中将它们置为可用
 自动地可用的默认的Filter实例是被DefaultFilter枚举类定义的,枚举的名称字段就是可供配置的名称
 anon---------------org.apache.shiro.web.filter.authc.AnonymousFilter
 authc--------------org.apache.shiro.web.filter.authc.FormAuthenticationFilter
 authcBasic---------org.apache.shiro.web.filter.authc.BasicHttpAuthenticationFilter
 logout-------------org.apache.shiro.web.filter.authc.LogoutFilter
 noSessionCreation--org.apache.shiro.web.filter.session.NoSessionCreationFilter
 perms--------------org.apache.shiro.web.filter.authz.PermissionAuthorizationFilter
 port---------------org.apache.shiro.web.filter.authz.PortFilter
 rest---------------org.apache.shiro.web.filter.authz.HttpMethodPermissionFilter
 roles--------------org.apache.shiro.web.filter.authz.RolesAuthorizationFilter
 ssl----------------org.apache.shiro.web.filter.authz.SslFilter
 user---------------org.apache.shiro.web.filter.authz.UserFilter

3. 通常可将这些过滤器分为两组
 anon,authc,authcBasic,user是第一组认证过滤器
 perms,port,rest,roles,ssl是第二组授权过滤器
 注意user和authc不同：当应用开启了rememberMe时,用户下次访问时可以是一个user,但绝不会是authc,因为authc是需要重新认证的
 user表示用户不一定已通过认证,只要曾被Shiro记住过登录状态的用户就可以正常发起请求,比如rememberMe
 说白了,以前的一个用户登录时开启了rememberMe,然后他关闭浏览器,下次再访问时他就是一个user,而不会authc

4. 举几个例子
 /admin=authc,roles[admin]      表示用户必需已通过认证,并拥有admin角色才可以正常发起'/admin'请求
 /edit=authc,perms[admin:edit]  表示用户必需已通过认证,并拥有admin:edit权限才可以正常发起'/edit'请求
 /home=user                     表示用户不一定需要已经通过认证,只需要曾经被Shiro记住过登录状态就可以正常发起'/home'请求

5. 各默认过滤器常用如下(注意URL Pattern里用到的是两颗星,这样才能实现任意层次的全匹配)
 /admins/**=anon             无参,表示可匿名使用,可以理解为匿名用户或游客
 /admins/user/**=authc       无参,表示需认证才能使用
 /admins/user/**=authcBasic  无参,表示httpBasic认证
 /admins/user/**=user        无参,表示必须存在用户,当登入操作时不做检查
 /admins/user/**=ssl         无参,表示安全的URL请求,协议为https
 /admins/user/**=perms[user:add:*]
 参数可写多个,多参时必须加上引号,且参数之间用逗号分割,如/admins/user/**=perms["user:add:*,user:modify:*"]
 当有多个参数时必须每个参数都通过才算通过,相当于isPermitedAll()方法
 /admins/user/**=port[8081]
 当请求的URL端口不是8081时,跳转到schemal://serverName:8081?queryString
 其中schmal是协议http或https等,serverName是你访问的Host,8081是Port端口,queryString是你访问的URL里的?后面的参数
 /admins/user/**=rest[user]
 根据请求的方法,相当于/admins/user/**=perms[user:method],其中method为post,get,delete等
 /admins/user/**=roles[admin]
 参数可写多个,多个时必须加上引号,且参数之间用逗号分割,如/admins/user/**=roles["admin,guest"]
 当有多个参数时必须每个参数都通过才算通过,相当于hasAllRoles()方法

-----

*观点仅代表自己，期待你的留言。*
