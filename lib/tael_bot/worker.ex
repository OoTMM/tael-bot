defmodule TaelBot.Worker do
  @callback run() :: any()

  defmacro __using__(opts) do
    quote do
      use GenServer

      @behaviour TaelBot.Worker
      @worker_interval unquote(opts[:interval])

      def start_link(_) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      @impl true
      def init(_) do
        jitter = :rand.uniform(@worker_interval)
        Process.send_after(self(), :work, jitter)
        {:ok, nil}
      end

      @impl true
      def handle_info(:work, state) do
        run()
        Process.send_after(self(), :work, @worker_interval)
        {:noreply, state}
      end
    end
  end
end
