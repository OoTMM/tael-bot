import Config
import Dotenvy

env_dir_prefix = Path.expand("./envs")

e = source!([
  Path.absname(".env", env_dir_prefix),
  Path.absname(".#{config_env()}.env", env_dir_prefix),
  Path.absname(".#{config_env()}.overrides.env", env_dir_prefix),
  System.get_env()
])

config :tael_bot, TaelBot.Repo,
  database: env!("DB_NAME", :string, "data/data.db"),
  pool_size: 10

config :tael_bot, Discord,
  token: env!("DISCORD_TOKEN", :string),
  intents: 512
