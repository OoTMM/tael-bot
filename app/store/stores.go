package store

import "database/sql"

type Stores struct {
	StreamTwitch *StreamTwitchStore
}

func NewStores(db *sql.DB) *Stores {
	return &Stores{
		StreamTwitch: NewStreamTwitchStore(db),
	}
}
