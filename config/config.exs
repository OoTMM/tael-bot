import Config

# Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

config :tael_bot,
  ecto_repos: [TaelBot.Repo]

config :nostrum,
  ffmpeg: false,
  youtubedl: false,
  streamlink: false,
  gateway_intents: [
    :guilds,
    :guild_messages,
    :guild_message_reactions,
    :message_content,
  ]

config :tesla, adapter: Tesla.Adapter.Mint

config :tael_bot, TaelBot.Repo,
  default_transaction_mode: :immediate,
  journal_mode: :wal,
  busy_timeout: 10_000
