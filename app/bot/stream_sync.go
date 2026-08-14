package bot

import (
	"context"
	"log/slog"

	"github.com/OoTMM/tael-bot/app/store"
	"github.com/bwmarrin/discordgo"
)

type StreamSync struct {
	ctx       context.Context
	stores    *store.Stores
	discord   *discordgo.Session
	channelId string
}

func NewStreamSync(ctx context.Context, stores *store.Stores, discord *discordgo.Session) *StreamSync {
	return &StreamSync{
		ctx:     ctx,
		stores:  stores,
		discord: discord,
	}
}

func (s *StreamSync) Run() error {
	if s.channelId == "" {
		guilds := s.discord.State.Guilds
		if len(guilds) == 0 {
			slog.Warn("no guilds found in discord state")
			return nil
		}
		guild := guilds[0]
		for _, channel := range guild.Channels {
			if channel.Name == "streams-twitch" {
				s.channelId = channel.ID
				slog.Info("found channel 'streams-twitch'", "channel_id", s.channelId)
				break
			}
		}
		if s.channelId == "" {
			slog.Warn("no channel named 'streams-twitch' found in guild")
			return nil
		}
	}

	slog.Info("syncing streams to discord")
	return nil
}
