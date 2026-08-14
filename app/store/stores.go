package store

import "database/sql"

type Stores struct {
	StreamTwitch        *StreamTwitchStore
	DiscordStreamTwitch *DiscordStreamTwitchStore
}

func NewStores(db *sql.DB) *Stores {
	return &Stores{
		StreamTwitch:        NewStreamTwitchStore(db),
		DiscordStreamTwitch: NewDiscordStreamTwitchStore(db),
	}
}
