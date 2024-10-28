import { ChannelType, MessageCreateOptions as DiscordMessageCreateOptions, Message, MessageFlags, hyperlink } from 'discord.js';

import discordClient from './discord';
import db from './db';
import { getTwitchClient, TwitchStream, TwitchStreamsQuery } from './services/twitch';
import CONFIG from './config';

const GAME_IDS = {
  ZELDA_OOT: '11557',
  ZELDA_OOT_MQ: '15849',
  ZELDA_MM: '12482',
  RETRO: '27284',
  GAME_DEV: '1469308723',
}

function isComboStream(stream: TwitchStream) {
  const isGameZelda = stream.game_id === GAME_IDS.ZELDA_OOT || stream.game_id === GAME_IDS.ZELDA_OOT_MQ || stream.game_id === GAME_IDS.ZELDA_MM;

  if (stream.title.match(/\b(ootr?|zootr)(x|\+| )?mmr?\b/i)) {
    return true;
  }

  if (isGameZelda && stream.title.match(/\bcombo rando(mizer)?\b/i)) {
    return true;
  }

  return false;
}

function streamRawMessage(stream: TwitchStream): string {
  const url = `https://twitch.tv/${stream.user_login}`;
  const content = `${hyperlink(stream.user_name, url)} - ${stream.title}`;
  return content;
}

function streamNewMessage(stream: TwitchStream): DiscordMessageCreateOptions {
  const content = streamRawMessage(stream);
  const flags = MessageFlags.SuppressEmbeds | MessageFlags.SuppressNotifications;

  return { content, flags };
}

type StoredTwitchStream = {
  id: string;
  user_id: string;
  discord_message_id: string;
  user_name: string;
  title: string;
  created_at: Date;
  updated_at: Date;
}

class StreamSystem {
  private stopped: boolean;
  private timeoutHandle: NodeJS.Timeout | null;

  constructor() {
    this.stopped = false;
    this.timeoutHandle = null;
  }

  start() {
    this.tick();
  }

  stop() {
    this.stopped = true;
    if (this.timeoutHandle) {
      clearTimeout(this.timeoutHandle);
      this.timeoutHandle = null;
    }
  }

  private async tick() {
    try {
      await this.tickImpl();
    } catch (e) {
      console.error(e);
    } finally {
      if (!this.stopped) {
        this.timeoutHandle = setTimeout(() => this.tick(), 1000 * 60);
      }
    }
  }

  private async handleTwitchStreams(streams: TwitchStream[]) {
    if (streams.length === 0) return;

    const streamsMap = new Map(streams.map(x => [x.id, x]));
    const discordChannel = await discordClient.channels.fetch(CONFIG.discord.twitchChannel);
    if (!discordChannel) {
      console.error('Stream integration: Failed to fetch discord channel');
      return;
    }
    if (discordChannel.type !== ChannelType.GuildText) {
      console.error('Stream integration: Discord channel is not a text channel');
      return;
    }

    const updatePromises: Promise<void>[] = [];

    /* Start a transaction */
    await db.tx(async (tx) => {
      const txPromises: Promise<null>[] = [];

      /* Check which streams are banned */
      const bannedUserIds = await tx.manyOrNone<{ user_id: string }>('SELECT user_id FROM streams_twitch_blacklist WHERE user_id = ANY($1)', [streams.map(x => x.user_id)]);
      const bannedUserIdsSet = new Set(bannedUserIds.map(x => x.user_id));

      /* Check which streams already existed */
      const rawStoredExistingStreams = await tx.manyOrNone<StoredTwitchStream>('SELECT * FROM streams_twitch WHERE id = ANY($1) FOR UPDATE', [streams.map(x => x.id)]);
      const storedExistingStreamsMap = new Map(rawStoredExistingStreams.map(x => [x.id, x]));

      const newMessagePromises: Promise<{ id: string, discordMessageId: string }>[] = [];
      for (const s of streams) {
        if (bannedUserIdsSet.has(s.user_id)) {
          continue;
        }

        if (!storedExistingStreamsMap.has(s.id)) {
          /* New stream, need to post the message */
          const p = discordChannel.send(streamNewMessage(s));
          newMessagePromises.push(p.then((msg) => ({ id: s.id, discordMessageId: msg.id })));
        } else {
          /* Stream already exists */
          const storedStream = storedExistingStreamsMap.get(s.id)!;
          if (s.title === storedStream.title) {
            /* Nothing changed */
            txPromises.push(tx.none('UPDATE streams_twitch SET updated_at = NOW() WHERE id = $1', [s.id]));
            continue;
          }

          /* Update the message */
          updatePromises.push((async () => {
            const msg = await discordChannel.messages.fetch(storedStream.discord_message_id);
            if (msg) {
              await msg.edit(streamRawMessage(s));
            }
          })());

          /* Update the stored stream */
          txPromises.push(tx.none('UPDATE streams_twitch SET title = $1, updated_at = NOW() WHERE id = $2', [s.title, s.id]));
        }
      }

      /* Update the stored streams */
      const newMessages = await Promise.all(newMessagePromises);
      for (const nm of newMessages) {
        txPromises.push(tx.none('INSERT INTO streams_twitch (id, user_id, discord_message_id, user_name, title) VALUES ($1, $2, $3, $4, $5)', [nm.id, streamsMap.get(nm.id)!.user_id, nm.discordMessageId, streamsMap.get(nm.id)!.user_name, streamsMap.get(nm.id)!.title]));
      }

      await Promise.all(txPromises);
    });

    await Promise.all(updatePromises);
  }

  private async pollTwitch() {
    const data: TwitchStream[] = [];
    const seen = new Set<string>();
    const twitch = await getTwitchClient();
    let params: TwitchStreamsQuery = {
      type: 'live',
      game_id: [
        GAME_IDS.ZELDA_OOT,
        GAME_IDS.ZELDA_OOT_MQ,
        GAME_IDS.ZELDA_MM,
        GAME_IDS.RETRO,
        GAME_IDS.GAME_DEV,
      ],
      first: 100,
    }

    for (;;) {
      const streams = await twitch.streams(params);
      if (streams.data.length === 0) {
        break;
      }
      params.after = streams.pagination.cursor;

      for (const stream of streams.data) {
        if (seen.has(stream.id)) {
          continue;
        }
        if (isComboStream(stream)) {
          data.push(stream);
          seen.add(stream.id);
        }
      }
    }

    await this.handleTwitchStreams(data);
  }

  private async checkExpiredTwitch() {
    const channel = await discordClient.channels.fetch(CONFIG.discord.twitchChannel);
    if (!channel) {
      console.error('Stream integration: Failed to fetch discord channel');
      return;
    }
    if (channel.type !== ChannelType.GuildText) {
      console.error('Stream integration: Discord channel is not a text channel');
      return;
    }

    await db.tx(async (tx) => {
      const expired = await tx.manyOrNone<{ id: string, discord_message_id: string }>("SELECT id, discord_message_id FROM streams_twitch WHERE updated_at < (NOW() - '3 minutes'::interval) FOR UPDATE");
      await Promise.all(expired.map(async (ex) => {
        let discordMsg: Message | null;
        try {
          discordMsg = await channel.messages.fetch(ex.discord_message_id);
        } catch (e) {
          discordMsg = null;
        }

        if (discordMsg) {
          await discordMsg.delete();
        }

        await tx.none('DELETE FROM streams_twitch WHERE id = $1', [ex.id]);
      }));
    });
  }

  private async tickImpl() {
    await this.pollTwitch();
    await this.checkExpiredTwitch();
  }

  async blacklist(username: string) {
    /* Fetch the ID from twitch */
    const twitch = await getTwitchClient();
    const userQuery = await twitch.users({ login: username });
    const user = userQuery.data[0];
    if (!user) {
      throw new Error('User not found');
    }

    /* Ban */
    await db.none(`
      INSERT INTO streams_twitch_blacklist (user_id, user_login)
      VALUES ($1, $2)
      ON CONFLICT (user_id)
      DO UPDATE SET user_login = EXCLUDED.user_login
    `, [user.id, user.login]);

    /* Force expire */
    await db.none("UPDATE streams_twitch SET updated_at = (NOW() - '12 hours'::interval) WHERE user_id = $1", [user.id]);
    await this.checkExpiredTwitch();
  }

  async unblacklist(username: string) {
    await db.none('DELETE FROM streams_twitch_blacklist WHERE user_login = $1', [username]);
  }
}

const streamSystem = new StreamSystem();
export default streamSystem;
