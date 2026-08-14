package main

import (
	"os"

	"github.com/OoTMM/tael-bot/app/app"
	"github.com/joho/godotenv"
)

func main() {
	/* Load env */
	env := os.Getenv("TAELBOT_ENV")
	if "" == env {
		env = "development"
	}

	godotenv.Load()
	godotenv.Load(".env." + env)
	if "test" != env {
		godotenv.Load(".env.local")
	}
	godotenv.Load(".env." + env + ".local")

	app.Run()
}
