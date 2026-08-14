package store

import (
	"context"
	"database/sql"
	"time"

	"github.com/OoTMM/tael-bot/app/domain"
)

type StreamTwitchStore struct {
	db *sql.DB
}

func NewStreamTwitchStore(db *sql.DB) *StreamTwitchStore {
	return &StreamTwitchStore{
		db: db,
	}
}

func (s *StreamTwitchStore) Upsert(ctx context.Context, stream *domain.StreamTwitch) error {
	const query = `
		INSERT INTO streams_twitch (
			id, user_id, user_login, user_name, title, language, thumbnail_url, viewer_count, started_at, synced_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT (id) DO UPDATE SET
			user_id = excluded.user_id,
			user_login = excluded.user_login,
			user_name = excluded.user_name,
			title = excluded.title,
			language = excluded.language,
			thumbnail_url = excluded.thumbnail_url,
			viewer_count = excluded.viewer_count,
			started_at = excluded.started_at,
			synced_at = excluded.synced_at
	`

	_, err := s.db.ExecContext(ctx, query,
		stream.ID,
		stream.UserID,
		stream.UserLogin,
		stream.UserName,
		stream.Title,
		stream.Language,
		stream.ThumbnailURL,
		stream.ViewerCount,
		stream.StartedAt.UTC().Format(time.RFC3339),
		stream.SyncedAt.UTC().Format(time.RFC3339),
	)
	return err
}

func (s *StreamTwitchStore) DeleteOld(ctx context.Context, olderThan time.Time) error {
	const query = `
		DELETE FROM streams_twitch
		WHERE synced_at < ?
	`

	_, err := s.db.ExecContext(ctx, query, olderThan.UTC().Format(time.RFC3339))
	return err
}

func (s *StreamTwitchStore) GetAll(ctx context.Context) ([]*domain.StreamTwitch, error) {
	const query = `
		SELECT id, user_id, user_login, user_name, title, language, thumbnail_url, viewer_count, started_at, synced_at
		FROM streams_twitch
	`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var streams []*domain.StreamTwitch
	for rows.Next() {
		var stream domain.StreamTwitch
		var startedAtStr, syncedAtStr string

		err := rows.Scan(
			&stream.ID,
			&stream.UserID,
			&stream.UserLogin,
			&stream.UserName,
			&stream.Title,
			&stream.Language,
			&stream.ThumbnailURL,
			&stream.ViewerCount,
			&startedAtStr,
			&syncedAtStr,
		)
		if err != nil {
			return nil, err
		}

		stream.StartedAt, err = time.Parse(time.RFC3339, startedAtStr)
		if err != nil {
			return nil, err
		}

		stream.SyncedAt, err = time.Parse(time.RFC3339, syncedAtStr)
		if err != nil {
			return nil, err
		}

		streams = append(streams, &stream)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return streams, nil
}
