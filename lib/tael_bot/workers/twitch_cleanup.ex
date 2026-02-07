defmodule TaelBot.Workers.TwitchCleanup do
  use TaelBot.Worker, interval: 60_000
  import Ecto.Query, only: [from: 2]
  alias TaelBot.Schemas.TwitchStream

  @impl true
  def run() do
    cutoff = DateTime.utc_now() |> DateTime.add(-10, :second)
    TaelBot.Repo.delete_all(from ts in TwitchStream, where: ts.updated_at < ^cutoff)
    :ok
  end
end
