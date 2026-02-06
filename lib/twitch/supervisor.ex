defmodule Twitch.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      Twitch.TokenManager,
      Twitch.Client
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
