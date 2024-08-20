import { Message } from 'discord.js';
import { isModerator, msgGuard } from '../util';
import StreamSystem from '../stream';

function cmdPromiseWrap(message: Message, promise: Promise<any>) {
  return promise.catch((e) => {
    message.reply(`Error: ${e.message}`);
    return Promise.reject(e);
  });
}

async function commandTwitchBlacklist(message: Message, args: string[]) {
  if (args.length !== 1) {
    await message.reply('Usage: !twitch blacklist <channel>');
    return;
  }

  return cmdPromiseWrap(message, StreamSystem.blacklist(args[0])).then(() => {
    message.reply(`Blacklisted ${args[0]}`);
  });
}

async function commandTwitchUnblacklist(message: Message, args: string[]) {
  if (args.length !== 1) {
    await message.reply('Usage: !twitch unblacklist <channel>');
    return;
  }

  return cmdPromiseWrap(message, StreamSystem.unblacklist(args[0])).then(() => {
    message.reply(`Unblacklisted ${args[0]}`);
  });
}

export async function commandTwitch(message: Message, args: string[]) {
  /* Guard */
  if (!(await msgGuard(message, isModerator))) {
    return;
  }

  const subcommand = args[0];
  const subArgs = args.slice(1);

  switch (subcommand) {
  case 'blacklist':
    return commandTwitchBlacklist(message, subArgs);
  case 'unblacklist':
    return commandTwitchUnblacklist(message, subArgs);
  default:
    break;
  }

  await message.reply(`Unknown cmd subcommand: ${subcommand}`);
}
