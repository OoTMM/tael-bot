defmodule TaelBot.Tasks.TwitchSync do
  alias TaelBot.Util.TwitchGames
  require Logger

  def run() do
    {:ok, streams} = fetch_streams()
    IO.inspect(streams, label: "Fetched Twitch streams")
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

  defp combo_stream?(stream) do
    title = stream["title"]
    String.match?(title, ~r/\b(ootr?|zootr)(x|\+| )?mmr?\b/i) or (zelda_stream?(stream) and String.match?(title, ~r/\bcombo rando(mizer)?\b/i))
  end

  defp zelda_stream?(stream), do: stream["game_id"] in [TwitchGames.zelda_oot(), TwitchGames.zelda_oot_mq(), TwitchGames.zelda_mm()]
end
