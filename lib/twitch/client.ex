defmodule Twitch.Client do
  defp middleware() do
    [
      {Tesla.Middleware.BaseUrl, "https://api.twitch.tv/helix"},
      {Tesla.Middleware.JSON, engine: Jason},
      {Tesla.Middleware.Headers, [{"Client-ID", Application.get_env(:tael_bot, Twitch)[:client_id]}]},
      Twitch.AuthMiddleware
    ]
  end

  def build(), do: Tesla.client(middleware())
end
