defmodule TaelBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Twitch,
      TaelBot.TaskSupervisor,
      TaelBot.Repo,
      TaelBot.DiscordConsumer,
      TaelBot.StreamsManager,
      #TaelBot.Workers.TwitchSync,
      TaelBot.Workers.TwitchCleanup,
    ]

    opts = [strategy: :one_for_one, name: TaelBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
