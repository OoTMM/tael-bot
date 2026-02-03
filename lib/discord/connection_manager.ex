defmodule Discord.ConnectionManager do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
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
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    Logger.error("Discord WebSocket died! Reason: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_continue(:connect, state), do: connect(state)

  defp fetch_gateway(state) do
    {:ok, res} = Tesla.get("https://discord.com/api/v10/gateway")
    body = Jason.decode!(res.body)
    url = body["url"]
    {:noreply, %{state | gateway_url: url}, {:continue, :connect}}
  end

  def connect(%{gateway_url: url, token: token, intents: intents} = state) do
    Logger.info("Manager PID: #{inspect(self())}")
    {:ok, socket} = Discord.Connection.start(url, token: token, intents: intents)
    Process.monitor(socket)
    {:noreply, %{state | socket: socket}}
  end

  @impl true
  def terminate(reason, state) do
    :ok
  end
end
