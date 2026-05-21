package validator

import (
	"fmt"
	"regexp"
	"strings"
)

var (
	usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_]{3,30}$`)
	emailRegex    = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	uuidRegex     = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)
)

// ValidateUsername checks if username is valid.
func ValidateUsername(username string) error {
	if !usernameRegex.MatchString(username) {
		return fmt.Errorf("username must be 3-30 characters, alphanumeric and underscores only")
	}
	return nil
}

// ValidateEmail checks if email format is valid.
func ValidateEmail(email string) error {
	if !emailRegex.MatchString(email) {
		return fmt.Errorf("invalid email format")
	}
	return nil
}

// ValidatePassword checks password strength.
func ValidatePassword(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}
	return nil
}

// ValidateUUID checks if string is a valid UUID.
func ValidateUUID(id string) error {
	if !uuidRegex.MatchString(id) {
		return fmt.Errorf("invalid uuid format")
	}
	return nil
}

// SanitizeText trims whitespace and normalizes.
func SanitizeText(s string) string {
	return strings.TrimSpace(s)
}

// MaxLength checks string length.
func MaxLength(s string, max int) error {
	if len(s) > max {
		return fmt.Errorf("exceeds maximum length of %d", max)
	}
	return nil
}

// NotEmpty checks if string is not empty after trimming.
func NotEmpty(s string) error {
	if strings.TrimSpace(s) == "" {
		return fmt.Errorf("required field is empty")
	}
	return nil
}
