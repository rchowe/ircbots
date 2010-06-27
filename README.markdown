Simple IRC Bots
===============

Running the bots
----------------

These bots require the following things:
- Ruby
- SQLite 3 (rubygems required to install the library)

Ruby can be installed from the many packages available at http://www.ruby-lang.org/. If you are running a linux distribution with a package manager, you can install it from the command line. Be sure to also install rubygems so that you can grab the sqlite3 ruby library.

### Installing SQLite3 under Ubuntu 10.04
Installing sqlite3 under ubuntu can be fairly difficult. You can follow these steps (assuming you have ruby installed). This can be run as a shell script.

    #!/bin/sh
    sudo apt-get install libsqlite3 libsqlite3-ruby
    sudo gem install sqlite3

### Running the bots
These bots can be run by executing them. They should already have the execute flag set.

    ./carbon.rb

However, windows users will need to explicitly invoke the ruby interpreter.

	ruby carbon.rb

Creating a new bot
------------------

If you want to create a new bot, start by creating a new branch off of the IRC branch. This will give you a clean working environment with just the lastest IRC and IRCBot classes. Subcless the IRCBot class, and override the IRCBot#name and IRCBot#fullname methods. Then, override IRCBot#handle_server_msg method to respond to messages from the server.
