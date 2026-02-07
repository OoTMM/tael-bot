defmodule TaelBot.Workers.TwitchSync do
  use TaelBot.Worker, interval: 60_000
  alias TaelBot.Util.TwitchGames
  alias TaelBot.Schemas.TwitchStream
  require Logger

  @impl true
  def run(_) do
    {:ok, streams} = fetch_streams()
    sync_streams(streams)
    :ok
  end

  defp fetch_streams(), do: fetch_streams(nil, [])
  defp fetch_streams(cursor, stack) do
    params = [
      type: "live",
      game_id: TwitchGames.zelda_oot(),
      game_id: TwitchGames.zelda_oot_mq(),
      game_id: TwitchGames.zelda_mm(),
      game_id: TwitchGames.retro(),
      game_id: TwitchGames.game_dev(),
      first: 100,
      after: cursor,
    ]

    case Twitch.streams(params) do
      {:ok, %{"data" => []}} ->
        {:ok, stack}
      {:ok, %{"data" => streams, "pagination" => pagination}} ->
        stack = stack ++ Enum.filter(streams, &combo_stream?/1)
        fetch_streams(pagination["cursor"], stack)
      {:error, reason} ->
        Logger.error("TwitchSync: Failed to fetch streams: #{inspect(reason)}")
        {:error, reason}
      _ ->
        Logger.error("TwitchSync: Unexpected response from Twitch API")
        {:error, :unexpected_response}
    end
  end

  defp sync_streams(streams) do
    Enum.uniq_by(streams, fn x -> x["id"] end)
    |> Enum.chunk_every(10)
    |> Enum.each(&sync_streams_chunk/1)
  end

  defp sync_streams_chunk(streams) do
    TaelBot.Repo.insert_all(TwitchStream, Enum.map(streams, &stream_attrs/1), on_conflict: {:replace_all_except, [:id]}, conflict_target: :stream_id)
  end

  defp stream_attrs(stream) do
    {:ok, started_at, _} = DateTime.from_iso8601(stream["started_at"])
    now = DateTime.utc_now()

    %{
      id: Ecto.UUID.generate(),
      stream_id: stream["id"],
      user_id: stream["user_id"],
      user_name: stream["user_name"],
      user_login: stream["user_login"],
      title: stream["title"],
      thumbnail_url: stream["thumbnail_url"],
      language: stream["language"],
      viewer_count: stream["viewer_count"],
      started_at: started_at,
      updated_at: now,
    }
  end

  defp combo_stream?(stream) do
    title = stream["title"]
    String.match?(title, ~r/\b(ootr?|zootr)(x|\+| )?mmr?\b/i) or (zelda_stream?(stream) and String.match?(title, ~r/\bcombo rando(mizer)?\b/i))
  end

  defp zelda_stream?(stream), do: stream["game_id"] in [TwitchGames.zelda_oot(), TwitchGames.zelda_oot_mq(), TwitchGames.zelda_mm()]
end
