import Config

config :tael_bot,
  ecto_repos: [TaelBot.Repo]

config :nostrum,
  log_level: :warn,
  ffmpeg: false,
  youtubedl: false,
  streamlink: false,
  gateway_intents: [
    :guilds,
    :guild_messages,
    :message_content,
  ]

config :tesla, adapter: Tesla.Adapter.Mint

config :tael_bot, TaelBot.Repo,
  default_transaction_mode: :immediate,
  journal_mode: :wal
