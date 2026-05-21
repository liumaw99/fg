# 类 Twitter 社交 App 企业级架构设计

## 1. 架构定位

本项目从第一天采用企业级技术选型，但当前阶段不拆微服务。

第一版生产架构采用 **模块化单体**：

- 部署上是一个 Go API 服务。
- 部署上是一个 Go Worker 服务。
- 代码按领域模块拆分。
- 初期共用一个 PostgreSQL 数据库。
- 从第一天引入 Kafka 作为事件驱动骨架。
- 后续可以按模块边界逐步拆成微服务。

核心原则：

```txt
部署先单体
代码先模块化
数据先规范化
异步先事件化
观测先标准化
未来可拆服务
```

## 2. 技术选型

### Flutter 客户端

- Flutter：跨平台客户端框架。
- Riverpod：状态管理。
- GoRouter：路由和登录守卫。
- Dio：HTTP 客户端。
- Freezed：不可变数据模型。
- json_serializable：JSON 序列化。
- Isar：本地缓存、草稿箱、离线 Timeline 缓存。
- flutter_secure_storage：安全 Token 存储。
- Firebase Cloud Messaging：推送通知。
- Sentry：崩溃和错误监控。
- Firebase Analytics 或 Amplitude：产品数据分析。

推荐组合：

```txt
Flutter + Riverpod + GoRouter + Dio + Freezed + Isar + FCM + Sentry
```

### Go 后端

- Go：后端语言。
- Gin：HTTP API 框架。
- Wire：编译期依赖注入。
- Ent：ORM、Schema、Migration。
- Zap：结构化日志。
- PostgreSQL：核心业务数据库。
- Elasticsearch：用户、帖子、话题搜索引擎。
- Redis：缓存、限流、热点数据、Timeline 缓存。
- Kafka：业务事件流和异步处理骨架。
- OpenTelemetry：链路追踪。
- Prometheus：指标采集。
- Grafana：监控面板。
- Loki：日志聚合。
- Sentry：后端错误监控。

推荐组合：

```txt
Go + Gin + Wire + Ent + Zap + PostgreSQL + Elasticsearch + Redis + Kafka
```

### 基础设施

开发环境：

```txt
Docker Compose
PostgreSQL
Elasticsearch
Redis
Kafka
MinIO
OpenAPI UI
```

生产环境：

```txt
Docker
Kubernetes
Helm
Argo CD
GitHub Actions / GitLab CI
Managed PostgreSQL
Managed Elasticsearch 或 Elastic Cloud
Managed Redis
Managed Kafka 或 Kubernetes 自建 Kafka
Cloudflare
Cloudflare R2 / AWS S3
Prometheus
Grafana
Loki
Tempo / Jaeger
Sentry
```

## 3. 为什么直接使用 Kafka

这个产品是社交 App，天然是事件密集型系统。

Kafka 适合以下核心场景：

- Timeline 写扩散。
- 通知创建。
- Push 推送。
- 搜索索引同步。
- 媒体处理。
- 内容审核。
- 用户行为采集。
- 数据分析管道。
- 推荐系统特征收集。
- 审计与合规事件流。

相比普通任务队列，Kafka 的企业级价值更强：

- 事件日志持久化。
- Consumer Group 支持横向扩展。
- 事件可回放，方便重建搜索索引、Timeline、推荐特征和分析数据。
- 业务写入和副作用解耦。
- 更适合未来拆微服务。
- 更适合数据平台和推荐系统。

代价：

- 运维复杂度高于 Redis 任务队列。
- 需要设计 Topic、Partition Key、Consumer Group、幂等、重试和 DLQ。
- 本地开发需要 Docker Compose 启动 Kafka。

最终决策：

```txt
从第一天直接使用 Kafka。
不引入 Asynq。
Worker 直接消费 Kafka Topic。
使用 PostgreSQL outbox_events 保证业务写库和事件发布最终一致。
```

## 4. 总体架构

```txt
Flutter App
   |
   | HTTPS REST API
   v
Cloudflare / API Gateway / Ingress
   |
   v
Go API 模块化单体
   |
   |-- Auth Module
   |-- User Module
   |-- Social Graph Module
   |-- Post Module
   |-- Timeline Module
   |-- Interaction Module
   |-- Notification Module
   |-- Messaging Module
   |-- Media Module
   |-- Search Module
   |-- Moderation Module
   |-- Admin Module
   |
   |-- PostgreSQL
   |-- Elasticsearch
   |-- Redis
   |-- Object Storage
   |-- Kafka Producer
   v
Kafka
   |
   |-- user.events.v1
   |-- social.events.v1
   |-- post.events.v1
   |-- interaction.events.v1
   |-- media.events.v1
   |-- message.events.v1
   |-- notification.events.v1
   |-- moderation.events.v1
   |-- search.events.v1
   |-- timeline.events.v1
   |
   v
Go Worker 模块化单体
   |
   |-- Timeline Fanout Consumer
   |-- Notification Consumer
   |-- Push Consumer
   |-- Message Delivery Consumer
   |-- Search Index Consumer
   |-- Media Processing Consumer
   |-- Moderation Consumer
   |-- Analytics Consumer
```

## 5. 后端部署单元

第一版只有两个 Go 二进制：

```txt
cmd/api
cmd/worker
```

`cmd/api` 负责：

- HTTP API。
- 登录鉴权。
- 请求参数校验。
- 业务命令处理。
- 数据库事务写入。
- 创建 outbox event。
- 同步查询接口。

`cmd/worker` 负责：

- 扫描并发布 outbox event 到 Kafka。
- 消费 Kafka Topic。
- 执行异步副作用。
- 重试失败任务。
- 写入 DLQ 或失败记录。

## 6. 后端工程结构

```txt
server/
  cmd/
    api/
      main.go
    worker/
      main.go
    migrate/
      main.go

  internal/
    bootstrap/
      app.go
      router.go
      server.go
      worker.go

    config/
      config.go

    container/
      wire.go
      provider.go

    platform/
      logger/
      database/
      redis/
      kafka/
      storage/
      telemetry/
      response/
      errors/
      middleware/
      validator/
      pagination/
      security/

    module/
      auth/
      user/
      social/
      post/
      timeline/
      interaction/
      notification/
      messaging/
      media/
      search/
      moderation/
      admin/

    ent/
      schema/

  api/
    openapi/

  deploy/
    docker/
    helm/
    k8s/

  test/
    integration/
```

每个业务模块建议结构：

```txt
module/post/
  handler.go
  service.go
  repository.go
  dto.go
  event.go
  provider.go
```

工程规则：

- Handler 只处理 HTTP。
- Service 负责业务逻辑和事务边界。
- Repository 负责 Ent 查询。
- Event 定义放在产生事件的领域模块内。
- Ent Client 不直接泄漏到 Handler。
- 错误向上返回，只在中间件边界记录一次日志。

## 7. 领域模块

### Auth

职责：

- 注册。
- 登录。
- 刷新 Token。
- 退出登录。
- Session 管理。
- 找回密码。
- 设备管理。

### User

职责：

- 用户资料。
- 头像和封面。
- 用户设置。
- 用户统计。
- 账号状态。

### Social

职责：

- 关注。
- 取消关注。
- 粉丝列表。
- 关注列表。
- 拉黑。
- 静音。
- 私密账号关注申请，后置。

### Post

职责：

- 发帖。
- 删帖。
- 回复。
- 转发。
- 引用转发。
- 话题解析。
- 提及解析。

### Timeline

职责：

- 首页流。
- 用户主页流。
- 探索流。
- Timeline 写扩散。
- Timeline 缓存。

### Interaction

职责：

- 点赞。
- 取消点赞。
- 收藏。
- 取消收藏。
- 浏览数聚合。

### Notification

职责：

- 站内通知。
- 未读数。
- 已读状态。
- 通知设置。
- Push 推送。

### Messaging

职责：

- 单聊私信。
- 群聊私信，后置。
- 会话列表。
- 消息历史。
- 消息发送、撤回、删除。
- 已读回执。
- 未读数。
- 消息附件。
- 消息实时投递。
- 离线 Push 通知。
- 拉黑、静音、隐私设置校验。

实时通道：

- 第一版使用 WebSocket。
- HTTP API 负责会话列表、历史消息、补偿拉取、附件上传。
- WebSocket 负责新消息投递、typing、已读回执、在线状态通知。
- Redis 保存在线连接路由、用户在线状态和会话未读缓存。
- PostgreSQL 保存会话和消息权威数据。
- Kafka 负责消息投递事件、通知事件、Push 事件、审核事件。

私信发送流程：

```txt
Flutter 发送消息
  -> WebSocket 或 HTTP API
  -> Messaging Service 校验权限、拉黑、频率限制
  -> PostgreSQL 写入 messages
  -> 同事务写入 outbox_events
  -> Worker 发布 MessageSent 到 Kafka
  -> message-delivery-consumer 查询接收方在线状态
  -> 在线：通过 WebSocket 推送
  -> 离线：创建通知并触发 Push
```

消息一致性：

- 消息以 PostgreSQL 为权威数据。
- WebSocket 投递只作为实时通道，不作为持久化来源。
- 客户端发送消息使用 `client_message_id` 去重。
- 服务端返回 `message_id` 后客户端更新本地状态。
- 断线重连后通过 HTTP 拉取 `last_message_id` 之后的增量消息。

WebSocket 事件：

```txt
message.send
message.new
message.delivered
message.read
message.deleted
typing.start
typing.stop
presence.online
presence.offline
error
```

### Media

职责：

- 预签名上传 URL。
- 上传完成回调。
- 媒体元数据。
- 缩略图处理。
- 视频处理，后置。

### Search

职责：

- 用户搜索。
- 帖子搜索。
- 话题搜索。
- 搜索索引同步。

搜索存储：

- PostgreSQL 仍保存用户、帖子、话题的权威数据。
- Elasticsearch 保存面向检索的反范式索引。
- API 查询搜索结果时先查 Elasticsearch，再按需回源 PostgreSQL 补充权限、状态和最新统计。
- Kafka `search-index-consumer` 负责把用户、帖子、话题变更同步到 Elasticsearch。

第一版索引：

```txt
users_v1
posts_v1
hashtags_v1
```

索引写入事件：

```txt
UserRegistered
UserProfileUpdated
UserSuspended
UserBanned
PostCreated
PostDeleted
PostHidden
PostUpdated
HashtagCreated
HashtagUpdated
```

搜索能力：

- 用户昵称、用户名、简介搜索。
- 帖子正文搜索。
- 话题名称搜索。
- 按发布时间、互动热度、相关性排序。
- 过滤已删除、已隐藏、审核中、被拉黑作者的内容。

索引一致性：

- 业务写入 PostgreSQL 成功后，通过 outbox_events 发布领域事件。
- Worker 将领域事件发布到 Kafka。
- `search-index-consumer` 消费 Kafka 后 upsert 或 delete Elasticsearch 文档。
- Consumer 使用 `processed_events` 保证幂等。
- 搜索索引允许最终一致，关键权限和内容状态必须在返回前二次校验。

索引重建：

- 支持从 Kafka 历史事件回放重建。
- 支持从 PostgreSQL 批量扫描重建。
- 使用版本化索引和 alias 切换，例如 `posts_v1` -> `posts_v2`。
- 重建完成后原子切换 alias，避免线上搜索中断。

### Moderation

职责：

- 举报用户。
- 举报帖子。
- 敏感词过滤。
- 内容隐藏。
- 封禁用户。
- 审核动作审计。

### Admin

职责：

- 用户管理。
- 帖子管理。
- 举报审核。
- 审核操作。
- 系统配置。

## 8. Kafka 设计

### Topic 命名

按领域划分 Topic：

```txt
auth.events.v1
user.events.v1
social.events.v1
post.events.v1
interaction.events.v1
message.events.v1
media.events.v1
notification.events.v1
moderation.events.v1
search.events.v1
timeline.events.v1
```

重试 Topic：

```txt
post.events.retry.v1
interaction.events.retry.v1
message.events.retry.v1
notification.events.retry.v1
media.events.retry.v1
search.events.retry.v1
```

死信 Topic：

```txt
post.events.dlq.v1
interaction.events.dlq.v1
message.events.dlq.v1
notification.events.dlq.v1
media.events.dlq.v1
search.events.dlq.v1
```

### 事件信封

所有事件统一使用 envelope：

```json
{
  "event_id": "uuid",
  "event_type": "PostCreated",
  "event_version": 1,
  "aggregate_type": "post",
  "aggregate_id": "uuid",
  "occurred_at": "2026-05-21T00:00:00Z",
  "producer": "api",
  "trace_id": "trace-id",
  "payload": {}
}
```

### 核心事件

User 事件：

```txt
UserRegistered
UserProfileUpdated
UserSuspended
UserBanned
```

Social 事件：

```txt
UserFollowed
UserUnfollowed
UserBlocked
UserMuted
```

Post 事件：

```txt
PostCreated
PostUpdated
PostDeleted
PostReplied
PostReposted
PostQuoted
PostMentioned
```

Interaction 事件：

```txt
PostLiked
PostUnliked
PostBookmarked
PostViewed
```

Messaging 事件：

```txt
ConversationCreated
ConversationMuted
MessageSent
MessageDelivered
MessageRead
MessageDeleted
MessageAttachmentUploaded
```

Media 事件：

```txt
MediaUploaded
MediaReady
MediaRejected
```

Notification 事件：

```txt
NotificationCreated
NotificationRead
PushRequested
PushDelivered
PushFailed
```

Moderation 事件：

```txt
ReportCreated
PostHidden
UserSuspended
ModerationActionCreated
```

Search 索引事件：

```txt
HashtagCreated
HashtagUpdated
SearchDocumentIndexed
SearchDocumentDeleted
```

### Partition Key 策略

```txt
User events: user_id
Social events: follower_id 或 following_id
Post events: post_id 或 author_id
Interaction events: post_id 用于计数顺序，user_id 用于用户行为顺序
Message events: conversation_id，保证同一会话内消息顺序
Notification events: user_id
Search events: aggregate_id，用户用 user_id，帖子用 post_id，话题用 hashtag_id
Timeline fanout events: author_id
```

### Consumer Group

```txt
timeline-fanout-consumer
notification-consumer
push-consumer
message-delivery-consumer
search-index-consumer
media-processing-consumer
moderation-consumer
analytics-consumer
```

### 幂等设计

所有 Kafka Consumer 必须幂等。

推荐做法：

- 使用 `event_id` 作为幂等 Key。
- 用 `processed_events` 表记录已处理事件。
- 可以用 Redis 做短期幂等缓存，但关键业务仍建议落库。
- 天然幂等操作依赖数据库唯一约束。
- 写入类操作优先使用 UPSERT。

### 重试和 DLQ

处理策略：

- 临时性错误进入 retry topic。
- 超过最大重试次数进入 DLQ。
- DLQ 必须可观测、可查询、可人工重放。

建议记录：

```txt
retry_count
first_failed_at
last_failed_at
last_error
next_retry_at
```

## 9. Outbox Pattern

API 服务不要在业务事务中直接发布 Kafka。

使用 `outbox_events`：

1. Service 开启数据库事务。
2. 写入业务数据。
3. 同事务写入 outbox_events。
4. 事务提交。
5. Worker 扫描 pending outbox_events。
6. Worker 发布事件到 Kafka。
7. Worker 标记 outbox event 为已发布。

价值：

- 数据库提交后事件不会丢。
- 事务回滚时事件不会误发。
- 方便回放和排查问题。
- 未来拆微服务更安全。

## 10. Timeline 架构

### 阶段一：Fanout On Read

首页流：

```txt
获取当前用户关注列表
查询关注用户最近帖子
过滤拉黑、静音、隐藏、删除、审核中内容
按 published_at 倒序排序
Cursor 分页返回
```

优点是简单，适合早期上线。

### 阶段二：Kafka 驱动 Fanout On Write

发帖流程：

```txt
PostCreated event
  -> timeline-fanout-consumer
  -> 查询作者粉丝
  -> 写入粉丝 timeline_items
  -> 可选写入 Redis ZSet timeline cache
```

读 Timeline：

```txt
按 user_id 查询 timeline_items
根据 post_id 批量取帖子
补充作者、媒体、统计、当前用户互动状态
Cursor 分页返回
```

### 阶段三：混合 Timeline

混合策略：

- 普通用户：写扩散。
- 大 V 用户：读时合并。
- 推荐内容：由推荐消费者插入。
- 广告内容：后期由广告系统插入。

## 11. 数据库表摘要

核心表：

```txt
users
user_profiles
user_stats
user_sessions
follows
user_blocks
user_mutes
posts
post_stats
post_media
media_assets
post_likes
post_bookmarks
post_views
conversations
conversation_members
messages
message_reads
message_reactions
message_attachments
message_delivery_receipts
notifications
notification_settings
device_tokens
hashtags
post_hashtags
mentions
reports
moderation_actions
audit_logs
outbox_events
processed_events
```

### conversations

会话表，单聊和群聊共用。

```sql
conversations
- id              uuid pk
- type            varchar(32) not null -- direct/group
- title           varchar(128) null
- avatar_url      text null
- last_message_id uuid null
- last_message_at timestamptz null
- created_by      uuid not null
- created_at      timestamptz not null
- updated_at      timestamptz not null
```

### conversation_members

会话成员表。

```sql
conversation_members
- id              uuid pk
- conversation_id uuid not null
- user_id         uuid not null
- role            varchar(32) not null -- owner/admin/member
- status          varchar(32) not null -- active/left/removed
- muted_until     timestamptz null
- last_read_at    timestamptz null
- last_read_message_id uuid null
- joined_at       timestamptz not null
- left_at         timestamptz null
- created_at      timestamptz not null
- updated_at      timestamptz not null
```

唯一约束：

```txt
unique(conversation_id, user_id)
```

### messages

消息表。

```sql
messages
- id                uuid pk
- conversation_id   uuid not null
- sender_id         uuid not null
- client_message_id varchar(128) not null
- type              varchar(32) not null -- text/image/file/system
- body              text null
- status            varchar(32) not null -- sent/deleted/hidden
- reply_to_id       uuid null
- created_at        timestamptz not null
- updated_at        timestamptz not null
- deleted_at        timestamptz null
```

唯一约束：

```txt
unique(sender_id, client_message_id)
```

### message_reads

消息已读表。单聊可以只依赖 `conversation_members.last_read_message_id`，群聊或精确回执再使用该表。

```sql
message_reads
- id              uuid pk
- message_id      uuid not null
- conversation_id uuid not null
- user_id         uuid not null
- read_at         timestamptz not null
- created_at      timestamptz not null
```

唯一约束：

```txt
unique(message_id, user_id)
```

### message_attachments

消息附件表。

```sql
message_attachments
- id          uuid pk
- message_id  uuid not null
- media_id    uuid not null
- type        varchar(32) not null
- sort_order  int not null
- created_at  timestamptz not null
```

### message_delivery_receipts

消息投递回执表，用于排查和可观测，不要求每条消息强一致写入。

```sql
message_delivery_receipts
- id              uuid pk
- message_id      uuid not null
- conversation_id uuid not null
- user_id         uuid not null
- status          varchar(32) not null -- delivered/failed
- delivered_at    timestamptz null
- last_error      text null
- created_at      timestamptz not null
- updated_at      timestamptz not null
```

### processed_events

用于 Kafka Consumer 幂等。

```sql
processed_events
- id             uuid pk
- event_id       uuid not null
- event_type     varchar(128) not null
- consumer_group varchar(128) not null
- processed_at   timestamptz not null
- created_at     timestamptz not null
```

唯一约束：

```txt
unique(event_id, consumer_group)
```

## 12. Elasticsearch 设计

Elasticsearch 不作为业务真相源，只作为搜索索引和排序引擎。

### 索引规划

```txt
users_v1
posts_v1
hashtags_v1
```

Alias：

```txt
users_current -> users_v1
posts_current -> posts_v1
hashtags_current -> hashtags_v1
```

### posts_current 文档字段

```json
{
  "post_id": "uuid",
  "author_id": "uuid",
  "author_username": "alice",
  "author_display_name": "Alice",
  "text": "post text",
  "hashtags": ["go", "flutter"],
  "mentions": ["bob"],
  "language": "zh",
  "like_count": 10,
  "reply_count": 2,
  "repost_count": 1,
  "view_count": 100,
  "visibility": "public",
  "status": "published",
  "is_deleted": false,
  "is_hidden": false,
  "published_at": "2026-05-21T00:00:00Z",
  "updated_at": "2026-05-21T00:00:00Z"
}
```

### users_current 文档字段

```json
{
  "user_id": "uuid",
  "username": "alice",
  "display_name": "Alice",
  "bio": "builder",
  "avatar_url": "https://cdn.example.com/a.png",
  "follower_count": 100,
  "post_count": 20,
  "status": "active",
  "is_private": false,
  "created_at": "2026-05-21T00:00:00Z",
  "updated_at": "2026-05-21T00:00:00Z"
}
```

### hashtags_current 文档字段

```json
{
  "hashtag_id": "uuid",
  "name": "golang",
  "post_count": 1200,
  "last_used_at": "2026-05-21T00:00:00Z"
}
```

### 查询策略

- 用户搜索使用 `username` 精确前缀匹配 + `display_name`、`bio` 分词匹配。
- 帖子搜索使用 `text` 分词匹配，叠加发布时间和互动数据排序。
- 话题搜索使用 `name` 前缀匹配，叠加 `post_count` 和 `last_used_at` 排序。
- 中文内容需要启用合适中文分词器，例如 IK 或 Elastic 内置 CJK 分析能力。
- 查询结果返回前必须过滤当前用户拉黑、静音、不可见内容。

### 写入策略

```txt
领域事件 -> Kafka -> search-index-consumer -> Elasticsearch bulk upsert/delete
```

- 批量写入优先使用 Bulk API。
- 短时间高频计数字段可以合并刷新，避免每次点赞都更新索引。
- 删除、隐藏、封禁类事件必须尽快更新索引。
- 写入失败进入 `search.events.retry.v1`，最终失败进入 `search.events.dlq.v1`。

### 可观测性

必须监控：

- Elasticsearch 集群健康状态。
- 索引文档数。
- 搜索 P50/P95/P99 延迟。
- Bulk 写入失败率。
- search-index-consumer lag。
- DLQ 事件数量。

## 13. API 风格

外部客户端使用 REST：

```txt
/api/v1/auth/*
/api/v1/users/*
/api/v1/social/*
/api/v1/posts/*
/api/v1/timeline/*
/api/v1/interactions/*
/api/v1/notifications/*
/api/v1/conversations/*
/api/v1/messages/*
/api/v1/media/*
/api/v1/search/*
/api/v1/moderation/*
/api/v1/admin/*
```

规范：

- 使用 OpenAPI 维护接口文档。
- Timeline、通知、评论、搜索结果统一使用 Cursor Pagination。
- 错误码统一管理。
- 所有请求都有 request_id。

WebSocket 入口：

```txt
/ws/v1/realtime
```

WebSocket 规范：

- 使用 Access Token 鉴权。
- 连接建立后绑定 user_id、device_id、connection_id。
- Redis 维护 `user_id -> connection_id` 路由。
- 客户端需要心跳保活。
- 服务端需要连接数限制和消息频率限制。
- 断线重连后客户端通过 HTTP 补拉消息。

## 14. 可观测性

API 日志字段：

```txt
service
env
version
request_id
trace_id
user_id
method
path
status
latency_ms
ip
user_agent
error_code
error_message
```

核心指标：

```txt
api_requests_total
api_request_duration_seconds
api_errors_total
db_query_duration_seconds
redis_operations_total
kafka_producer_errors_total
kafka_consumer_lag
kafka_consumer_errors_total
websocket_connections_current
websocket_messages_total
message_delivery_duration_seconds
message_delivery_errors_total
elasticsearch_query_duration_seconds
elasticsearch_index_errors_total
timeline_generation_duration_seconds
notification_delivery_total
push_delivery_total
```

## 15. 安全基线

- JWT Access Token。
- Refresh Token Rotation。
- Argon2id 或 bcrypt 密码哈希。
- 登录失败限流。
- API 限流。
- 请求体大小限制。
- CORS 白名单。
- 安全响应头。
- 敏感操作审计日志。
- 管理员角色隔离。
- 拉黑、静音、举报、审核能力。

## 16. 未来拆服务顺序

流量增长后，建议按这个顺序拆：

1. Media Worker / Media Service。
2. Search Indexer / Search Service。
3. Notification Service。
4. Timeline Service。
5. Social Graph Service。
6. Recommendation Service。

Kafka 和 Outbox 能保证这条拆分路径更平滑，因为模块之间已经通过事件解耦。
