server-setup
============

Setup/configure a new server by installing packages, creating databases, creating users, creating groups, and setting permissions

Features
--------

- Use a bash sourced config to supply template 
- Install yum packages
- Create a secure MySQL setup with root password
- Create MySQL databases and user with permissions
- Start Apache
- Import Sql dumps
- Move/extract files to the web root
- Create user groups
- Create users
- Set permissions on web files/directories
- Run custom bash commands

Workflow
--------

The basic workflow for setting up a new server with an existing site:

1. Tar and gzip the web files on the old server
2. Dump the database from the old server
3. Git clone server-setup on the new server
4. SCP the files/databases from the old server to the new server
5. Create a server-setup config file from the sample.cfg provided
6. Run ./setup.sh


