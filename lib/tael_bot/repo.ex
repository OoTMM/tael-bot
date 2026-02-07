defmodule TaelBot.Repo do
  use Ecto.Repo,
    otp_app: :tael_bot,
    adapter: Ecto.Adapters.SQLite3
end
