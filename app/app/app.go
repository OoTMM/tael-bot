package app

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/OoTMM/tael-bot/app/bot"
	"github.com/OoTMM/tael-bot/app/store"
	"github.com/OoTMM/tael-bot/app/streams"
	_ "modernc.org/sqlite"
)

func connectDB(ctx context.Context) (*sql.DB, error) {
	/* Connect to the database */
	dsn := os.Getenv("GOOSE_DBSTRING") + "?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)"
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to the database: %w", err)
	}

	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping the database: %w", err)
	}

	return db, nil
}

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

	/* Create the database connection */
	db, err := connectDB(ctx)
	if err != nil {
		slog.Error("failed to connect to the database", "error", err)
		return
	}
	defer db.Close()

	/* Create the stores */
	stores := store.NewStores(db)

	var wg sync.WaitGroup
	wg.Go(func() { bot.Run(ctx, stores) })
	wg.Go(func() { streams.Run(ctx, stores) })
	slog.Info("app started")
	wg.Wait()
}
