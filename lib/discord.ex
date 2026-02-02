defmodule Discord do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [Application.get_env(:tael_bot, __MODULE__, [])]}
    }
  end

  @impl true
  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    intents = Keyword.fetch!(opts, :intents)

    children = [
      {Discord.ConnectionManager, token: token, intents: intents},
      #{DynamicSupervisor, strategy: :one_for_one, name: Discord.DynamicSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
