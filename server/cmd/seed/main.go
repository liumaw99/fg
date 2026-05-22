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
	"social-server/internal/platform/logger"
	"social-server/internal/platform/security"
)

// Seed data for Chinese social app demo

var (
	usersData = []struct {
		username    string
		email       string
		password    string
		displayName string
		bio         string
		location    string
	}{
		{"zhangsan", "zhangsan@example.com", "password123", "张三", "热爱编程与生活的全栈开发者", "北京"},
		{"lisi", "lisi@example.com", "password123", "李四", "前端工程师 | 设计爱好者", "上海"},
		{"wangwu", "wangwu@example.com", "password123", "王五", "产品经理，专注用户体验", "深圳"},
		{"zhaoliu", "zhaoliu@example.com", "password123", "赵六", "摄影师 / 旅行者", "成都"},
		{"qianqi", "qianqi@example.com", "password123", "钱七", "AI 研究员 | 深度学习", "杭州"},
		{"sunba", "sunba@example.com", "password123", "孙八", "美食博主，走遍天下吃遍天下", "广州"},
		{"zhoujiu", "zhoujiu@example.com", "password123", "周九", "独立开发者，创业中", "武汉"},
		{"wushi", "wushi@example.com", "password123", "吴十", "UI 设计师，极简主义", "南京"},
		{"zheng11", "zheng11@example.com", "password123", "郑十一", "技术写作者，开源贡献者", "西安"},
		{"feng12", "feng12@example.com", "password123", "冯十二", "DevOps 工程师，云原生", "重庆"},
	}

	postsData = []string{
		"今天终于完成了这个新功能的开发，感觉非常有成就感！",
		"分享一下最近在学习 Flutter 的心得，跨平台开发真的很香。",
		"周末去了一趟西湖，风景太美了，随手拍了几张照片。",
		"有人推荐好用的代码编辑器插件吗？想提升一下效率。",
		"刚刚发布了一个开源项目，欢迎大家来提 issue 和 PR！",
		"面试了一家心仪的公司，希望能拿到 offer。",
		"今天的工作效率特别高，把一周的代码都重构完了。",
		"发现了 Riverpod 代码生成的新用法，代码变得清爽多了。",
		"深夜食堂：一碗热腾腾的牛肉面，治愈了一天的疲惫。",
		"看了《黑客与画家》，对编程有了新的理解。",
		"团队新来的小伙伴技术能力很强，学习了很多新思路。",
		"终于把家里的网络环境搭建好了，NAS + 软路由真香。",
		"Go 语言的错误处理机制设计得真好，代码可靠性大幅提升。",
		"最近在研究微服务架构，感觉还是有很多坑要踩。",
		"周末约了几个朋友去爬山，户外运动真的能让人放松心情。",
		"写了一个自动化部署脚本，省了好多手动操作的时间。",
		"咖啡续命中，今晚要把这个项目赶出来。",
		"参加了技术分享会，听到了很多前沿的实践方案。",
		"家里的猫又把我键盘踩了一遍，产出了一堆神秘代码。",
		"在 GitHub 上发现了一个宝藏项目，star 数量涨得好快。",
		"今天学会了使用 Docker Compose 编排多容器应用。",
		"Spring Boot 用久了，换到 Gin 框架感觉轻量了很多。",
		"公司的代码 review 流程越来越规范了，质量提升明显。",
		"去图书馆借了几本技术书，准备好好充充电。",
		"写文档比写代码还累，但为了让同事理解，值得。",
		"新入手的机械键盘手感真不错，码字效率翻倍。",
		"今天解决了困扰三天的 bug，原来是一个拼写错误。",
		"推荐大家试试 PostgreSQL，比 MySQL 好用太多了。",
		"在家办公的好处是可以随时撸猫，效率反而更高了。",
		"终于理解了为什么大家都说「代码是写给人看的」。",
	}

	repliesData = []string{
		"同感！我也遇到了类似的情况。",
		"这个思路很棒，学到了。",
		"请问具体是怎么实现的？",
		"加油！期待你的后续分享。",
		"太真实了，我也一样。",
		"感谢分享，很有参考价值。",
		"收藏了，回头仔细研究。",
		"说得很有道理，受教了。",
	}
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--help" {
		fmt.Println("usage: go run ./cmd/seed")
		fmt.Println("  Seeds the database with demo users, posts, follows, likes, and messages.")
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

func seedUsers(ctx context.Context, client *ent.Client, log *logger.Logger) ([]*ent.User, error) {
	var users []*ent.User

	for _, u := range usersData {
		// Check if user already exists
		existing, err := client.User.Query().
			Where(user.Username(u.username)).
			Only(ctx)
		if err == nil {
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

		_, err = client.UserProfile.Create().
			SetUserID(newUser.ID).
			SetDisplayName(u.displayName).
			SetBio(u.bio).
			SetLocation(u.location).
			Save(ctx)
		if err != nil {
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

func seedPosts(ctx context.Context, client *ent.Client, users []*ent.User, log *logger.Logger) ([]*ent.Post, error) {
	var posts []*ent.Post
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for _, content := range postsData {
		user := users[rng.Intn(len(users))]

		post, err := client.Post.Create().
			SetUserID(user.ID).
			SetContent(content).
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

		posts = append(posts, post)
	}

	return posts, nil
}

func seedFollows(ctx context.Context, client *ent.Client, users []*ent.User, log *logger.Logger) error {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	for i, follower := range users {
		// Cap follows at len(users)-1 to avoid infinite loop
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
		// Cap likes at min(len(users), 8) to avoid infinite loop
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
			user := users[rng.Intn(len(users))]
			if likedBy[user.ID] {
				continue
			}
			likedBy[user.ID] = true

			_, err := client.PostLike.Create().
				SetPostID(post.ID).
				SetUserID(user.ID).
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
		if rng.Float32() > 0.3 {
			continue
		}

		numReplies := 1 + rng.Intn(3)
		for i := 0; i < numReplies; i++ {
			user := users[rng.Intn(len(users))]
			content := repliesData[rng.Intn(len(repliesData))]

			reply, err := client.Post.Create().
				SetUserID(user.ID).
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
	// Create like notifications for first 10 posts
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

	// Create follow notifications
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

	// Mark some notifications as read
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

	conversations := []struct {
		u1 int
		u2 int
	}{
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
