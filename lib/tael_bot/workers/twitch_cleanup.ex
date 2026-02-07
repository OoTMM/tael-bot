defmodule TaelBot.Workers.TwitchCleanup do
  use TaelBot.Worker, interval: 15_000
  import Ecto.Query, only: [from: 2]
  alias TaelBot.Schemas.TwitchStream

  @impl true
  def run(_) do
    cutoff = DateTime.utc_now() |> DateTime.add(-3, :minute)
    TaelBot.Repo.delete_all(from ts in TwitchStream, where: ts.updated_at < ^cutoff)
    :ok
  end
end
