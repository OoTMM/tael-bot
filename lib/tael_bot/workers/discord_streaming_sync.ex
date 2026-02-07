defmodule TaelBot.Workers.DiscordStreamingSync do
  use TaelBot.Worker, interval: 2_000
  require Logger
  alias TaelBot.Schemas.DiscordStreamingMessage
  import Ecto.Query, only: [from: 2]

  @impl true
  def init() do
    %{last_update: nil}
  end

  @impl true
  def run(%{last_update: last_update} = state) do
    now = DateTime.utc_now()
    process_all(now, last_update)
    {:update, %{state | last_update: now}}
  end

  defp updated?(nil), do: true
  defp updated?(last_update), do: TaelBot.Repo.exists?(from dsm in DiscordStreamingMessage, where: dsm.updated_at > ^last_update)

  defp process_all(now, last_update) do
    if updated?(last_update) do
      process(now, last_update)
    end
  end

  defp process(now, last_update, last_id \\ nil) do
    {:ok, dsm} = TaelBot.Repo.transact(fn ->
      q = from dsm in DiscordStreamingMessage,
        order_by: [asc: dsm.id],
        limit: 1

      q = if last_update, do: (from dsm in q, where: dsm.updated_at > ^last_update), else: q
      q = if last_id, do: (from dsm in q, where: dsm.id > ^last_id), else: q

      dsm = TaelBot.Repo.one(q)
      if dsm do
        process_message(now, dsm)
      end
      {:ok, dsm}
    end)
    if dsm do
      process(now, last_update, dsm.id)
    end
  end

  defp process_message(now, msg) do
    service = TaelBot.Util.StreamServices.get(msg.service)
    channel_id = TaelBot.DiscordStore.channel_id(service.channel)
    if channel_id do
      sync_message(now, msg, channel_id)
    end
  end

  defp sync_message(now, msg, channel_id) do
    data = Jason.decode!(msg.data)
    embed = embed_from_data(data)
    res = if msg.message_id do
      Nostrum.Api.Message.edit(channel_id, msg.message_id, embeds: [embed])
    else
      Nostrum.Api.Message.create(channel_id, embeds: [embed])
    end

    case res do
      {:ok, message} -> TaelBot.Repo.update_all((from dsm in DiscordStreamingMessage, where: dsm.id == ^msg.id), set: [message_id: message.id, updated_at: now])
      {:error, %{response: %{code: 10008}}} -> sync_message(now, %{msg | message_id: nil}, channel_id)
      {:error, _} -> Logger.error("DiscordStreamingSync: Failed to sync message #{msg.id}")
    end
  end

  defp embed_from_data(data) do
    embed = %Nostrum.Struct.Embed{}
    embed = if title = data["title"], do: Nostrum.Struct.Embed.put_title(embed, title), else: embed
    embed = if url = data["url"], do: Nostrum.Struct.Embed.put_url(embed, url), else: embed
    embed = if author = data["author"], do: Nostrum.Struct.Embed.put_author(embed, author["name"], author["url"], author["icon_url"]), else: embed
    embed = if image = data["image"], do: Nostrum.Struct.Embed.put_image(embed, image["url"]), else: embed
    embed = if footer = data["footer"], do: Nostrum.Struct.Embed.put_footer(embed, footer["text"], footer["icon_url"]), else: embed
    embed
  end
end
