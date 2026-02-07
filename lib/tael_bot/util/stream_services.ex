defmodule TaelBot.Util.StreamServices do
  @data %{
    "twitch" => %{
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
