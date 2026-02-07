defmodule TaelBot.Workers.TwitchConsumer do
  use TaelBot.Worker, interval: 1_000
  alias TaelBot.Schemas.TwitchStream
  import Ecto.Query, only: [from: 2]
  require Logger

  # This worker projects entries from twitch into discord.
  @impl true
  def init() do
    %{last_update: nil}
  end

  @impl true
  def run(%{last_update: last_update} = state) do
    process(last_update)
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    {:update, %{state | last_update: now}}
  end

  def process(last_update, last_id \\ nil) do
    q = from ts in TwitchStream,
      order_by: [asc: ts.id],
      limit: 10

    q = if last_update, do: (from ts in q, where: ts.updated_at > ^last_update), else: q
    q = if last_id, do: (from ts in q, where: ts.id > ^last_id), else: q

    streams = TaelBot.Repo.all(q)
    if length(streams) > 0 do
      update(streams)
      process(last_update, List.last(streams).id)
    end
  end

  def update(streams) do
    IO.inspect(streams, label: "TwitchConsumer: Updating streams")
  end
end
