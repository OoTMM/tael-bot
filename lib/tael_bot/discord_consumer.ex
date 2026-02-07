defmodule TaelBot.DiscordConsumer do
  use Nostrum.Consumer
  require Logger

  @impl true
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    content = msg.content
    if String.starts_with?(content, "!") do
      TaelBot.TaskSupervisor.start_child(fn -> TaelBot.Commands.Handlers.dispatch(msg) end)
    end
    TaelBot.DiscordStore.update({:MESSAGE_CREATE, msg})
  end

  @impl true
  def handle_event({type, data, _ws_state}) do
    TaelBot.DiscordStore.update({type, data})
  end
end
