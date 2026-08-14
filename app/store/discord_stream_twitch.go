package store

import (
	"context"
	"database/sql"
)

type DiscordStreamTwitchStore struct {
	db *sql.DB
}

func NewDiscordStreamTwitchStore(db *sql.DB) *DiscordStreamTwitchStore {
	return &DiscordStreamTwitchStore{
		db: db,
	}
}

func (s *DiscordStreamTwitchStore) Upsert(ctx context.Context, id string, streamID string) error {
	const query = `
		INSERT INTO discord_streams_twitch (id, stream_id)
		VALUES (?, ?)
		ON CONFLICT (id) DO UPDATE SET
			stream_id = excluded.stream_id
	`

	_, err := s.db.ExecContext(ctx, query, id, streamID)
	return err
}

func (s *DiscordStreamTwitchStore) GetMessageID(ctx context.Context, streamID string) (string, error) {
	const query = `
		SELECT id FROM discord_streams_twitch WHERE stream_id = ?
	`

	var messageID string
	err := s.db.QueryRowContext(ctx, query, streamID).Scan(&messageID)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", nil
		}
		return "", err
	}

	return messageID, nil
}
