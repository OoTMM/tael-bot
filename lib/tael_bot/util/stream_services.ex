defmodule TaelBot.Util.StreamServices do
  @data %{
    "twitch" => %{
      table: "twitch_streams",
      channel: "streams-twitch",
    }
  }

  def get(service) do
    Map.get(@data, service)
  end

  def all_services() do
    Map.keys(@data)
  end
end
