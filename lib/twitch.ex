defmodule Twitch do
  def child_spec(_) do
    %{
      id: Twitch,
      start: {Twitch.TokenManager, :start_link, []}
    }
  end

  defp client(), do: Twitch.Client.build()

  def streams(opts \\ []) do
    Tesla.get(client(), "/streams", query: opts)
  end
end
