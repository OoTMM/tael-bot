package streams

import (
	"context"
	"log/slog"
	"os"
	"regexp"
	"time"

	twitch "github.com/adeithe/go-twitch/api"
)

const (
	TwitchGameOcarinaOfTime       = "11557"
	TwitchGameOcarinaOfTimeMQ     = "15849"
	TwitchGameMajorasMask         = "12482"
	TwitchGameRetro               = "27284"
	TwitchGameSoftwareDevelopment = "1469308723"
)

var regexOotmm *regexp.Regexp
var regexComboRando *regexp.Regexp

type TwitchWorker struct {
	ctx    context.Context
	cancel context.CancelFunc
	client *twitch.Client
}

func Run(ctx context.Context) {
	regexOotmm = regexp.MustCompile(`(?i)(?:^|[^a-z0-9])ootx?mm(?:[^a-z0-9]|$)`)
	regexComboRando = regexp.MustCompile(`(?i)(?:^|[^a-z0-9])combo rando(mizer)?(?:[^a-z0-9]|$)`)

	for ctx.Err() == nil {
		err := work(ctx)
		if err != nil && ctx.Err() == nil {
			slog.Error("twitch worker error", "error", err)
		}

		select {
		case <-time.After(5 * time.Second):
		case <-ctx.Done():
		}
	}
}

func work(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	clientId := os.Getenv("TWITCH_CLIENT_ID")
	clientSecret := os.Getenv("TWITCH_CLIENT_SECRET")

	auth := twitch.AppAccess(clientId, clientSecret)
	client := twitch.New(clientId, twitch.WithDefaultAuthorization(auth))

	worker := &TwitchWorker{
		ctx:    ctx,
		cancel: cancel,
		client: client,
	}

	slog.Info("twitch worker started")
	err := worker.run()
	slog.Info("twitch worker stopped")
	return err
}

func (w *TwitchWorker) run() error {
	err := w.tick()
	if err != nil {
		return err
	}

	ticker := time.NewTicker(1 * time.Minute)
	for {
		select {
		case <-ticker.C:
			err := w.tick()
			if err != nil {
				return err
			}
		case <-w.ctx.Done():
			return nil
		}
	}
}

func (w *TwitchWorker) tick() error {
	slog.Info("synchronizing twitch streams")
	streams, err := w.poll()
	if err != nil {
		return err
	}

	for _, stream := range streams {
		slog.Info("found stream", "user", stream.UserName, "title", stream.Title, "game_id", stream.GameID)
	}
	return nil
}

func isStreamValid(stream *twitch.Stream) bool {
	if regexOotmm.MatchString(stream.Title) {
		return true
	}

	if stream.GameID == TwitchGameRetro || stream.GameID == TwitchGameSoftwareDevelopment {
		return false
	}

	// DEBUG
	return true

	return regexComboRando.MatchString(stream.Title)
}

func (w *TwitchWorker) poll() ([]*twitch.Stream, error) {
	var cursor string
	data := make([]*twitch.Stream, 0, 100)

	req := w.client.Streams.List().GameID(TwitchGameOcarinaOfTime, TwitchGameOcarinaOfTimeMQ, TwitchGameMajorasMask, TwitchGameRetro, TwitchGameSoftwareDevelopment).First(100)
	for {
		streams, err := req.After(cursor).Do(w.ctx)
		if err != nil {
			return nil, err
		}

		if len(streams.Data) == 0 {
			break
		}

		for _, stream := range streams.Data {
			if !isStreamValid(&stream) {
				continue
			}
			data = append(data, &stream)
		}
		cursor = streams.Pagination.Cursor
	}

	return data, nil
}
