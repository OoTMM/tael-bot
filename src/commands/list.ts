import { Message } from 'discord.js';

import db from '../db';

export async function commandList(message: Message) {
  /* Get the list of custom commands */
  const result = await db.any('SELECT name FROM commands ORDER BY name', []);
  const names = result.map((row) => row.name);
  const channel = message.channel!;

  /* Send the list */
  await channel.send(`Available commands:\n\n${names.join(', ')}`);
}
