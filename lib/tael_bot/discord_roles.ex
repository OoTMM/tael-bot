defmodule TaelBot.DiscordRoles do
  def handle_event(:add, data) do
    role = lookup_role(data.guild_id, data.emoji.name)
    if role do
      Nostrum.Api.Guild.add_member_role(data.guild_id, data.user_id, role.role_id)
    end
  end

  def handle_event(:remove, data) do
    role = lookup_role(data.guild_id, data.emoji.name)
    if role do
      Nostrum.Api.Guild.remove_member_role(data.guild_id, data.user_id, role.role_id)
    end
  end

  defp lookup_role(guild_id, emoji) do
    TaelBot.Repo.get_by(TaelBot.Schemas.GuildRole, guild_id: guild_id, emoji: emoji)
  end
end
