package app

import (
	"context"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/OoTMM/tael-bot/app/streams"
)

func Run() {
	/* Configure logger */
	logger := slog.New(slog.NewJSONHandler(log.Writer(), nil))
	slog.SetDefault(logger)

	/* Create Ctrl-C context */
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	/* On first Ctrl-C, stop the context */
	go func() {
		<-ctx.Done()
		stop()
	}()

	var wg sync.WaitGroup
	wg.Go(func() { streams.Run(ctx) })
	slog.Info("app started")
	wg.Wait()
}
