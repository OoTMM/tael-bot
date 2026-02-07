defmodule TaelBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TaelBot.DiscordStore,
      Twitch,
      TaelBot.TaskSupervisor,
      TaelBot.Repo,
      TaelBot.DiscordConsumer,
      TaelBot.Workers.TwitchSync,
      TaelBot.Workers.TwitchCleanup,
      TaelBot.Workers.TwitchConsumer,
      TaelBot.Workers.DiscordStreamingSync,
    ]

    opts = [strategy: :one_for_one, name: TaelBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
