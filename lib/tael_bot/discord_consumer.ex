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
    IO.inspect(msg)
    if String.starts_with?(content, "!") do
      {:ok, guild} = Nostrum.Cache.GuildCache.get(msg.guild_id)
      role_names = Enum.map(msg.member.roles, fn role_id -> guild.roles[role_id].name end)
      role = cond do
        "Admin" in role_names -> :admin
        "Moderator" in role_names -> :moderator
        true -> :user
      end

      TaelBot.TaskSupervisor.start_child(fn -> TaelBot.Commands.Handlers.dispatch(msg.content, %{user_id: msg.author.id, id: msg.id, role: role}) end)
    end
    :ok
  end

  @impl true
  def handle_event(event) do
    Logger.info("Received event: #{inspect(event)}")
    :ok
  end
end
