import { Message } from 'discord.js';

import { commandCmd } from './commands/cmd';
import { commandList } from './commands/list';
import { commandCustom } from './commands/custom';
import { commandTwitch } from './commands/twitch';

async function handleCommand(message: Message) {
  const commandName = message.content.split(' ')[0].slice(1);
  switch (commandName) {
  case 'cmd':
    return commandCmd(message, message.content.split(' ').slice(1));
  case 'list':
    return commandList(message);
  case 'twitch':
    return commandTwitch(message, message.content.split(' ').slice(1));
  default:
    return commandCustom(message, commandName);
  }
}

export async function handleMessage(message: Message) {
  /* Detect commands */
  if (message.content[0] === '!') {
    return handleCommand(message);
  }
}
