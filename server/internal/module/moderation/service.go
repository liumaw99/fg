package moderation

import (
	"context"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/pagination"
)

// Service handles moderation business logic.
type Service struct {
	repo *Repository
	log  *logger.Logger
}

// NewService creates a new moderation service.
func NewService(repo *Repository, log *logger.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// CreateReport creates a new report.
func (s *Service) CreateReport(ctx context.Context, reporterID uuid.UUID, req ReportRequest) (*ReportResponse, error) {
	if req.TargetUserID == "" && req.TargetPostID == "" {
		return nil, errors.New("invalid_target", 400, "must specify target_user_id or target_post_id")
	}

	var targetUserID, targetPostID *uuid.UUID
	if req.TargetUserID != "" {
		id, err := uuid.Parse(req.TargetUserID)
		if err != nil {
			return nil, errors.New("invalid_user_id", 400, "invalid target_user_id")
		}
		// Verify user exists
		if _, err := s.repo.client.User.Get(ctx, id); err != nil {
			return nil, errors.ErrNotFound
		}
		targetUserID = &id
	}

	if req.TargetPostID != "" {
		id, err := uuid.Parse(req.TargetPostID)
		if err != nil {
			return nil, errors.New("invalid_post_id", 400, "invalid target_post_id")
		}
		// Verify post exists
		if _, err := s.repo.client.Post.Get(ctx, id); err != nil {
			return nil, errors.ErrNotFound
		}
		targetPostID = &id
	}

	rep, err := s.repo.CreateReport(ctx, reporterID, targetUserID, targetPostID, req.Type, req.Reason)
	if err != nil {
		s.log.Error("failed to create report", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildReportResponse(rep), nil
}

// ListReports retrieves reports for admin review.
func (s *Service) ListReports(ctx context.Context, status string, params pagination.Params) (*ReportListResponse, error) {
	params.ValidateAndNormalize(50)

	reports, err := s.repo.ListReports(ctx, status, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list reports", logger.Error(err))
		return nil, errors.ErrInternal
	}

	hasMore := len(reports) > params.Limit
	if hasMore {
		reports = reports[:params.Limit]
	}

	var items []ReportResponse
	for _, r := range reports {
		items = append(items, *s.buildReportResponse(r))
	}

	result := &ReportListResponse{
		Reports: items,
		HasMore: hasMore,
	}

	if hasMore && len(reports) > 0 {
		result.NextCursor = reports[len(reports)-1].ID.String()
	}

	return result, nil
}

// TakeAction performs a moderation action on a report.
func (s *Service) TakeAction(ctx context.Context, moderatorID uuid.UUID, req ModerationActionRequest) error {
	var targetUserID, targetPostID, reportID *uuid.UUID

	if req.TargetUserID != "" {
		id, err := uuid.Parse(req.TargetUserID)
		if err != nil {
			return errors.New("invalid_user_id", 400, "invalid target_user_id")
		}
		targetUserID = &id
	}
	if req.TargetPostID != "" {
		id, err := uuid.Parse(req.TargetPostID)
		if err != nil {
			return errors.New("invalid_post_id", 400, "invalid target_post_id")
		}
		targetPostID = &id
	}
	if req.ReportID != "" {
		id, err := uuid.Parse(req.ReportID)
		if err != nil {
			return errors.New("invalid_report_id", 400, "invalid report_id")
		}
		reportID = &id
	}

	// Create moderation action
	_, err := s.repo.CreateModerationAction(ctx, moderatorID, targetUserID, targetPostID, reportID, req.ActionType, req.Reason)
	if err != nil {
		s.log.Error("failed to create moderation action", logger.Error(err))
		return errors.ErrInternal
	}

	// Update report status if report_id provided
	if reportID != nil {
		if err := s.repo.UpdateReportStatus(ctx, *reportID, "resolved", req.Reason, moderatorID); err != nil {
			s.log.Error("failed to update report status", logger.Error(err))
		}
	}

	// Handle specific action types
	switch req.ActionType {
	case "hide_post":
		if targetPostID != nil {
			_, err := s.repo.client.Post.UpdateOneID(*targetPostID).SetStatus("hidden").Save(ctx)
			if err != nil {
				s.log.Error("failed to hide post", logger.Error(err))
			}
		}
	case "ban_user":
		if targetUserID != nil {
			_, err := s.repo.client.User.UpdateOneID(*targetUserID).SetStatus("banned").Save(ctx)
			if err != nil {
				s.log.Error("failed to ban user", logger.Error(err))
			}
		}
	}

	s.log.Info("moderation action taken",
		logger.String("moderator_id", moderatorID.String()),
		logger.String("action_type", req.ActionType),
	)

	return nil
}

// Search searches users and posts.
func (s *Service) Search(ctx context.Context, req SearchRequest) (*SearchResponse, error) {
	if req.Query == "" {
		return &SearchResponse{Results: []SearchResult{}}, nil
	}

	query := strings.TrimSpace(req.Query)
	if len(query) > 100 {
		query = query[:100]
	}

	var results []SearchResult
	searchType := req.Type
	if searchType == "" {
		searchType = "all"
	}

	// Search users
	if searchType == "all" || searchType == "users" {
		users, err := s.repo.SearchUsers(ctx, query, 10)
		if err != nil {
			s.log.Error("failed to search users", logger.Error(err))
		} else {
			for _, u := range users {
				results = append(results, SearchResult{
					ID:       u.ID.String(),
					Type:     "user",
					Title:    u.Username,
					Subtitle: "@" + u.Username,
				})
			}
		}
	}

	// Search posts
	if searchType == "all" || searchType == "posts" {
		posts, err := s.repo.SearchPosts(ctx, query, 10)
		if err != nil {
			s.log.Error("failed to search posts", logger.Error(err))
		} else {
			for _, p := range posts {
				content := p.Content
				if utf8.RuneCountInString(content) > 100 {
					runes := []rune(content)
					content = string(runes[:100]) + "..."
				}
				results = append(results, SearchResult{
					ID:      p.ID.String(),
					Type:    "post",
					Title:   "Post",
					Content: content,
				})
			}
		}
	}

	return &SearchResponse{
		Results: results,
		HasMore: false,
	}, nil
}

func (s *Service) buildReportResponse(rep *ent.Report) *ReportResponse {
	r := &ReportResponse{
		ID:         rep.ID.String(),
		ReporterID: rep.ReporterID.String(),
		Type:       rep.Type,
		Reason:     rep.Reason,
		Status:     rep.Status,
		ReviewNotes: rep.ReviewNotes,
		CreatedAt:  rep.CreatedAt,
	}
	if rep.TargetUserID != uuid.Nil {
		r.TargetUserID = rep.TargetUserID.String()
	}
	if rep.TargetPostID != uuid.Nil {
		r.TargetPostID = rep.TargetPostID.String()
	}
	if rep.ReviewedBy != uuid.Nil {
		r.ReviewedBy = rep.ReviewedBy.String()
	}
	if !rep.ReviewedAt.IsZero() {
		r.ReviewedAt = rep.ReviewedAt
	}
	return r
}
