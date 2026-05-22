package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"social-server/internal/config"
	"social-server/internal/ent"
	"social-server/internal/ent/postlike"
	"social-server/internal/ent/user"
	"social-server/internal/ent/userprofile"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/security"
)

// Seed data for Chinese social app demo with real media
//
// 图片来源说明：
// - 头像：DiceBear notionists / lorelei / avataaars 风格生成器（稳定 PNG）
// - 封面：Picsum.photos 固定 seed 的随机图（每次同样）
// - 帖子配图：Picsum.photos 固定 seed 风景/抽象/城市图
// 全部支持热链接，无版权问题。

const (
	// DiceBear 头像 API：根据 seed 生成稳定头像
	avatarBase = "https://api.dicebear.com/9.x/notionists/png?seed=%s&radius=50&backgroundColor=transparent"
	// Picsum 固定 seed：URL 不变则图片不变
	coverBase = "https://picsum.photos/seed/%s/1500/500"
	postImage = "https://picsum.photos/seed/%s/1200/675"
)

type seedUser struct {
	username    string
	email       string
	password    string
	displayName string
	bio         string
	location    string
	website     string
}

var (
	usersData = []seedUser{
		{"zhangsan", "zhangsan@example.com", "password123", "张三", "热爱编程与生活的全栈开发者 | Go × Flutter", "北京", "https://github.com/zhangsan"},
		{"lisi", "lisi@example.com", "password123", "李四", "前端工程师 | 设计爱好者 | 偶尔写写文字", "上海", ""},
		{"wangwu", "wangwu@example.com", "password123", "王五", "产品经理，专注用户体验和增长策略", "深圳", "https://wangwu.design"},
		{"zhaoliu", "zhaoliu@example.com", "password123", "赵六", "摄影师 / 旅行者 / 不务正业程序员", "成都", ""},
		{"qianqi", "qianqi@example.com", "password123", "钱七", "AI 研究员 | 深度学习 | 论文搬运工", "杭州", "https://arxiv.org"},
		{"sunba", "sunba@example.com", "password123", "孙八", "美食博主，走遍天下吃遍天下", "广州", ""},
		{"zhoujiu", "zhoujiu@example.com", "password123", "周九", "独立开发者，创业中，欢迎合作", "武汉", "https://zhoujiu.dev"},
		{"wushi", "wushi@example.com", "password123", "吴十", "UI 设计师，极简主义信徒", "南京", ""},
		{"zheng11", "zheng11@example.com", "password123", "郑十一", "技术写作者 | 开源贡献者", "西安", "https://blog.zheng11.com"},
		{"feng12", "feng12@example.com", "password123", "冯十二", "DevOps 工程师，云原生 / SRE", "重庆", ""},
	}

	// 帖子内容：(content, withMedia, numImages, imageSeedPrefix)
	postsData = []struct {
		content        string
		mediaCount     int
		imageSeedTheme string
	}{
		{"今天终于上线了我们团队的新功能，三个月的努力终于变成现实。复盘一下：用户调研 → 原型设计 → 技术评审 → 灰度发布 → 监控反馈。每一步都不能省。", 0, ""},
		{"分享一下最近在学习 Flutter 的心得。跨平台开发的关键不是「一次编写到处运行」，而是「同一套业务逻辑，针对不同平台做合适的体验」。", 1, "code"},
		{"周末去了一趟西湖，杭州的春天太美了。随手拍了几张，分享给大家。", 4, "westlake"},
		{"有人推荐好用的 VSCode 插件吗？我目前在用 GitLens、Error Lens、Prettier、Tailwind IntelliSense，还有什么必装的？", 0, ""},
		{"刚刚发布了一个开源项目：一个轻量级的 Go 微服务脚手架。集成了 Gin + Ent + Wire + Zap + Kafka，开箱即用。欢迎 star 和 PR。", 1, "github"},
		{"面试了一家心仪的公司，三轮技术 + 一轮 HR。希望能有好消息。等待 offer 是最煎熬的环节。", 0, ""},
		{"今天 mob programming 了一下午，效率出奇地高。三个人一起想边界条件，bug 提前消灭，code review 直接省了。", 0, ""},
		{"发现了 Riverpod 代码生成的妙用，@riverpod 注解 + build_runner，省去了一大堆 Provider 样板代码。喜欢这种渐进式的 API 设计。", 1, "riverpod"},
		{"深夜食堂：一碗热腾腾的兰州牛肉面 + 一瓶冰啤酒，治愈了一天的疲惫。", 1, "noodle"},
		{"看完了《黑客与画家》，Paul Graham 的视角真的很独特。「优秀的程序员是平均水平的 5-10 倍，但工资只多 50%」这句话让我反复思考。", 1, "book"},
		{"团队新来的小伙伴技术能力很强，今天给我讲了一下 eBPF 在性能分析里的应用，开了眼界。", 0, ""},
		{"终于把家里的网络环境搭建好了：软路由（OpenWrt）+ NAS（群晖）+ Wi-Fi 6 mesh。家里所有设备无缝漫游，4K 流媒体流畅得不行。", 2, "homelab"},
		{"Go 语言的错误处理一直被吐槽，但用久了反而觉得清晰。errors.Is / errors.As / fmt.Errorf with %w，配合 sentinel error 模式，可读性很高。", 0, ""},
		{"最近在研究微服务架构，发现「拆分服务」远比「合并服务」难得多。一旦边界划错，团队就要为此付出长期代价。", 0, ""},
		{"周末和几个朋友爬了趟黄山，五点起来看日出，云海让人忘了所有烦恼。", 3, "huangshan"},
		{"写了一个自动化部署脚本，从 git push 到 Kubernetes 滚动更新，全程 90 秒。终于不用每次手动 kubectl apply 了。", 1, "devops"},
		{"咖啡续命中，今晚要把这个数据迁移脚本调完。从 MySQL 迁到 PostgreSQL，几百万行数据，索引重建是关键。", 1, "coffee"},
		{"今天参加了 GopherCon China，听了 Rob Pike 的主题演讲，对 Go 1.25 的新特性很期待。", 1, "conference"},
		{"家里的橘猫又把我键盘踩了一遍，留下了一长串「nhuyjbtgvrfcdexsw」的神秘字符。", 1, "cat"},
		{"在 GitHub 上发现了一个宝藏项目：用 Rust 实现的 Redis 替代品，性能据说比原版高 30%。准备周末试一下。", 1, "rust"},
		{"今天学会了用 Docker Compose 的 healthcheck + depends_on，配合 wait-for-it.sh，启动顺序问题终于解决了。", 0, ""},
		{"Spring Boot 用久了再换 Gin，感觉清爽多了。少了那么多 IoC / AOP 的魔法，代码逻辑一目了然。各有所爱吧。", 0, ""},
		{"公司的 code review 流程越来越规范，每个 PR 至少 2 个 reviewer，重要模块要 Tech Lead 把关。质量明显提升。", 0, ""},
		{"去图书馆借了《设计数据密集型应用》《SRE 实战》《代码大全》，准备这个季度好好充充电。", 1, "books"},
		{"写技术文档比写代码更费脑。要换位思考，要照顾不同水平的读者，要有逻辑，要有图。但写好的文档，能省下同事几小时的沟通成本。", 0, ""},
		{"新入手的客制化机械键盘（HHKB 60% + 静电容轴），手感真的不一样，码字效率翻倍，写代码也变得很享受。", 1, "keyboard"},
		{"今天解决了困扰三天的 bug：发现是因为 Go map 在并发写入时会 panic，而我忘了加 sync.RWMutex。教训。", 0, ""},
		{"推荐大家试试 PostgreSQL：JSONB、CTE、Window Function、Partial Index、Generated Columns…功能丰富得离谱。", 1, "postgres"},
		{"在家办公的好处之一：可以随时撸猫休息。效率反而比在公司更高，会议也少。", 1, "cat2"},
		{"终于理解了 Knuth 那句「代码是写给人看的，机器执行只是顺便」。当你 review 自己半年前写的代码时，感受最深刻。", 0, ""},
	}

	repliesData = []string{
		"同感！我也遇到了类似的情况，准备试试你的方案。",
		"这个思路很棒，学到了，回去就实践一下。",
		"请问具体是怎么实现的？方便分享一下代码片段吗？",
		"加油！期待你的后续分享。",
		"太真实了，我也是一样的体验。",
		"感谢分享，很有参考价值，已经收藏。",
		"收藏了，回头仔细研究下细节。",
		"说得很有道理，受教了。",
		"我们团队也在用类似的方案，效果不错。",
		"这个工具确实好用，强烈推荐。",
	}
)

func avatarURL(seed string) string  { return fmt.Sprintf(avatarBase, seed) }
func coverURL(seed string) string   { return fmt.Sprintf(coverBase, seed) }
func postImgURL(seed string) string { return fmt.Sprintf(postImage, seed) }

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--help" {
		fmt.Println("usage: go run ./cmd/seed")
		fmt.Println("  Seeds the database with demo users, posts, follows, likes, messages,")
		fmt.Println("  avatars, covers, and post media (all from public CDN URLs).")
		os.Exit(0)
	}

	cfg, err := config.Load(".")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to load config: %v\n", err)
		os.Exit(1)
	}

	log, err := logger.New(cfg.LogLevel, cfg.ServiceName, cfg.Env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create logger: %v\n", err)
		os.Exit(1)
	}
	defer log.Sync()

	ctx := context.Background()

	client, err := ent.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatal("failed to connect database", logger.Error(err))
	}
	defer client.Close()

	log.Info("starting database seed...")

	users, err := seedUsers(ctx, client, log)
	if err != nil {
		log.Fatal("failed to seed users", logger.Error(err))
	}
	log.Info("seeded users", logger.Int("count", len(users)))

	posts, err := seedPosts(ctx, client, users, log)
	if err != nil {
		log.Fatal("failed to seed posts", logger.Error(err))
	}
	log.Info("seeded posts", logger.Int("count", len(posts)))

	if err := seedFollows(ctx, client, users, log); err != nil {
		log.Fatal("failed to seed follows", logger.Error(err))
	}
	log.Info("seeded follows")

	if err := seedLikes(ctx, client, users, posts, log); err != nil {
		log.Fatal("failed to seed likes", logger.Error(err))
	}
	log.Info("seeded likes")

	if err := seedReplies(ctx, client, users, posts, log); err != nil {
		log.Fatal("failed to seed replies", logger.Error(err))
	}
	log.Info("seeded replies")

	if err := seedNotifications(ctx, client, users, posts, log); err != nil {
		log.Fatal("failed to seed notifications", logger.Error(err))
	}
	log.Info("seeded notifications")

	if err := seedMessages(ctx, client, users, log); err != nil {
		log.Fatal("failed to seed messages", logger.Error(err))
	}
	log.Info("seeded conversations and messages")

	log.Info("database seed completed successfully")
}

// seedUsers creates users with profile images (avatar + cover).
func seedUsers(ctx context.Context, client *ent.Client, log *logger.Logger) ([]*ent.User, error) {
	var users []*ent.User

	for _, u := range usersData {
		// 检查是否已存在 → 同时更新 profile 字段（让旧 seed 的用户也带头像）
		existing, err := client.User.Query().Where(user.Username(u.username)).Only(ctx)
		if err == nil {
			if err := upsertProfile(ctx, client, existing.ID, u); err != nil {
				return nil, fmt.Errorf("update profile for %s: %w", u.username, err)
			}
			users = append(users, existing)
			continue
		}

		hash, err := security.HashPassword(u.password)
		if err != nil {
			return nil, fmt.Errorf("hash password for %s: %w", u.username, err)
		}

		newUser, err := client.User.Create().
			SetUsername(u.username).
			SetEmail(u.email).
			SetPasswordHash(hash).
			Save(ctx)
		if err != nil {
			return nil, fmt.Errorf("create user %s: %w", u.username, err)
		}

		if err := upsertProfile(ctx, client, newUser.ID, u); err != nil {
			return nil, fmt.Errorf("create profile for %s: %w", u.username, err)
		}

		_, err = client.UserStats.Create().
			SetUserID(newUser.ID).
			Save(ctx)
		if err != nil {
			return nil, fmt.Errorf("create stats for %s: %w", u.username, err)
		}

		users = append(users, newUser)
	}

	return users, nil
}

// upsertProfile creates or updates a user's profile with avatar + cover.
func upsertProfile(ctx context.Context, client *ent.Client, userID uuid.UUID, u seedUser) error {
	avatar := avatarURL(u.username)
	cover := coverURL(u.username + "-cover")

	existing, err := client.UserProfile.Query().
		Where(userprofile.UserID(userID)).
		Only(ctx)
	if err == nil {
		_, err = client.UserProfile.UpdateOneID(existing.ID).
			SetDisplayName(u.displayName).
			SetBio(u.bio).
			SetLocation(u.location).
			SetWebsite(u.website).
			SetAvatarURL(avatar).
			SetCoverURL(cover).
			Save(ctx)
		return err
	}

	_, err = client.UserProfile.Create().
		SetUserID(userID).
		SetDisplayName(u.displayName).
		SetBio(u.bio).
		SetLocation(u.location).
		SetWebsite(u.website).
		SetAvatarURL(avatar).
		SetCoverURL(cover).
		Save(ctx)
	return err
}

// seedPosts creates main posts and attaches media for those with mediaCount>0.
func seedPosts(ctx context.Context, client *ent.Client, users []*ent.User, log *logger.Logger) ([]*ent.Post, error) {
	var posts []*ent.Post
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for i, p := range postsData {
		author := users[rng.Intn(len(users))]

		post, err := client.Post.Create().
			SetUserID(author.ID).
			SetContent(p.content).
			SetStatus("active").
			SetVisibility("public").
			Save(ctx)
		if err != nil {
			return nil, fmt.Errorf("create post: %w", err)
		}

		_, err = client.PostStats.Create().
			SetPostID(post.ID).
			Save(ctx)
		if err != nil {
			return nil, fmt.Errorf("create post stats: %w", err)
		}

		// Attach media
		for j := 0; j < p.mediaCount; j++ {
			seed := fmt.Sprintf("%s-%d-%d", p.imageSeedTheme, i, j)
			url := postImgURL(seed)

			asset, err := client.MediaAsset.Create().
				SetOwnerID(author.ID).
				SetFilename(seed + ".jpg").
				SetMimeType("image/jpeg").
				SetSize(0).
				SetURL(url).
				SetThumbnailURL(url).
				SetStatus("active").
				Save(ctx)
			if err != nil {
				return nil, fmt.Errorf("create media asset: %w", err)
			}

			_, err = client.PostMedia.Create().
				SetPostID(post.ID).
				SetMediaAssetID(asset.ID).
				SetSortOrder(j).
				Save(ctx)
			if err != nil {
				return nil, fmt.Errorf("create post media link: %w", err)
			}
		}

		posts = append(posts, post)
	}

	return posts, nil
}

func seedFollows(ctx context.Context, client *ent.Client, users []*ent.User, log *logger.Logger) error {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for i, follower := range users {
		maxFollows := len(users) - 1
		if maxFollows < 1 {
			continue
		}
		numFollows := 2 + rng.Intn(maxFollows-1)
		if numFollows > maxFollows {
			numFollows = maxFollows
		}
		followed := make(map[int]bool)

		for len(followed) < numFollows {
			targetIdx := rng.Intn(len(users))
			if targetIdx == i || followed[targetIdx] {
				continue
			}
			followed[targetIdx] = true

			target := users[targetIdx]
			_, err := client.Follow.Create().
				SetFollowerID(follower.ID).
				SetFollowingID(target.ID).
				Save(ctx)
			if err != nil {
				if ent.IsConstraintError(err) {
					continue
				}
				return fmt.Errorf("create follow: %w", err)
			}
		}
	}

	return nil
}

func seedLikes(ctx context.Context, client *ent.Client, users []*ent.User, posts []*ent.Post, log *logger.Logger) error {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for _, post := range posts {
		maxLikes := len(users) - 1
		if maxLikes > 8 {
			maxLikes = 8
		}
		if maxLikes < 1 {
			continue
		}
		numLikes := 1 + rng.Intn(maxLikes)
		likedBy := make(map[uuid.UUID]bool)

		for len(likedBy) < numLikes {
			liker := users[rng.Intn(len(users))]
			if likedBy[liker.ID] {
				continue
			}
			likedBy[liker.ID] = true

			_, err := client.PostLike.Create().
				SetPostID(post.ID).
				SetUserID(liker.ID).
				Save(ctx)
			if err != nil {
				if ent.IsConstraintError(err) {
					continue
				}
				return fmt.Errorf("create like: %w", err)
			}
		}
	}

	return nil
}

func seedReplies(ctx context.Context, client *ent.Client, users []*ent.User, posts []*ent.Post, log *logger.Logger) error {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for _, parentPost := range posts {
		if rng.Float32() > 0.35 {
			continue
		}

		numReplies := 1 + rng.Intn(3)
		for i := 0; i < numReplies; i++ {
			author := users[rng.Intn(len(users))]
			content := repliesData[rng.Intn(len(repliesData))]

			reply, err := client.Post.Create().
				SetUserID(author.ID).
				SetContent(content).
				SetReplyToID(parentPost.ID).
				SetStatus("active").
				SetVisibility("public").
				Save(ctx)
			if err != nil {
				return fmt.Errorf("create reply: %w", err)
			}

			_, err = client.PostStats.Create().
				SetPostID(reply.ID).
				Save(ctx)
			if err != nil {
				return fmt.Errorf("create reply stats: %w", err)
			}
		}
	}

	return nil
}

func seedNotifications(ctx context.Context, client *ent.Client, users []*ent.User, posts []*ent.Post, log *logger.Logger) error {
	for _, post := range posts[:min(10, len(posts))] {
		likes, err := client.PostLike.Query().
			Where(postlike.PostID(post.ID)).
			All(ctx)
		if err != nil {
			continue
		}

		for _, like := range likes {
			if like.UserID == post.UserID {
				continue
			}

			_, err = client.Notification.Create().
				SetUserID(post.UserID).
				SetActorID(like.UserID).
				SetType("like").
				SetPostID(post.ID).
				SetContent("赞了你的动态").
				Save(ctx)
			if err != nil {
				return fmt.Errorf("create notification: %w", err)
			}
		}
	}

	follows, err := client.Follow.Query().All(ctx)
	if err != nil {
		return fmt.Errorf("query follows: %w", err)
	}

	for _, f := range follows {
		_, err = client.Notification.Create().
			SetUserID(f.FollowingID).
			SetActorID(f.FollowerID).
			SetType("follow").
			SetContent("关注了你").
			Save(ctx)
		if err != nil {
			return fmt.Errorf("create follow notification: %w", err)
		}
	}

	allNotifs, err := client.Notification.Query().All(ctx)
	if err != nil {
		return err
	}

	for i, n := range allNotifs {
		if i%3 == 0 {
			_, _ = client.Notification.UpdateOneID(n.ID).
				SetIsRead(true).
				Save(ctx)
		}
	}

	return nil
}

func seedMessages(ctx context.Context, client *ent.Client, users []*ent.User, log *logger.Logger) error {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	conversations := []struct{ u1, u2 int }{
		{0, 1}, {0, 2}, {1, 3}, {2, 4}, {3, 5},
		{4, 6}, {5, 7}, {6, 8}, {7, 9}, {8, 0},
	}

	messageContents := []string{
		"你好，最近在忙什么项目？",
		"那个新功能我已经实现了，要不要看看代码？",
		"周末有空吗，一起出来喝杯咖啡？",
		"这个项目的技术选型你有什么建议？",
		"刚看到你的动态，那个问题我也遇到过。",
		"好的，没问题，我来处理这个 bug。",
		"这个设计方案我觉得不错，可以推进。",
		"谢谢分享，这个工具确实好用。",
		"晚上一起吃饭吗？我请客。",
		"代码 review 完了，有几个小问题需要改一下。",
		"明天下午有个技术分享会，一起去吗？",
		"收到，我会尽快处理。",
		"这个功能的用户反馈很好，可以继续优化。",
		"周末去爬山吗，天气很好。",
		"数据库迁移脚本写好了，你检查一下。",
	}

	for _, pair := range conversations {
		u1 := users[pair.u1]
		u2 := users[pair.u2]

		conv, err := client.Conversation.Create().
			SetType("direct").
			SetTitle(fmt.Sprintf("%s 和 %s", u1.Username, u2.Username)).
			Save(ctx)
		if err != nil {
			return fmt.Errorf("create conversation: %w", err)
		}

		_, err = client.ConversationMember.Create().
			SetConversationID(conv.ID).
			SetUserID(u1.ID).
			Save(ctx)
		if err != nil {
			return fmt.Errorf("add member: %w", err)
		}

		_, err = client.ConversationMember.Create().
			SetConversationID(conv.ID).
			SetUserID(u2.ID).
			Save(ctx)
		if err != nil {
			return fmt.Errorf("add member: %w", err)
		}

		numMessages := 5 + rng.Intn(11)
		var lastMessageID uuid.UUID
		var lastMessageAt time.Time

		for i := 0; i < numMessages; i++ {
			sender := u1
			if i%2 == 1 {
				sender = u2
			}

			content := messageContents[rng.Intn(len(messageContents))]
			clientMsgID := fmt.Sprintf("seed-%d-%d", conv.ID.Time(), i)

			msg, err := client.Message.Create().
				SetConversationID(conv.ID).
				SetSenderID(sender.ID).
				SetContent(content).
				SetType("text").
				SetClientMessageID(clientMsgID).
				Save(ctx)
			if err != nil {
				return fmt.Errorf("create message: %w", err)
			}

			lastMessageID = msg.ID
			lastMessageAt = msg.CreatedAt
		}

		if lastMessageID != uuid.Nil {
			_, _ = client.Conversation.UpdateOneID(conv.ID).
				SetLastMessageID(lastMessageID).
				SetLastMessageAt(lastMessageAt).
				Save(ctx)
		}
	}

	return nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
