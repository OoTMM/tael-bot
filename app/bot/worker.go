package bot

import (
	"context"
	"log/slog"
	"os"
	"sync"
	"time"

	"github.com/OoTMM/tael-bot/app/store"
	"github.com/bwmarrin/discordgo"
)

type Worker struct {
	ctx     context.Context
	cancel  context.CancelFunc
	stores  *store.Stores
	discord *discordgo.Session
}

func Run(ctx context.Context, stores *store.Stores) {
	for ctx.Err() == nil {
		err := work(ctx, stores)
		if err != nil && ctx.Err() == nil {
			slog.Error("bot worker error", "error", err)
		}

		select {
		case <-time.After(5 * time.Second):
		case <-ctx.Done():
		}
	}
}

func work(ctx context.Context, store *store.Stores) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	discordToken := os.Getenv("DISCORD_TOKEN")
	discord, err := discordgo.New("Bot " + discordToken)
	if err != nil {
		return err
	}

	worker := &Worker{
		ctx:     ctx,
		cancel:  cancel,
		stores:  store,
		discord: discord,
	}

	ready := make(chan struct{})
	var once sync.Once
	discord.AddHandler(func(s *discordgo.Session, gc *discordgo.GuildCreate) {
		once.Do(func() { close(ready) })
	})

	if err := discord.Open(); err != nil {
		return err
	}
	defer discord.Close()

	select {
	case <-ready:
	case <-ctx.Done():
		return nil
	}

	slog.Info("bot worker started")
	err = worker.run()
	slog.Info("bot worker stopped")
	return err
}

func (w *Worker) run() error {
	var wg sync.WaitGroup
	wg.Go(w.syncStreams)
	<-w.ctx.Done()
	wg.Wait()
	return nil
}

func (w *Worker) syncStreams() {
	streamSync := NewStreamSync(w.ctx, w.stores, w.discord)

	for w.ctx.Err() == nil {
		err := streamSync.Run()
		if err != nil && w.ctx.Err() == nil {
			slog.Error("stream sync error", "error", err)
		}

		select {
		case <-time.After(1 * time.Minute):
		case <-w.ctx.Done():
		}
	}
}
