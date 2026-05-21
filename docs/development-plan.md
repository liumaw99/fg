# 类 Twitter 社交 App 详细开发计划

## 1. 项目目标

构建一个企业级类 Twitter/X 社交 App，技术栈：

```txt
Flutter + Go + Gin + Wire + Ent + Zap + PostgreSQL + Elasticsearch + Redis + Kafka
```

第一版采用模块化单体，不拆微服务。

架构要求：

- 可快速交付 MVP。
- 可支撑正式生产上线。
- 可观测、可测试、可扩展。
- 未来可按模块拆成微服务。

## 2. MVP 功能范围

必须实现：

- 注册和登录。
- Refresh Token 和退出登录。
- 用户资料。
- 头像上传。
- 发布文字帖。
- 发布图片帖。
- 删除帖子。
- 用户主页流。
- 关注和取消关注。
- 首页关注流。
- 点赞和取消点赞。
- 回复。
- 转发。
- 站内通知。
- 基础 Push 通知。
- 用户搜索。
- 帖子搜索。
- 举报帖子和用户。
- 基础后台审核。

暂不做：

- 私信第一版 MVP 暂不做，作为上线后的第 10 阶段。
- 复杂推荐系统。
- 视频转码。
- 广告系统。
- 创作者收益。
- A/B 测试。
- 直播。
- 高级风控系统。

## 3. 里程碑总览

小团队预估周期：

```txt
第 1-2 周：后端基础设施
第 2-3 周：Flutter 基础设施
第 3-4 周：认证和用户资料
第 5-6 周：帖子和媒体
第 7-8 周：社交关系和 Timeline
第 9-10 周：互动和通知
第 11-12 周：搜索、审核、后台基础
第 13-14 周：可观测性、测试、加固、上线准备
上线后第 1 期：私信聊天
```

交付预期：

```txt
8 周：Alpha
12 周：Beta
14-16 周：小规模生产上线
```

## 4. 第 0 阶段：产品和技术基线

周期：3-5 天。

交付物：

- 确认 MVP 功能边界。
- 确认用户角色和权限。
- 确认 API 命名规范。
- 确认错误码规范。
- 确认数据库 ERD。
- 确认 Ent Schema 列表。
- 确认 Kafka Topic 列表。
- 确认 Flutter 页面地图。
- 确认部署环境规划。

需要定下来的问题：

- 邮箱登录、手机号登录，还是两者都支持。
- Alpha 是否必须支持图片上传。
- 视频上传是否后置。
- 后台管理是否第一版必须上线。
- 第三方登录是否后置。

验收标准：

- 架构设计确认。
- MVP 范围确认。
- 数据库表列表确认。
- Kafka Topic 列表确认。

## 5. 第 1 阶段：后端基础设施

周期：1-2 周。

### 后端任务

- 创建 Go 项目结构。
- 初始化 Gin Router。
- 初始化 Wire 依赖注入。
- 增加配置加载。
- 增加 Zap 日志。
- 增加 PostgreSQL 连接。
- 集成 Ent。
- 增加 Redis 连接。
- 增加 Kafka Producer 和 Consumer 基础封装。
- 增加 S3/R2/MinIO 对象存储封装。
- 增加统一响应封装。
- 增加统一错误封装。
- 增加请求参数校验。
- 增加 Cursor Pagination 封装。
- 增加 JWT 封装。
- 增加密码哈希封装。
- 增加 OpenTelemetry 基础集成。

### 中间件任务

- Request ID Middleware。
- Recovery Middleware。
- Logger Middleware。
- CORS Middleware。
- Timeout Middleware。
- Auth Middleware。
- Rate Limit Middleware。
- Security Headers Middleware。
- Metrics Middleware。

### 数据库任务

- 创建基础 Ent Schema。
- 增加 migration 命令。
- 增加本地 seed 命令。
- 增加数据库事务 helper。

### Kafka 任务

- 创建 Topic 常量。
- 创建事件 Envelope 定义。
- 创建 Kafka Producer 封装。
- 创建 Kafka Consumer 封装。
- 创建 Outbox Publisher Worker。
- 创建 processed_events 幂等 helper。
- 创建 retry 和 DLQ 约定。

### DevOps 任务

- Docker Compose 启动 PostgreSQL、Redis、Kafka、MinIO。
- 增加 Makefile 或任务脚本。
- 增加 `.env.example`。
- 增加健康检查接口。
- 增加就绪检查接口。
- 增加 OpenAPI 基础配置。

验收标准：

- API 服务本地可启动。
- Worker 服务本地可启动。
- 健康检查可访问。
- PostgreSQL migration 可执行。
- Redis ping 正常。
- Kafka Producer 和 Consumer 冒烟测试通过。
- 请求日志包含 request_id 和 trace_id。
- 基础集成测试通过。

## 6. 第 2 阶段：Flutter 基础设施

周期：1 周。

### Flutter 任务

- 创建 Flutter 项目结构。
- 引入 Riverpod。
- 引入 GoRouter。
- 封装 Dio ApiClient。
- 封装 API 错误映射。
- 封装安全 Token 存储。
- 增加 Auth Interceptor。
- 增加 Refresh Token Interceptor。
- 使用 Isar 封装本地缓存。
- 增加主题系统。
- 增加全局 loading 和 error 组件。
- 初始化 Sentry。
- 初始化 Firebase。

### 页面任务

- Splash 页面。
- 登录页占位。
- 注册页占位。
- 首页 Shell。
- 个人主页占位。
- 设置页占位。

验收标准：

- App 可在 iOS 和 Android 模拟器启动。
- Router 登录守卫生效。
- Dio 可调用后端健康检查。
- Token 存储封装可用。
- 全局 API 错误展示可用。

## 7. 第 3 阶段：认证和用户系统

周期：1-2 周。

### 后端任务

- 实现注册。
- 实现登录。
- 实现刷新 Token。
- 实现退出登录。
- 实现当前用户接口。
- 实现 Session 管理。
- 实现用户资料查询。
- 实现用户资料更新。
- 实现头像上传预签名接口。
- 发送 `UserRegistered` 事件。
- 发送 `UserProfileUpdated` 事件。

### 数据库表

- users。
- user_profiles。
- user_stats。
- user_sessions。
- media_assets。
- outbox_events。
- processed_events。

### Flutter 任务

- 登录页。
- 注册页。
- 当前用户 Provider。
- 个人主页。
- 编辑资料页。
- 头像上传。
- 退出登录流程。

验收标准：

- 用户可以注册。
- 用户可以登录。
- Access Token 可以自动刷新。
- 用户可以编辑资料。
- 用户可以上传头像。
- 退出登录会撤销当前 Session。

## 8. 第 4 阶段：帖子和媒体

周期：2 周。

### 后端任务

- 创建帖子接口。
- 删除帖子接口。
- 帖子详情接口。
- 用户帖子列表接口。
- 创建媒体预签名上传接口。
- 完成媒体上传接口。
- 帖子绑定媒体。
- 解析话题。
- 解析提及。
- 创建帖子统计。
- 发送 `PostCreated` 事件。
- 发送 `PostDeleted` 事件。
- 发送 `PostMentioned` 事件。
- 消费媒体事件更新媒体状态。

### 数据库表

- posts。
- post_stats。
- media_assets。
- post_media。
- hashtags。
- post_hashtags。
- mentions。
- outbox_events。

### Kafka Topic

- post.events.v1。
- media.events.v1。
- notification.events.v1。

### Flutter 任务

- 发帖页。
- 图片选择。
- 上传进度 UI。
- 帖子卡片组件。
- 帖子详情页。
- 用户主页帖子列表。

验收标准：

- 用户可以发文字帖。
- 用户可以发图片帖。
- 用户可以删除自己的帖子。
- 用户可以打开帖子详情。
- 用户主页展示自己的帖子。
- 提及事件能触发通知流程占位。

## 9. 第 5 阶段：社交关系和 Timeline

周期：2 周。

### 后端任务

- 关注接口。
- 取消关注接口。
- 粉丝列表接口。
- 关注列表接口。
- 拉黑接口。
- 取消拉黑接口。
- 静音接口。
- 取消静音接口。
- 首页 Timeline 接口，先使用 fanout-on-read。
- 用户主页 Timeline 接口。
- 预留 timeline_items 表。
- 预留 fanout-on-write Kafka Consumer。
- 发送 `UserFollowed` 事件。
- 发送 `UserUnfollowed` 事件。

### 数据库表

- follows。
- user_blocks。
- user_mutes。
- timeline_items。
- outbox_events。

### Kafka Topic

- social.events.v1。
- timeline.events.v1。
- notification.events.v1。

### Flutter 任务

- 首页 Timeline。
- 下拉刷新。
- 上拉加载。
- 用户主页关注按钮。
- 粉丝列表。
- 关注列表。
- 拉黑和静音操作。

验收标准：

- 用户可以关注和取消关注。
- 用户可以查看粉丝和关注列表。
- 首页展示已关注用户的帖子。
- 被拉黑或静音用户正确过滤。
- Timeline 使用 Cursor Pagination。

## 10. 第 6 阶段：互动和通知

周期：1-2 周。

### 后端任务

- 点赞接口。
- 取消点赞接口。
- 收藏接口。
- 取消收藏接口。
- 回复接口。
- 转发接口。
- 引用转发接口。
- 通知列表接口。
- 通知未读数接口。
- 标记通知已读接口。
- 全部通知已读接口。
- 通知设置接口。
- 设备 Push Token 注册接口。
- Push 分发 Consumer。
- 发送 `PostLiked` 事件。
- 发送 `PostBookmarked` 事件。
- 发送 `PostReplied` 事件。
- 发送 `NotificationCreated` 事件。

### 数据库表

- post_likes。
- post_bookmarks。
- notifications。
- notification_settings。
- device_tokens。
- posts。
- post_stats。
- outbox_events。

### Kafka Topic

- interaction.events.v1。
- notification.events.v1。

### Flutter 任务

- 点赞按钮和状态。
- 收藏按钮和状态。
- 回复输入框。
- 转发和引用入口。
- 通知页。
- 通知未读红点。
- Push Token 注册。
- Push 点击跳转。

验收标准：

- 点赞和取消点赞幂等。
- 计数正确更新。
- 回复会创建关联父帖的帖子。
- 点赞、关注、回复、提及可以创建通知。
- 测试环境可以收到 Push。

## 11. 第 7 阶段：搜索、审核、后台基础

周期：2 周。

### 后端任务

- 用户搜索接口。
- 帖子搜索接口。
- 话题搜索接口。
- Elasticsearch 本地开发配置。
- Elasticsearch `users_current`、`posts_current`、`hashtags_current` 索引模板。
- 搜索索引初始化脚本。
- `search-index-consumer` 消费 Kafka 并写入 Elasticsearch。
- 用户、帖子、话题索引 upsert/delete。
- 搜索结果回源 PostgreSQL 做权限、状态和最新统计校验。
- 搜索索引重建命令。
- 举报帖子接口。
- 举报用户接口。
- 后台举报列表接口。
- 后台举报处理接口。
- 隐藏帖子接口。
- 封禁用户接口。
- 敏感词过滤。
- 管理员操作审计日志。
- 发送 `ReportCreated` 事件。
- 发送 `ModerationActionCreated` 事件。

### 数据库表

- reports。
- moderation_actions。
- audit_logs。
- hashtags。
- post_hashtags。
- users。
- posts。

### Elasticsearch 索引

- users_current。
- posts_current。
- hashtags_current。

### Kafka Topic

- search.events.v1。
- moderation.events.v1。

### Flutter 任务

- 搜索页。
- 用户搜索结果页。
- 帖子搜索结果页。
- 话题结果页。
- 举报弹窗。
- 拉黑和静音入口。

### 后台任务

- 管理员登录守卫。
- 举报列表。
- 举报详情。
- 隐藏帖子。
- 封禁用户。
- 审计日志查看。

验收标准：

- 用户可以搜索用户和帖子。
- 用户可以搜索话题。
- 用户、帖子、话题变更可以同步到 Elasticsearch。
- 删除、隐藏、封禁后的内容不会出现在搜索结果。
- 搜索索引可以从 PostgreSQL 批量重建。
- 用户可以举报内容。
- 管理员可以处理举报。
- 被隐藏帖子不再出现在 Timeline。
- 管理员操作有审计日志。

## 12. 第 8 阶段：可观测性、测试、加固

周期：1-2 周。

### 可观测性任务

- API 和 Worker 接入 OpenTelemetry。
- 增加 Prometheus Metrics。
- 创建 Grafana Dashboard。
- 接入 Loki 日志采集。
- 接入后端 Sentry。
- 接入 Flutter Sentry。
- 增加 Kafka Consumer Lag Dashboard。
- 增加 Elasticsearch 集群健康 Dashboard。
- 增加 Elasticsearch 搜索延迟和索引失败率 Dashboard。
- 增加数据库慢查询 Dashboard。

### 测试任务

- Service 单元测试。
- Repository 数据库测试。
- API 集成测试。
- Kafka Consumer 集成测试。
- Flutter 核心页面 Widget Test。
- Flutter 冒烟集成测试。

### 安全任务

- API 限流。
- 登录失败限制。
- 密码策略。
- 请求体大小限制。
- Security Headers。
- CORS 白名单。
- 管理后台权限检查。
- 敏感操作审计日志。

### 性能任务

- Timeline API 压测。
- Login API 压测。
- Post Create API 压测。
- Kafka Consumer 吞吐测试。
- Elasticsearch 搜索延迟压测。
- Elasticsearch Bulk 写入吞吐测试。
- PostgreSQL 索引检查。
- Redis 热 Key 检查。

验收标准：

- P95 API 延迟可观测。
- 错误率可观测。
- Kafka Consumer Lag 可观测。
- Elasticsearch 集群健康、搜索延迟、索引失败率可观测。
- Worker 失败可观测。
- Flutter 崩溃上报可用。
- 核心 API 集成测试通过。
- 基础压测达到目标阈值。

## 13. 第 9 阶段：生产上线准备

周期：1 周。

任务：

- 生产 Docker 镜像。
- Helm Charts。
- Kubernetes 部署配置。
- 环境变量管理。
- 数据库备份策略。
- Redis 持久化策略。
- Kafka Topic 自动创建脚本。
- Cloudflare 域名和 WAF 配置。
- 对象存储 Bucket 权限。
- CDN 配置。
- CI/CD Pipeline。
- Staging 部署。
- Production 部署演练。
- 回滚流程。
- 故障响应清单。

验收标准：

- Staging 环境端到端可用。
- Production Secret 与 Staging 隔离。
- 数据库备份和恢复已测试。
- 回滚命令已测试。
- 告警已配置。

## 14. 第 10 阶段：私信聊天

周期：2-3 周。

定位：上线后第一期功能，不阻塞 MVP 生产上线。

### 后端任务

- 新增 Messaging Module。
- 新增 WebSocket 实时入口 `/ws/v1/realtime`。
- 新增会话创建接口。
- 新增会话列表接口。
- 新增历史消息分页接口。
- 新增发送消息接口。
- 新增消息撤回和删除接口。
- 新增已读回执接口。
- 新增 typing 状态 WebSocket 事件。
- 新增 Redis 在线状态和连接路由。
- 新增 `message-delivery-consumer`。
- 新增消息投递失败重试和 DLQ。
- 新增离线消息 Push 触发。
- 新增拉黑、静音、隐私设置校验。
- 新增消息频率限制和反刷策略。

### 数据库表

- conversations。
- conversation_members。
- messages。
- message_reads。
- message_reactions。
- message_attachments。
- message_delivery_receipts。

### Kafka Topic

- message.events.v1。
- message.events.retry.v1。
- message.events.dlq.v1。

### Kafka 事件

- ConversationCreated。
- ConversationMuted。
- MessageSent。
- MessageDelivered。
- MessageRead。
- MessageDeleted。
- MessageAttachmentUploaded。

### Redis Key

```txt
presence:user:{user_id}
ws:conn:{connection_id}
ws:user_connections:{user_id}
conversation:unread:{user_id}
rate_limit:message:{user_id}
```

### Flutter 任务

- 私信入口。
- 会话列表页。
- 聊天详情页。
- 消息输入框。
- 图片消息发送。
- 消息发送中、已发送、失败状态。
- 已读状态展示。
- typing 状态展示。
- WebSocket 连接管理。
- 断线重连和历史消息补拉。
- 本地消息缓存。

### 可观测性任务

- WebSocket 当前连接数。
- WebSocket 消息收发量。
- 消息投递 P50/P95/P99 延迟。
- message-delivery-consumer lag。
- 消息投递失败率。
- 私信频率限制命中数。

验收标准：

- 两个互相关注或允许私信的用户可以创建单聊会话。
- 用户可以发送和接收文本消息。
- 用户可以发送和接收图片消息。
- 在线用户可以通过 WebSocket 实时收到消息。
- 离线用户重新打开 App 后可以拉取未读消息。
- 离线用户可以收到 Push 通知。
- 已读回执可以正常更新。
- 拉黑用户不能继续发送私信。
- 消息发送具备客户端幂等，重复请求不会生成重复消息。
- message-delivery-consumer 失败可重试，最终失败进入 DLQ。

## 15. 工程规则

后端规则：

- Handler 不写业务逻辑。
- Handler 不直接使用 Ent Client。
- 每个外部请求必须有 request_id 和 trace_id。
- WebSocket 连接必须绑定 user_id、device_id、connection_id。
- 错误向上返回，只在边界记录日志。
- 多表业务写入必须使用事务。
- 所有领域事件通过 outbox_events 产生。
- Kafka Consumer 必须幂等。
- 消息发送必须使用 client_message_id 做客户端幂等。
- Timeline 和列表统一使用 Cursor Pagination。
- 私信历史消息统一使用 Cursor Pagination。

Flutter 规则：

- 网络请求只能通过 Dio Client。
- Token 只能通过 secure storage。
- Feature 状态使用 Riverpod。
- API DTO 和 UI Model 按需要分离。
- Timeline 列表必须支持下拉刷新和分页。
- 私信聊天必须支持断线重连和消息补拉。
- 错误必须映射成用户可理解的提示。

数据库规则：

- 主键使用 UUID。
- 所有业务表有 created_at。
- 可变表有 updated_at。
- 软删除表有 deleted_at。
- 高频查询必须显式建索引。
- 幂等业务操作必须有数据库唯一约束。

Kafka 规则：

- 每个事件必须有 event_id。
- 每个 Consumer 必须有 consumer group 名称。
- 每个 Consumer 必须幂等。
- 每个领域 Topic 必须有 retry 和 DLQ 策略。
- 事件结构变更必须提升 event_version。

## 16. 上线检查清单

- 注册登录可用。
- Token 刷新可用。
- 资料编辑可用。
- 头像上传可用。
- 发帖可用。
- 图片帖可用。
- 关注可用。
- 首页 Timeline 可用。
- 点赞可用。
- 回复可用。
- 转发可用。
- 通知可用。
- 搜索可用。
- 举报可用。
- 后台审核可用。
- Kafka Outbox Publisher 可用。
- Kafka Consumer 幂等。
- 日志、指标、链路追踪可见。
- Sentry 错误上报可用。
- 数据库备份可用。
- CI/CD 可用。
