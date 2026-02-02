import Config

config :tael_bot,
  ecto_repos: [TaelBot.Repo]

config :tael_bot, Discord,
  intents: 512
