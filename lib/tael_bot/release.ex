defmodule TaelBot.Release do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    for repo <- repos() do
      {:ok, _pid} = repo.start_link()
      Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
    end
  end

  defp repos do
    Application.fetch_env!(:tael_bot, :ecto_repos)
  end

  defp migrations_path(repo) do
    # Path to compiled release migrations
    priv_dir = repo.config()[:priv] || "priv"
    Path.join([priv_dir, "repo", "migrations"])
  end
end
