import { GuildMember, Message } from 'discord.js';

const ROLE_ADMIN = 'Admin';
const ROLE_MODERATOR = 'Moderator';

function hasRole(member: GuildMember, roles: string[]) {
  const r = member.roles.cache.map(x => x.name);
  return roles.some((role) => r.includes(role));
}

export function isAdmin(member: GuildMember) {
  return hasRole(member, [ROLE_ADMIN]);
}

export function isModerator(member: GuildMember) {
  return hasRole(member, [ROLE_ADMIN, ROLE_MODERATOR]);
}

export async function msgGuard(message: Message, guard: (m: GuildMember) => boolean) {
  if (!guard(message.member!)) {
    await message.reply('You do not have permission to use this command');
    return false;
  }
  return true;
}
