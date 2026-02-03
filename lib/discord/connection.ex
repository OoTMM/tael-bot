defmodule Discord.Connection do
  use WebSockex
  require Logger

  def start_link(url, opts) do
    token = Keyword.fetch!(opts, :token)
    intents = Keyword.fetch!(opts, :intents)

    WebSockex.start_link(url, __MODULE__, %{
      token: token,
      intents: intents,
      heartbeat_interval: nil,
      heartbeat_timer: nil,
      heartbeat_ack_expected: false,
      last_sequence: nil,
      state: :disconnected
    })
  end

  @impl true
  def handle_connect(_conn, state) do
    {:ok, %{state | state: :wait_hello}}
  end

  @impl true
  def handle_disconnect(_, state) do
    {:ok, %{state | state: :disconnected}}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    data = Jason.decode!(msg)
    state = case data["s"] do
      nil -> state
      seq -> %{state | last_sequence: seq}
    end
    handle(data, state)
  end

  @impl true
  def handle_info(:close, state) do
    IO.puts("STOP IN WS")
    {:close, state}
  end

  @impl true
  def handle_info(:send_heartbeat, state), do: send_heartbeat(state)

  defp handle(%{"op" => 10, "d" => %{"heartbeat_interval" => heartbeat_interval}}, state) do
    state = %{state | heartbeat_interval: heartbeat_interval}
    heartbeat_delay = :rand.uniform(heartbeat_interval)
    {:ok, state} = schedule_heartbeat(state, heartbeat_delay)
    identify(state)
  end

  defp handle(%{"op" => 11}, state) do
    {:ok, %{state | heartbeat_ack_expected: false}}
  end

  defp handle(%{"op" => 1}, state) do
    send_heartbeat(state)
  end

  defp handle(msg, state) do
    Logger.debug("#{__MODULE__}: Received unhandled message: #{inspect(msg)}")
    {:ok, state}
  end

  defp schedule_heartbeat(state, delay) do
    timer = Process.send_after(self(), :send_heartbeat, delay)
    {:ok, %{state | heartbeat_timer: timer}}
  end

  defp send_heartbeat(state) do
    Process.cancel_timer(state.heartbeat_timer)
    state = %{state | heartbeat_ack_expected: true, heartbeat_timer: nil}
    {:ok, state} = schedule_heartbeat(state, state.heartbeat_interval)
    {:reply, {:text, serialize_heartbeat(state)}, state}
  end

  defp identify(state) do
    {:reply, {:text, serialize_event(2, %{
      token: state.token,
      properties: %{
        "os" => "linux",
        "browser" => "tael_bot",
        "device" => "tael_bot"
      },
      intents: state.intents
    })}, %{state | state: :identified}}
  end

  defp serialize_event(op, d), do: Jason.encode!(%{op: op, d: d})
  defp serialize_heartbeat(state), do: serialize_event(1, state.last_sequence)
end
