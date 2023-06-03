import 'dotenv/config';

import { Client } from 'discord.js';

import { handleMessage } from './message';

const client = new Client({
  intents: [
    'Guilds',
    'GuildMessages',
    'MessageContent',
  ]
});

client.on('ready', (c) => {
  console.log(`Logged in as ${c.user?.tag}!`);
});

client.on('messageCreate', handleMessage);

client.login(process.env.DISCORD_TOKEN);
