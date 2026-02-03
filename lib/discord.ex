defmodule Discord do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def child_spec(_) do
    opts = Application.get_env(:tael_bot, Discord)

    %{
      id: Discord.ConnectionManager,
      start: {__MODULE__, :start_link, [opts]},
    }
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    token = Keyword.fetch!(opts, :token)
    intents = Keyword.fetch!(opts, :intents)
    Process.send_after(self(), :fetch_gateway, 0)
    {:ok, %{token: token, intents: intents, socket: nil, gateway_url: nil}}
  end

  @impl true
  def handle_info(:fetch_gateway, state), do: fetch_gateway(state)

  @impl true
  def handle_info({:EXIT, pid, reason}, state) do
    if state.socket == pid do
      Logger.error("Discord connection exited! Reason: #{inspect(reason)}")
      Process.send_after(self(), :connect, 5_000)
      {:noreply, %{state | socket: nil}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    Logger.error("Discord WebSocket died! Reason: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:connect, state), do: connect(state)

  @impl true
  def handle_continue(:connect, state), do: connect(state)

  defp fetch_gateway(state) do
    {:ok, res} = Tesla.get("https://discord.com/api/v10/gateway")
    body = Jason.decode!(res.body)
    url = body["url"]
    {:noreply, %{state | gateway_url: url}, {:continue, :connect}}
  end

  def connect(%{gateway_url: url, token: token, intents: intents} = state) do
    {:ok, socket} = Discord.Connection.start_link(url, token: token, intents: intents)
    {:noreply, %{state | socket: socket}}
  end

  @impl true
  def terminate(_reason, state) do
    IO.puts("STOP")
    if is_pid(state.socket) do
      send(state.socket, :close)
    end
    :ok
  end
end
