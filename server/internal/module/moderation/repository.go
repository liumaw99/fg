package moderation

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/post"
	"social-server/internal/ent/report"
	"social-server/internal/ent/user"
	"social-server/internal/ent/userprofile"
)

// Repository handles database operations for moderation.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new moderation repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateReport creates a new report.
func (r *Repository) CreateReport(ctx context.Context, reporterID uuid.UUID, targetUserID, targetPostID *uuid.UUID, reportType, reason string) (*ent.Report, error) {
	builder := r.client.Report.Create().
		SetReporterID(reporterID).
		SetType(reportType).
		SetReason(reason)

	if targetUserID != nil {
		builder = builder.SetTargetUserID(*targetUserID)
	}
	if targetPostID != nil {
		builder = builder.SetTargetPostID(*targetPostID)
	}

	rep, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create report: %w", err)
	}
	return rep, nil
}

// GetReportByID retrieves a report by ID.
func (r *Repository) GetReportByID(ctx context.Context, id uuid.UUID) (*ent.Report, error) {
	rep, err := r.client.Report.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("report not found")
		}
		return nil, fmt.Errorf("get report: %w", err)
	}
	return rep, nil
}

// ListReports retrieves reports with pagination.
func (r *Repository) ListReports(ctx context.Context, status string, cursor string, limit int) ([]*ent.Report, error) {
	q := r.client.Report.Query().
		Order(ent.Desc(report.FieldCreatedAt))

	if status != "" {
		q = q.Where(report.Status(status))
	}

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			rep, err := r.client.Report.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					report.Or(
						report.CreatedAtLT(rep.CreatedAt),
						report.And(
							report.CreatedAtEQ(rep.CreatedAt),
							report.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	reports, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list reports: %w", err)
	}
	return reports, nil
}

// UpdateReportStatus updates a report's status.
func (r *Repository) UpdateReportStatus(ctx context.Context, reportID uuid.UUID, status, notes string, reviewedBy uuid.UUID) error {
	_, err := r.client.Report.UpdateOneID(reportID).
		SetStatus(status).
		SetReviewNotes(notes).
		SetReviewedBy(reviewedBy).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("update report: %w", err)
	}
	return nil
}

// CreateModerationAction creates a moderation action.
func (r *Repository) CreateModerationAction(ctx context.Context, moderatorID uuid.UUID, targetUserID, targetPostID, reportID *uuid.UUID, actionType, reason string) (*ent.ModerationAction, error) {
	builder := r.client.ModerationAction.Create().
		SetModeratorID(moderatorID).
		SetActionType(actionType).
		SetReason(reason)

	if targetUserID != nil {
		builder = builder.SetTargetUserID(*targetUserID)
	}
	if targetPostID != nil {
		builder = builder.SetTargetPostID(*targetPostID)
	}
	if reportID != nil {
		builder = builder.SetReportID(*reportID)
	}

	action, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create moderation action: %w", err)
	}
	return action, nil
}

// SearchUsers searches users by username or display name.
func (r *Repository) SearchUsers(ctx context.Context, query string, limit int) ([]*ent.User, error) {
	users, err := r.client.User.Query().
		Where(
			user.Or(
				user.UsernameContains(query),
			),
		).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("search users: %w", err)
	}
	return users, nil
}

// SearchPosts searches posts by content.
func (r *Repository) SearchPosts(ctx context.Context, query string, limit int) ([]*ent.Post, error) {
	posts, err := r.client.Post.Query().
		Where(
			post.And(
				post.Status("active"),
				post.ContentContains(query),
			),
		).
		Order(ent.Desc(post.FieldCreatedAt)).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("search posts: %w", err)
	}
	return posts, nil
}

// GetUserProfile retrieves a user profile.
func (r *Repository) GetUserProfile(ctx context.Context, userID uuid.UUID) (*ent.UserProfile, error) {
	p, err := r.client.UserProfile.Query().
		Where(userprofile.UserID(userID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("profile not found")
		}
		return nil, fmt.Errorf("get profile: %w", err)
	}
	return p, nil
}
