package bot

import (
	"context"
	"log/slog"

	"github.com/OoTMM/tael-bot/app/store"
	"github.com/bwmarrin/discordgo"
)

type StreamSync struct {
	ctx     context.Context
	stores  *store.Stores
	discord *discordgo.Session
}

func NewStreamSync(ctx context.Context, stores *store.Stores, discord *discordgo.Session) *StreamSync {
	return &StreamSync{
		ctx:     ctx,
		stores:  stores,
		discord: discord,
	}
}

func (s *StreamSync) Run() error {
	slog.Info("syncing streams to discord")
	return nil
}
