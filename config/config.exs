import Config

config :tael_bot,
  ecto_repos: [TaelBot.Repo]

config :nostrum,
  ffmpeg: false,
  youtubedl: false,
  streamlink: false,
  gateway_intents: [
    :guilds,
    :guild_messages,
    :message_content,
  ]
