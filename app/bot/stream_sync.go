package bot

import (
	"context"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/OoTMM/tael-bot/app/domain"
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
	err := s.update()
	if err != nil {
		return err
	}

	return nil
}

func (s *StreamSync) update() error {
	/* Fetch all twitch streams */
	all, err := s.stores.StreamTwitch.GetAll(s.ctx)
	if err != nil {
		return err
	}

	for _, stream := range all {
		err = s.handleStream(stream)
		if err != nil {
			slog.Error("failed to send message for stream", "stream_id", stream.ID, "error", err)
		}
	}

	return nil
}

func (s *StreamSync) sendMessage(streamId string, embed *discordgo.MessageEmbed) error {
	msg, err := s.discord.ChannelMessageSendEmbed(s.channelId, embed)
	if err != nil {
		return err
	}

	slog.Info("sent new message", "message_id", msg.ID)
	s.stores.DiscordStreamTwitch.Upsert(context.Background(), msg.ID, streamId)
	return nil
}

func (s *StreamSync) updateMessage(streamId string, embed *discordgo.MessageEmbed, messageId string) error {
	_, err := s.discord.ChannelMessageEditEmbed(s.channelId, messageId, embed)
	if err != nil {
		restErr, ok := err.(*discordgo.RESTError)
		if ok && restErr.Response != nil && restErr.Response.StatusCode == 404 {
			/* Message not found, reset messageId to send a new message */
			slog.Warn("message not found, sending a new message", "message_id", messageId)
			return s.sendMessage(streamId, embed)
		}
		return err
	}
	return nil
}

func (s *StreamSync) handleStream(stream *domain.StreamTwitch) error {
	width := 1280
	height := 720

	imageUrl := stream.ThumbnailURL
	imageUrl = strings.ReplaceAll(imageUrl, "{width}", strconv.Itoa(width))
	imageUrl = strings.ReplaceAll(imageUrl, "{height}", strconv.Itoa(height))
	imageUrl = fmt.Sprintf("%s?_ts=%d", imageUrl, time.Now().UnixNano())

	duration := time.Since(stream.StartedAt)
	durationStr := fmt.Sprintf("%02d:%02d:%02d", int(duration.Hours()), int(duration.Minutes())%60, int(duration.Seconds())%60)

	embed := &discordgo.MessageEmbed{
		Type:        discordgo.EmbedTypeRich,
		Title:       stream.UserName,
		Description: stream.Title,
		URL:         "https://www.twitch.tv/" + stream.UserLogin,
		Color:       0x9146ff,
		Image: &discordgo.MessageEmbedImage{
			URL:    imageUrl,
			Width:  width,
			Height: height,
		},
		Footer: &discordgo.MessageEmbedFooter{
			Text: fmt.Sprintf("Viewers: %d • Language: %s • Duration: %s", stream.ViewerCount, stream.Language, durationStr),
		},
	}

	messageId, err := s.stores.DiscordStreamTwitch.GetMessageID(s.ctx, stream.ID)
	if err != nil {
		return err
	}

	if messageId == "" {
		return s.sendMessage(stream.ID, embed)
	} else {
		return s.updateMessage(stream.ID, embed, messageId)
	}
}
