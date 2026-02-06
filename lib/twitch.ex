defmodule Twitch do
  def child_spec(_) do
    %{
      id: Twitch,
      start: {Twitch.Supervisor, :start_link, []}
    }
  end
end
