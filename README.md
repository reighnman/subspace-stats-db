# subspace-stats-db

A database for storing stats for use with the SS.Matchmaking modules included in the [Subspace Server .NET](https://github.com/gigamon-dev/SubspaceServer) zone server.

## Installation

Install [PostgreSQL](https://www.postgresql.org).

Download the latest release of `subspace-stats-db`. This is a tar file that you will use to "restore".

> NOTE: This is a work in progress. A release will be made available in the future.

Create a new database and use the tar file to "restore" into the database.

> TODO: Add detailed instruction on how to create the database and perform the restore.

Create logins: 
- One for the zone server to use. Assign the `ss_zone_server` role to the login name.

```SQL
GRANT ss_zone_server TO <zone server login name>;
```

- One for the website to use. Assign the `ss_web_server` role to the login name.

```SQL
GRANT ss_web_server TO <web server login name>;
```

## Configure the SS.Matchmaking modules

1. Fill in the connection string in `conf/global.conf` using the login for the zone server that was created in an earlier step.

```INI
[SS.Matchmaking]
DatabaseConnectionString = 
```

2. Configure `conf/Modules.config` to load the matchmaking modules. Be sure to include the `SS.Matchmaking.Modules.PostgreSqlGameStats` module.

```XML
<module type="SS.Matchmaking.Modules.PlayerGroups" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.MatchmakingQueues" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.PostgreSqlGameStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.OneVersusOneMatch" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.OneVersusOneStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.TeamVersusStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll" />
<module type="SS.Matchmaking.Modules.TeamVersusMatch" path="bin/modules/Matchmaking/SS.Matchmaking.dll" />
```

## Configure the subspace-stats-web website

Follow the instructions for the website and use the login name created earlier for the website in the connection string.

> NOTE: This is a work in progress. The website will be made available in another repository.
