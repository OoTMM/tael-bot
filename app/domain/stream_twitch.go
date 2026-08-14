package domain

import "time"

type StreamTwitch struct {
	ID           string
	UserID       string
	UserLogin    string
	UserName     string
	Title        string
	Language     string
	ThumbnailURL string
	ViewerCount  int
	StartedAt    time.Time
	SyncedAt     time.Time
}
