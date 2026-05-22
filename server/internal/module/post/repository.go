package post

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/mediaasset"
	"social-server/internal/ent/post"
	"social-server/internal/ent/postlike"
	"social-server/internal/ent/postmedia"
	"social-server/internal/ent/poststats"
	"social-server/internal/ent/user"
	"social-server/internal/ent/userprofile"
)

// Repository handles database operations for posts.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new post repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreatePost creates a new post.
func (r *Repository) CreatePost(ctx context.Context, userID uuid.UUID, content string, mediaAssetIDs []uuid.UUID) (*ent.Post, error) {
	builder := r.client.Post.Create().
		SetUserID(userID).
		SetContent(content)

	p, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create post: %w", err)
	}

	// Create post media links
	for i, mediaID := range mediaAssetIDs {
		err = r.client.PostMedia.Create().
			SetPostID(p.ID).
			SetMediaAssetID(mediaID).
			SetSortOrder(i).
			Exec(ctx)
		if err != nil {
			return nil, fmt.Errorf("create post media: %w", err)
		}
	}

	// Create stats
	_, err = r.client.PostStats.Create().
		SetPostID(p.ID).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create post stats: %w", err)
	}

	return p, nil
}

// CountOwnedMediaAssets counts media assets owned by user.
func (r *Repository) CountOwnedMediaAssets(ctx context.Context, ownerID uuid.UUID, ids []uuid.UUID) (int, error) {
	if len(ids) == 0 {
		return 0, nil
	}
	count, err := r.client.MediaAsset.Query().
		Where(
			mediaasset.IDIn(ids...),
			mediaasset.OwnerID(ownerID),
			mediaasset.Status("uploaded"),
		).
		Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("count owned media assets: %w", err)
	}
	return count, nil
}

// CreateReply creates a reply post under parentPostID.
func (r *Repository) CreateReply(ctx context.Context, userID, parentPostID uuid.UUID, content string) (*ent.Post, error) {
	p, err := r.client.Post.Create().
		SetUserID(userID).
		SetContent(content).
		SetReplyToID(parentPostID).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create reply: %w", err)
	}

	_, err = r.client.PostStats.Create().
		SetPostID(p.ID).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create reply stats: %w", err)
	}

	return p, nil
}

// GetPostByID retrieves a post by ID.
func (r *Repository) GetPostByID(ctx context.Context, id uuid.UUID) (*ent.Post, error) {
	p, err := r.client.Post.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("post not found")
		}
		return nil, fmt.Errorf("get post: %w", err)
	}
	return p, nil
}

// GetPostWithMedia retrieves a post with its media.
func (r *Repository) GetPostWithMedia(ctx context.Context, id uuid.UUID) (*ent.Post, []*ent.PostMedia, error) {
	p, err := r.GetPostByID(ctx, id)
	if err != nil {
		return nil, nil, err
	}

	media, err := r.client.PostMedia.Query().
		Where(postmedia.PostID(id)).
		Order(ent.Asc(postmedia.FieldSortOrder)).
		All(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("get post media: %w", err)
	}

	return p, media, nil
}

// GetPostStats retrieves stats for a post.
func (r *Repository) GetPostStats(ctx context.Context, postID uuid.UUID) (*ent.PostStats, error) {
	s, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("post stats not found")
		}
		return nil, fmt.Errorf("get post stats: %w", err)
	}
	return s, nil
}

// DeletePost soft-deletes a post.
func (r *Repository) DeletePost(ctx context.Context, id uuid.UUID) error {
	_, err := r.client.Post.UpdateOneID(id).
		SetStatus("deleted").
		Save(ctx)
	if err != nil {
		return fmt.Errorf("delete post: %w", err)
	}
	return nil
}

// IncrementReplyCount increments the reply count in post stats.
func (r *Repository) IncrementReplyCount(ctx context.Context, postID uuid.UUID) error {
	stats, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	return r.client.PostStats.UpdateOne(stats).
		AddReplyCount(1).
		Exec(ctx)
}

func (r *Repository) DecrementReplyCount(ctx context.Context, postID uuid.UUID) error {
	stats, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	if stats.ReplyCount <= 0 {
		return nil
	}
	return r.client.PostStats.UpdateOne(stats).
		AddReplyCount(-1).
		Exec(ctx)
}

func (r *Repository) CountReplyDescendants(ctx context.Context, postID uuid.UUID, maxDepth int) (int, error) {
	if maxDepth <= 0 {
		return 0, nil
	}

	count := 0
	frontier := []uuid.UUID{postID}
	for depth := 0; depth < maxDepth && len(frontier) > 0; depth++ {
		replies, err := r.client.Post.Query().
			Where(
				post.ReplyToIDIn(frontier...),
				post.Status("active"),
			).
			All(ctx)
		if err != nil {
			return 0, fmt.Errorf("count reply descendants: %w", err)
		}

		count += len(replies)
		frontier = frontier[:0]
		for _, reply := range replies {
			frontier = append(frontier, reply.ID)
		}
	}

	return count, nil
}

// ListReplies retrieves active replies for a post, oldest first.
func (r *Repository) ListReplies(ctx context.Context, postID uuid.UUID, limit int) ([]*ent.Post, error) {
	replies, err := r.client.Post.Query().
		Where(
			post.ReplyToID(postID),
			post.Status("active"),
		).
		Order(ent.Asc(post.FieldCreatedAt)).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list replies: %w", err)
	}
	return replies, nil
}

// ListRepliesForParents retrieves active direct replies for multiple parent posts.
func (r *Repository) ListRepliesForParents(ctx context.Context, parentIDs []uuid.UUID, limitPerParent int) (map[uuid.UUID][]*ent.Post, error) {
	result := make(map[uuid.UUID][]*ent.Post, len(parentIDs))
	if len(parentIDs) == 0 {
		return result, nil
	}

	replies, err := r.client.Post.Query().
		Where(
			post.ReplyToIDIn(parentIDs...),
			post.Status("active"),
		).
		Order(ent.Asc(post.FieldCreatedAt)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list child replies: %w", err)
	}

	for _, reply := range replies {
		parentID := reply.ReplyToID
		if limitPerParent > 0 && len(result[parentID]) >= limitPerParent {
			continue
		}
		result[parentID] = append(result[parentID], reply)
	}
	return result, nil
}

// ListReplyDescendants retrieves replies grouped by direct parent for a bounded reply tree.
func (r *Repository) ListReplyDescendants(ctx context.Context, rootIDs []uuid.UUID, maxDepth, limitPerRoot int) (map[uuid.UUID][]*ent.Post, error) {
	result := make(map[uuid.UUID][]*ent.Post, len(rootIDs))
	if len(rootIDs) == 0 || maxDepth <= 0 {
		return result, nil
	}

	frontier := append([]uuid.UUID(nil), rootIDs...)
	owner := make(map[uuid.UUID]uuid.UUID, len(rootIDs))
	ownerCount := make(map[uuid.UUID]int, len(rootIDs))
	for _, id := range rootIDs {
		owner[id] = id
	}

	for depth := 0; depth < maxDepth && len(frontier) > 0; depth++ {
		replies, err := r.client.Post.Query().
			Where(
				post.ReplyToIDIn(frontier...),
				post.Status("active"),
			).
			Order(ent.Asc(post.FieldCreatedAt)).
			All(ctx)
		if err != nil {
			return nil, fmt.Errorf("list reply descendants: %w", err)
		}

		next := make([]uuid.UUID, 0, len(replies))
		for _, reply := range replies {
			rootID, ok := owner[reply.ReplyToID]
			if !ok {
				continue
			}
			if limitPerRoot > 0 && ownerCount[rootID] >= limitPerRoot {
				continue
			}
			result[reply.ReplyToID] = append(result[reply.ReplyToID], reply)
			ownerCount[rootID]++
			owner[reply.ID] = rootID
			next = append(next, reply.ID)
		}
		frontier = next
	}

	return result, nil
}

// CreateNotification creates a post-related notification.
func (r *Repository) CreateNotification(ctx context.Context, userID, actorID uuid.UUID, notifType string, postID uuid.UUID, content string) error {
	if userID == actorID {
		return nil
	}
	err := r.client.Notification.Create().
		SetUserID(userID).
		SetActorID(actorID).
		SetType(notifType).
		SetPostID(postID).
		SetContent(content).
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("create notification: %w", err)
	}
	return nil
}

// ListUserPosts retrieves posts by a user with cursor pagination.
func (r *Repository) ListUserPosts(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.Post, error) {
	q := r.client.Post.Query().
		Where(
			post.UserID(userID),
			post.Status("active"),
			post.ReplyToIDIsNil(),
		).
		Order(ent.Desc(post.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			p, err := r.client.Post.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					post.Or(
						post.CreatedAtLT(p.CreatedAt),
						post.And(
							post.CreatedAtEQ(p.CreatedAt),
							post.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	posts, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list user posts: %w", err)
	}
	return posts, nil
}

// ListPosts retrieves all active posts with cursor pagination.
func (r *Repository) ListPosts(ctx context.Context, cursor string, limit int) ([]*ent.Post, error) {
	q := r.client.Post.Query().
		Where(
			post.Status("active"),
			post.ReplyToIDIsNil(),
		).
		Order(ent.Desc(post.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			p, err := r.client.Post.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					post.Or(
						post.CreatedAtLT(p.CreatedAt),
						post.And(
							post.CreatedAtEQ(p.CreatedAt),
							post.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	posts, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list posts: %w", err)
	}
	return posts, nil
}

// GetMediaAssets retrieves media assets by IDs.
func (r *Repository) GetMediaAssets(ctx context.Context, ids []uuid.UUID) ([]*ent.MediaAsset, error) {
	assets, err := r.client.MediaAsset.Query().
		Where(mediaasset.IDIn(ids...)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("get media assets: %w", err)
	}
	return assets, nil
}

// GetPostMediaAssets retrieves media assets for a post.
func (r *Repository) GetPostMediaAssets(ctx context.Context, postID uuid.UUID) ([]*ent.PostMedia, error) {
	media, err := r.client.PostMedia.Query().
		Where(postmedia.PostID(postID)).
		Order(ent.Asc(postmedia.FieldSortOrder)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("get post media: %w", err)
	}
	return media, nil
}

// IsLiked checks if a user liked a post.
func (r *Repository) IsLiked(ctx context.Context, postID, userID uuid.UUID) (bool, error) {
	exists, err := r.client.PostLike.Query().
		Where(
			postlike.PostID(postID),
			postlike.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return false, fmt.Errorf("check like: %w", err)
	}
	return exists, nil
}

// CreateOutboxEvent creates an outbox event within the same transaction.
func (r *Repository) CreateOutboxEvent(ctx context.Context, topic, key string, payload map[string]any) error {
	err := r.client.OutboxEvent.Create().
		SetTopic(topic).
		SetKey(key).
		SetPayload(payload).
		SetStatus("pending").
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("create outbox event: %w", err)
	}
	return nil
}

// AuthorInfo bundles the user + profile data needed to populate PostAuthor.
type AuthorInfo struct {
	ID          uuid.UUID
	Username    string
	DisplayName string
	AvatarURL   string
}

// GetAuthorsByIDs batch-fetches user+profile info for the given user IDs.
// Returns a map keyed by user ID. Missing IDs are simply absent from the map.
func (r *Repository) GetAuthorsByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]*AuthorInfo, error) {
	result := make(map[uuid.UUID]*AuthorInfo, len(ids))
	if len(ids) == 0 {
		return result, nil
	}

	users, err := r.client.User.Query().
		Where(user.IDIn(ids...)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("query users: %w", err)
	}

	profiles, err := r.client.UserProfile.Query().
		Where(userprofile.UserIDIn(ids...)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("query user profiles: %w", err)
	}
	profileMap := make(map[uuid.UUID]*ent.UserProfile, len(profiles))
	for _, p := range profiles {
		profileMap[p.UserID] = p
	}

	for _, u := range users {
		info := &AuthorInfo{
			ID:       u.ID,
			Username: u.Username,
		}
		if p, ok := profileMap[u.ID]; ok {
			info.DisplayName = p.DisplayName
			info.AvatarURL = p.AvatarURL
		}
		result[u.ID] = info
	}
	return result, nil
}
