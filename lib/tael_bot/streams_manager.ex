defmodule TaelBot.StreamsManager do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    send(self(), :perform)
    {:ok, nil}
  end

  @impl true
  def handle_info(:perform, state) do
    TaelBot.Tasks.TwitchSync.run()
    perform_cleanup()
    Process.send_after(self(), :perform, 60_000)
    {:noreply, state}
  end

  defp perform_cleanup() do

  end
end
