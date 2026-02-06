defmodule Twitch.AuthMiddleware do
  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    perform(env, next, false)
  end

  defp perform(env, next, is_retry) do
    token = Twitch.TokenManager.get()
    env = Tesla.put_header(env, "Authorization", "Bearer #{token}")

    case Tesla.run(env, next) do
      {:ok, %{status: 401}} when not is_retry ->
        Twitch.TokenManager.invalidate()
        perform(env, next, true)
      res -> res
    end
  end
end
