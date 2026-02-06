defmodule TaelBot.DiscordConsumer do
  use Nostrum.Consumer
  require Logger

  @impl true
  def handle_event({:READY, _data, _ws_state}) do
    :ok
  end

  @impl true
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    content = msg.content
    if String.starts_with?(content, "!") do
      TaelBot.TaskSupervisor.start_child(fn -> TaelBot.Commands.Handlers.dispatch(msg) end)
    end
    :ok
  end

  @impl true
  def handle_event(event) do
    Logger.info("Received event: #{inspect(event)}")
    :ok
  end
end
