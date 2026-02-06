defmodule Twitch.TokenManager do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    state = %{
      token: nil,
      refresh_timer: nil,
      pids_waiting: []
    }
    {:ok, state}
  end

  def get(), do: GenServer.call(__MODULE__, :get, 30_000)
  def invalidate(), do: GenServer.cast(__MODULE__, :invalidate)

  @impl true
  def handle_call(:get, from, %{token: nil} = state) do
    schedule_refresh(state, 0)
    {:noreply, %{state | pids_waiting: [from | state.pids_waiting]}}
  end

  @impl true
  def handle_call(:get, _from, %{token: token} = state) do
    {:reply, token, state}
  end

  @impl true
  def handle_cast(:invalidate, %{token: nil} = state), do: {:noreply, state}

  @impl true
  def handle_cast(:invalidate, state) do
    state = %{state | token: nil}
    |> schedule_refresh(0)

    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    state = refresh_token(state)
    {:noreply, state}
  end

  defp refresh_token(state) do
    Logger.info("Twitch.TokenManager: Refreshing token")

    state = cancel_refresh(state)
    state = %{state | token: nil}
    env = Application.get_env(:tael_bot, Twitch)

    res = Tesla.post(client(), "/token", %{
      client_id: env[:client_id],
      client_secret: env[:client_secret],
      grant_type: "client_credentials"
    })

    case res do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        Logger.info("Twitch.TokenManager: New token acquired")
        pids = state.pids_waiting
        state = %{state | token: token, pids_waiting: []}
        Enum.each(pids, fn x -> GenServer.reply(x, token) end)
        state
      _ ->
        Logger.error("Twitch.TokenManager: Failed to refresh token (#{res.status})")
        schedule_refresh(state, 60_000)
    end
  end

  defp cancel_refresh(%{refresh_timer: nil} = state), do: state
  defp cancel_refresh(state) do
    Process.cancel_timer(state.refresh_timer)
    %{state | refresh_timer: nil}
  end

  defp schedule_refresh(state, delay) do
    state = cancel_refresh(state)
    %{state | refresh_timer: Process.send_after(self(), :refresh, delay)}
  end

  defp client() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://id.twitch.tv/oauth2"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.EncodeFormUrlencoded,
    ])
  end
end
