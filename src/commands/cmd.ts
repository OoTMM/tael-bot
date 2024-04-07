import { Message } from 'discord.js';
import { errors } from 'pg-promise';

import { msgGuard, isModerator } from '../util';
import db from '../db';

function validateCmdName(name: string): string | null {
  if (!name) return null;
  if (name.length > 64) return null;
  if (!/^[a-zA-Z0-9_]+$/.test(name)) return null;
  return name.toLowerCase();
}

export async function commandCmdAdd(message: Message, args: string[]) {
  /* Check for moderator */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const name = validateCmdName(args[0]);
  const response = args.slice(1).join(' ');

  if (!name || !response) {
    await message.reply('Usage: !cmd add <name> <response>');
    return;
  }

  /* Add the command */
  try {
    await db.any('INSERT INTO commands (name, value) VALUES ($1, $2)', [name, response]);
  } catch (e: any) {
    if (e.code === '23505') {
      await message.reply(`Command ${name} already exists`);
      return;
    } else {
      throw e;
    }
  }

  await message.reply(`Added command ${name}`);
}

export async function commandCmdEdit(message: Message, args: string[]) {
  /* Check for moderator */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const name = validateCmdName(args[0]);
  const response = args.slice(1).join(' ');

  if (!name || !response) {
    await message.reply('Usage: !cmd edit <name> <response>');
    return;
  }

  /* Edit the command */
  await db.tx(async (conn) => {
    await conn.none('INSERT INTO commands_history (name, value) SELECT name, value FROM commands WHERE name = $1', [name]);
    await conn.none('UPDATE commands SET value = $2, updated_at = NOW() WHERE name = $1', [name, response]);
  });

  await message.reply(`Edited command ${name}`);
}

export async function commandCmdDelete(message: Message, args: string[]) {
  /* Check for moderator */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const name = validateCmdName(args[0]);

  if (!name) {
    await message.reply('Usage: !cmd delete <name>');
    return;
  }

  /* Delete the command */
  await db.tx(async (conn) => {
    await conn.none('INSERT INTO commands_history (name, value) SELECT name, value FROM commands WHERE name = $1', [name]);
    await conn.none('DELETE FROM commands WHERE name = $1', [name]);
  });

  await message.reply(`Deleted command ${name}`);
}

export async function commandCmdRename(message: Message, args: string[]) {
  /* Check for moderator */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const nameOld = validateCmdName(args[0]);
  const nameNew = validateCmdName(args[1]);

  if (!nameOld || !nameNew) {
    await message.reply('Usage: !cmd rename <old> <new>');
    return;
  }

  /* Rename the command */
  await db.none('UPDATE commands SET name = $2, updated_at = NOW() WHERE name = $1', [nameOld, nameNew]);

  await message.reply(`Renamed command ${nameOld} into ${nameNew}`);
}

export async function commandCmd(message: Message, args: string[]) {
  const subcommand = args[0];
  const subArgs = args.slice(1);

  switch (subcommand) {
  case 'add':
    return commandCmdAdd(message, subArgs);
  case 'edit':
    return commandCmdEdit(message, subArgs);
  case 'delete':
    return commandCmdDelete(message, subArgs);
  case 'rename':
    return commandCmdRename(message, subArgs);
  default:
    break;
  }

  await message.reply(`Unknown cmd subcommand: ${subcommand}`);
}
