---
title: Shiro完成RestfulApi的会话保持实例
tags:
  - 原创
  - shiro
keywords:
  - 前后端分离
  - shiro
  - RestfulApi
  - 会话保持
date: 2018-10-24 15:00:30
---

## 背景
针对用户身份权限管理包含账户权限登录认证+会话保持两个部分，在 __移动端+服务平台__ 或 __前后端分离__ 的项目框架下，一般会涉及到通过token来进行用户登录会话的保持。
以下我将通过在HTTP Header中增加token的方式在RestfulApi的服务端进行权限校验与会话保持。

## 扩展分析
1. 扩展`org.apache.shiro.session.mgt.eis.EnterpriseCacheSessionDAO`: 完成用户Session的存取。
2. 扩展`org.apache.shiro.web.session.mgt.DefaultWebSessionManager`: 完成用户Session标识的获取。

## 源码
__org.wujianjun.apps.web.auth.TokenSessionManager__
```java
public class TokenSessionManager extends DefaultWebSessionManager {

    public static final String ACCESS_TOKEN = "x-access-token";
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    protected Serializable getSessionId(ServletRequest request, ServletResponse response) {
        final String accessToken = WebUtils.toHttp(request).getHeader(this.ACCESS_TOKEN);
        if (StringUtils.isBlank(accessToken)) {
            return null;
        }
        // 设置当前session状态
        request.setAttribute(ShiroHttpServletRequest.REFERENCED_SESSION_ID_SOURCE, ShiroHttpServletRequest.URL_SESSION_ID_SOURCE);
        request.setAttribute(ShiroHttpServletRequest.REFERENCED_SESSION_ID, accessToken);
        request.setAttribute(ShiroHttpServletRequest.REFERENCED_SESSION_ID_IS_VALID, Boolean.TRUE);
        return accessToken;
    }
}
```

__org.wujianjun.apps.web.auth.RedisSessionDAO__
```java
@Component
public class RedisSessionDAO extends EnterpriseCacheSessionDAO {

    @Resource
    private RedisTemplate<String, String> redisTemplate;

    public RedisSessionDAO(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public RedisTemplate<String, String> getRedisTemplate() {
        return redisTemplate;
    }

    public void setRedisTemplate(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    protected Session doReadSession(Serializable serializable) {
        final Object validAccessToken = redisTemplate.opsForHash().get(RedisConst.REDIS_ACCESS_TOKEN_KEY, serializable);
        if (validAccessToken == null) {
            return null;
        }
        final SimpleSession simpleSession = new SimpleSession();
        simpleSession.setId(serializable);
        final SysUser sysUser = JSON.parseObject(validAccessToken.toString(), SysUser.class);
        simpleSession.setAttribute(DefaultSubjectContext.PRINCIPALS_SESSION_KEY, new SimplePrincipalCollection(sysUser, "authorRealm"));
        simpleSession.setAttribute(DefaultSubjectContext.AUTHENTICATED_SESSION_KEY, Boolean.TRUE);
        return simpleSession;
    }

    @Override
    protected void doUpdate(Session session) {
        PrincipalCollection existingPrincipals = (PrincipalCollection)session.getAttribute(DefaultSubjectContext.PRINCIPALS_SESSION_KEY);
        if (existingPrincipals == null) {
            return;
        }
        final Object primaryPrincipal = existingPrincipals.getPrimaryPrincipal();
        if (primaryPrincipal instanceof SysUser) {
            final SysUser sysUser = (SysUser)primaryPrincipal;
            redisTemplate.opsForHash().put(RedisConst.REDIS_ACCESS_TOKEN_KEY, session.getId(), JSON.toJSONString(sysUser));
        }
    }

    @Override
    protected void doDelete(Session session) {
        redisTemplate.opsForHash().delete(RedisConst.REDIS_ACCESS_TOKEN_KEY, session.getId());
    }
}
```

__spring-shiro.xml__
```xml
<bean id="securityManager" class="org.apache.shiro.web.mgt.DefaultWebSecurityManager" p:realm-ref="authorRealm">
    <property name="cacheManager">
       <bean class="org.apache.shiro.cache.ehcache.EhCacheManager" />
    </property>
    <property name="sessionManager">
       <bean class="org.wujianjun.apps.web.auth.TokenSessionManager" p:sessionDAO-ref="redisSessionDAO"
             p:deleteInvalidSessions="false" p:sessionIdCookieEnabled="false" p:sessionValidationSchedulerEnabled="false"/>
    </property>
</bean>
```

## SessoinId扩展
如果需要自己定义sessionId的生成，只需要给 __org.apache.shiro.session.mgt.eis.AbstractSessionDAO__ 设置`sessionIdGenerator`的属性值即可。
```xml
<bean class="org.wujianjun.apps.web.auth.RedisSessionDAO">
  <property name="sessionIdGenerator">
    <bean class="org.wujianjun.apps.web.auth.JWTSessionIdGenerator" />
  </property>
</bean>
```

-----

*观点仅代表自己，期待你的留言。*
