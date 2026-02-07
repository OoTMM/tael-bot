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
    now = DateTime.utc_now()
    {:update, %{state | last_update: now}}
  end

  defp process(last_update, last_id \\ nil) do
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

  defp update(streams) do
    data = Enum.map(streams, &build/1)
    TaelBot.Repo.insert_all(TaelBot.Schemas.DiscordStreamingMessage, data, on_conflict: {:replace_all_except, [:id, :service, :service_id, :message_id]}, conflict_target: [:service, :service_id])
  end

  defp build(stream) do
    embed = build_embed(stream)
    %{
      service: "twitch",
      service_id: stream.id,
      data: Jason.encode!(embed),
      updated_at: DateTime.utc_now()
    }
  end

  defp build_embed(stream) do
    footer = "Viewers: #{stream.viewer_count} \u2022 Duration: #{duration_string(stream.started_at)} \u2022 Language: #{stream.language}"
    thumbnail_url = stream.thumbnail_url
    |> String.replace("{width}", "600")
    |> String.replace("{height}", "300")
    thumbnail_url = "#{thumbnail_url}&_t=#{DateTime.to_unix(DateTime.utc_now())}"
    url = "https://www.twitch.tv/#{stream.user_login}"

    %Nostrum.Struct.Embed{}
    |> Nostrum.Struct.Embed.put_title(stream.title)
    |> Nostrum.Struct.Embed.put_url(url)
    |> Nostrum.Struct.Embed.put_author(stream.user_name, url, nil)
    |> Nostrum.Struct.Embed.put_image(thumbnail_url)
    |> Nostrum.Struct.Embed.put_footer(footer)
  end

  defp duration_string(started_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, started_at)

    hours = div(diff, 3600)
    minutes = div(rem(diff, 3600), 60)
    seconds = rem(diff, 60)

    "#{hours}h #{minutes}m #{seconds}s"
  end
end
