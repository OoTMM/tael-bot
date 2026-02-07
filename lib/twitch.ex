defmodule Twitch do
  def child_spec(_) do
    %{
      id: Twitch,
      start: {Twitch.TokenManager, :start_link, []}
    }
  end

  defp client(), do: Twitch.Client.build()

  def streams(opts \\ []) do
    case Tesla.get(client(), "/streams", query: opts) do
      {:ok, %{body: body}} -> {:ok, body}
      res -> res
    end
  end
end
