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
  def handle_event({:MESSAGE_REACTION_ADD, data, _ws_state}), do: reaction_event(:add, data)

  @impl true
  def handle_event({:MESSAGE_REACTION_REMOVE, data, _ws_state}), do: reaction_event(:remove, data)

  @impl true
  def handle_event({type, data, _ws_state}) do
    TaelBot.DiscordStore.update({type, data})
  end

  defp reaction_event(type, data) do
    guild = TaelBot.DiscordStore.guild(data.guild_id)
    if guild && guild.role_message_id == data.message_id do
      TaelBot.TaskSupervisor.start_child(fn -> TaelBot.DiscordRoles.handle_event(type, data) end)
    end
  end
end
