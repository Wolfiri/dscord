module state;

import std.functional,
       std.stdio;

import api.client,
       gateway.client,
       gateway.events,
       gateway.packets,
       types.base,
       types.user,
       types.guild,
       types.channel;

class State {
  // Client
  APIClient      api;
  GatewayClient  gw;

  // Storage
  User        me;
  GuildMap    guilds;
  ChannelMap  channels;

  private {
    ushort onReadyGuildCount;
  }

  // Callbacks
  void delegate()  onStartupComplete;

  this(APIClient api, GatewayClient gw) {
    this.api = api;
    this.gw = gw;

    this.guilds = new GuildMap((id) {
      return new Guild(this.api.guild(id));
    });

    // this.channels = new ChannelMap();

    this.bindEvents();
  }

  void bindEvents() {
    this.gw.onEvent!Ready(toDelegate(&this.onReady));
    this.gw.onEvent!GuildCreate(toDelegate(&this.onGuildCreate));
  }

  void onReady(Ready r) {
    this.me = r.me;

    this.onReadyGuildCount = cast(ushort)r.guilds.length;
    foreach (g; r.guilds) {
      this.guilds[g.id] = g;
    }
  }

  void onGuildCreate(GuildCreate c) {
    this.guilds[c.guild.id] = c.guild;
    if (!c.isNew) {
      this.onReadyGuildCount -= 1;

      if (this.onReadyGuildCount == 0 && this.onStartupComplete) {
        this.onStartupComplete();
      }
    }
  }

  Guild guild(Snowflake id) {
    return this.guilds[id];
  }
}


