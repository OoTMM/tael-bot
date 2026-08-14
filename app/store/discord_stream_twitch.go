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

func (s *DiscordStreamTwitchStore) Delete(ctx context.Context, id string) error {
	const query = `
		DELETE FROM discord_streams_twitch WHERE id = ?
	`

	_, err := s.db.ExecContext(ctx, query, id)
	return err
}

func (s *DiscordStreamTwitchStore) GetOrphaned(ctx context.Context) ([]string, error) {
	const query = `
		SELECT id FROM discord_streams_twitch
		WHERE stream_id NOT IN (SELECT id FROM streams_twitch)
	`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return ids, nil
}
