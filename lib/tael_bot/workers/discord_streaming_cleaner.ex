defmodule TaelBot.Workers.DiscordStreamingCleaner do
  use TaelBot.Worker, interval: 5_000
  require Logger
  alias TaelBot.Repo
  alias TaelBot.Schemas.DiscordStreamingMessage
  import Ecto.Query, only: [from: 2]

  def run(_) do
    mark_deleted()
    process()
    :ok
  end

  defp process(last_id \\ nil) do
    q = from dsm in DiscordStreamingMessage, where: dsm.pending_deletion == true, order_by: [asc: dsm.id], limit: 1
    q = if last_id, do: (from dsm in q, where: dsm.id > ^last_id), else: q

    msg = Repo.one(q)
    if msg do
      service = TaelBot.Util.StreamServices.get(msg.service)
      channel_id = TaelBot.DiscordStore.channel_id(service.channel)
      if channel_id do
        res = case Nostrum.Api.Message.delete(channel_id, msg.message_id) do
          {:ok} -> :ok
          {:error, %{response: %{code: 10008}}} -> :ok
          e -> e
        end

        case res do
          :ok ->
            Repo.delete(msg)
          {:error, e} ->
            Logger.error("DiscordStreamingCleaner: Failed to delete message #{msg.id} (#{inspect(e)})")
        end
      end
      process(msg.id)
    end
  end

  defp mark_deleted() do
    Enum.each(TaelBot.Util.StreamServices.all_services(), &mark_deleted/1)
  end

  defp mark_deleted(service) do
    service_data = TaelBot.Util.StreamServices.get(service)
    table = service_data.table

    q = from dsm in DiscordStreamingMessage,
      where: dsm.service == ^service and dsm.service_id not in subquery(from x in table, select: x.id) and dsm.pending_deletion == false

    Repo.update_all(q, set: [pending_deletion: true])
  end
end
