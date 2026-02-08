defmodule TaelBot.DiscordStore do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(_) do
    :ets.new(__MODULE__, [:named_table, :public, :set, read_concurrency: true])
    :ets.new(__MODULE__.Channels, [:named_table, :public, :set, read_concurrency: true])
    :ets.new(__MODULE__.Guilds, [:named_table, :public, :set, read_concurrency: true])
    send(self(), :reload_guilds)
    {:ok, nil}
  end

  def guild(id) do
    case :ets.lookup(__MODULE__.Guilds, id) do
      [{_, guild}] -> guild
      [] -> nil
    end
  end

  def guild_id() do
    case :ets.lookup(__MODULE__, :guild) do
      [{:guild, id}] -> id
      [] -> nil
    end
  end

  def channel_id(name) do
    case :ets.lookup(__MODULE__.Channels, name) do
      [{_, id}] -> id
      [] -> nil
    end
  end

  def update({:GUILD_AVAILABLE, data}) do
    set_guild(data.id)
    Enum.each(data.channels, fn {_, channel} ->
      set_channel(channel.name, channel.id)
    end)
  end

  def update({:CHANNEL_CREATE, data}) do
    set_channel(data.name, data.id)
  end

  def update({:CHANNEL_UPDATE, {old, new}}) do
    delete_channel(old.name)
    set_channel(new.name, new.id)
  end

  def update({:CHANNEL_DELETE, channel}) do
    delete_channel(channel.name)
  end

  def update(_msg) do
    :ok
  end

  defp set_guild(id) do
    :ets.insert(__MODULE__, {:guild, id})
  end

  defp set_channel(name, id) do
    :ets.insert(__MODULE__.Channels, {name, id})
  end

  defp delete_channel(name) do
    :ets.delete(__MODULE__.Channels, name)
  end

  @impl true
  def handle_info(:reload_guilds, state) do
    guilds = TaelBot.Repo.all(TaelBot.Schemas.Guild)
    Enum.each(guilds, fn g -> :ets.insert(__MODULE__.Guilds, {g.id, %{id: g.id, role_channel_id: g.role_channel_id, role_message_id: g.role_message_id}}) end)
    Process.send_after(self(), :reload_guilds, 60_000)
    {:noreply, state}
  end
end
