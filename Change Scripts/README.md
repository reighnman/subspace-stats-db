# Change Scripts

This folder contains the change scripts for each release. If you're running an old version of the database, these scripts can be used to migrate your existing database to a newer version.

The scripts are named by date and version # to make it easy to determine which script(s) to run and in what order. To ensure compatibilty, the major version # of the database, subspace-stats website, and Subspace Server .NET zone server and SS.Matchmaking module should match each other.

### Upgrade instructions:

1. Backup your subspace-stats database.
2. Backup your subspace-stats web server.
3. Backup your Subspace Server .NET zone server.
4. Stop the subspace-stats web server.
5. Shutdown the zone server.
6. Run the change scripts in the proper order (by date). For example, if you're running v1.0.0 then you want to run the scripts the come after the v1.0.0 script. You'll want to check each script's output and ensure there are no errors.
7. Upgrade your subspace-stats web server. Start the web server up and test that it functions properly.
8. Upgrade your Subspace Server .NET zone server / matchmaking module. Start the zone server up and test that it functions properly.

If you run into any issues you can investigate the issue or revert to your backups.
