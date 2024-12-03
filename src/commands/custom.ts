import { Message } from 'discord.js';

import { db } from '../db';

export async function commandCustom(message: Message, cmd: string) {
  /* Fetch the custom command */
  const value = await db.oneOrNone<string>('SELECT value FROM commands WHERE name = $1 LIMIT 1', [cmd], x => x?.value);

  if (!value) {
    await message.reply(`Unknown command: ${cmd}`);
    return;
  }

  const channel = message.channel!;
  if (channel.isSendable()) {
    await channel.send(value);
  }
}
