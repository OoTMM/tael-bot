defmodule TaelBot.Worker do
  require Logger
  @optional_callbacks init: 0
  @callback init() :: any()
  @callback run(any()) :: {:update, any()} | :ok

  defmacro __using__(opts) do
    quote do
      use GenServer

      @behaviour TaelBot.Worker
      @worker_interval unquote(opts[:interval])

      def start_link(_) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      @impl true
      def init(), do: []

      @impl true
      def init(state), do: TaelBot.Worker.init(init())

      @impl true
      def handle_info(:work, state), do: TaelBot.Worker.run(__MODULE__, state, @worker_interval)

      defoverridable init: 0
    end
  end

  def init(state) do
    send(self(), :work)
    Logger.info("#{__MODULE__}: Worker started")
    {:ok, state}
  end

  def run(module, state, interval) do
    state = case module.run(state) do
      {:update, new_state} -> new_state
      _ -> state
    end
    Process.send_after(self(), :work, interval)
    {:noreply, state}
  end
end
