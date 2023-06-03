import { Message } from 'discord.js';

import { msgGuard, isModerator } from '../util';
import db from '../db';

export async function commandCmdAdd(message: Message, args: string[]) {
  /* Check for moderator */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const name = args[0];
  const response = args.slice(1).join(' ');

  if (!name || !response) {
    await message.reply('Usage: !cmd add <name> <response>');
    return;
  }

  /* Add the command */
  await db.tx(async (conn) => {
    await conn.any('UPDATE commands SET active = false WHERE name = $1', [name]);
    await conn.any('INSERT INTO commands (name, value, active) VALUES ($1, $2, TRUE)', [name, response]);
  });

  await message.reply(`Added command ${name}`);
}

export async function commandCmd(message: Message, args: string[]) {
  const subcommand = args[0];
  const subArgs = args.slice(1);

  switch (subcommand) {
  case 'add':
    return commandCmdAdd(message, subArgs);
  default:
    break;
  }

  await message.reply(`Unknown cmd subcommand: ${subcommand}`);
}
