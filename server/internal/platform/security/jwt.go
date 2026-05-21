package security

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// Claims represents JWT claims.
type Claims struct {
	UserID  string `json:"user_id"`
	TokenID string `json:"token_id"`
	Type    string `json:"type"`
	jwt.RegisteredClaims
}

func (c *Claims) GetUserID() string  { return c.UserID }
func (c *Claims) GetTokenID() string { return c.TokenID }

func (c *Claims) Valid() error {
	if c.ExpiresAt != nil && c.ExpiresAt.Before(time.Now()) {
		return fmt.Errorf("token expired")
	}
	return nil
}

// JWTManager handles token generation and validation.
type JWTManager struct {
	secret      []byte
	accessTTL   time.Duration
	refreshTTL  time.Duration
}

// NewJWTManager creates a new JWT manager.
func NewJWTManager(secret string, accessTTLMinutes, refreshTTLDays int) *JWTManager {
	return &JWTManager{
		secret:     []byte(secret),
		accessTTL:  time.Duration(accessTTLMinutes) * time.Minute,
		refreshTTL: time.Duration(refreshTTLDays) * 24 * time.Hour,
	}
}

// GenerateAccessToken creates a new access token.
func (m *JWTManager) GenerateAccessToken(userID string) (string, *Claims, error) {
	tokenID := uuid.Must(uuid.NewRandom()).String()
	now := time.Now()
	claims := &Claims{
		UserID:  userID,
		TokenID: tokenID,
		Type:    "access",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(m.accessTTL)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ID:        tokenID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(m.secret)
	if err != nil {
		return "", nil, fmt.Errorf("sign token: %w", err)
	}
	return signed, claims, nil
}

// GenerateRefreshToken creates a new refresh token.
func (m *JWTManager) GenerateRefreshToken(userID string) (string, *Claims, error) {
	tokenID := uuid.Must(uuid.NewRandom()).String()
	now := time.Now()
	claims := &Claims{
		UserID:  userID,
		TokenID: tokenID,
		Type:    "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(m.refreshTTL)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ID:        tokenID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(m.secret)
	if err != nil {
		return "", nil, fmt.Errorf("sign token: %w", err)
	}
	return signed, claims, nil
}

// Validate parses and validates a token string.
func (m *JWTManager) Validate(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return m.secret, nil
	})
	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token claims")
	}

	return claims, nil
}

// ValidateAccessToken validates an access token.
func (m *JWTManager) ValidateAccessToken(tokenString string) (*Claims, error) {
	claims, err := m.Validate(tokenString)
	if err != nil {
		return nil, err
	}
	if claims.Type != "access" {
		return nil, fmt.Errorf("invalid token type")
	}
	return claims, nil
}

// ValidateRefreshToken validates a refresh token.
func (m *JWTManager) ValidateRefreshToken(tokenString string) (*Claims, error) {
	claims, err := m.Validate(tokenString)
	if err != nil {
		return nil, err
	}
	if claims.Type != "refresh" {
		return nil, fmt.Errorf("invalid token type")
	}
	return claims, nil
}
