redmine_gitolite
================

CURRENT HEAD VERSION WORKS WITH TRUNK REDMINE (certified with 2.2.3)

THIS PLUGIN IS COMPATIBLE WITH REDMINE 2.X ONLY !

It combines `redmine-gitolite`__ with `redmine_git_hosting`__

A Redmine plugin which manages your Gitolite configuration based on your projects and user memberships in Redmine.

__ https://github.com/ivyl/redmine-gitolite
__ https://github.com/ericpaulbishop/redmine_git_hosting


Gems
----
* net-ssh
* lockfile
* `gitolite`__ (works with 1.1.0)

__ https://github.com/wingrunr21/gitolite

Other
-----
* Gitolite server (works with v2.3.1 and v3.3)
* accessible Git executable (works with 1.7.2.5)
* curl

Setup
-----

1. Install Redmine and put this plugin in ``redmine/plugins`` directory and migrate database

.. code:: ruby

    $ cd redmine/plugins
    $ git clone git://github.com/jbox-web/redmine_gitolite.git
    $ cd ..
    $ RAILS_ENV=production rake db:migrate_plugins


2. Create SSH Keys for user running Redmine

.. code:: ruby

    $ sudo su - redmine
    $ mkdir .ssh
    $ ssh-keygen -N '' -f ~/.ssh/redmine_gitolite_admin_id_rsa


3. User running Redmine must have RW+ access to gitolite-admin (assuming that you have Gitolite installed).

Otherwise you can install Gitolite (v3) by following this :

.. code:: ruby

    Server requirements:

      * any unix system
      * sh
      * git 1.6.6+
      * perl 5.8.8+
      * openssh 5.0+
      * a dedicated userid to host the repos (in this document, we assume it
        is 'git'), with shell access ONLY by 'su - git' from some other userid
        on the same server.

    Steps to install:

      * login as 'git' as described above

      * make sure ~/.ssh/authorized_keys is empty or non-existent

      * make sure Redmine SSH public key is available at $HOME/redmine_gitolite_admin_id_rsa.pub

      * add this in ~/.profile

            # set PATH so it includes user private bin if it exists
            if [ -d "$HOME/bin" ] ; then
              PATH="$PATH:$HOME/bin"
            fi

      * run the following commands:

            mkdir $HOME/bin
            source $HOME/.profile
            git clone git://github.com/sitaramc/gitolite
            gitolite/install -to $HOME/bin
            gitolite setup -pk redmine_gitolite_admin_id_rsa.pub


4. Configure sudoers file

.. code:: ruby

  $ visudo
  Add these lines (don't forget to replace user names)

  <redmine user>   ALL=(<git user>)      NOPASSWD:ALL
  <git user>       ALL=(<redmine user>)  NOPASSWD:ALL


Sometimes, the requiretty sudo setting can prevent the plugin from working correctly. Several users have reported this problem on CentOS. Check the Defaults directive in the sudoers file to see if this setting has been set.
You address the problem by either removing requiretty from the Defaults directive, or by adding the following lines below the original Defaults directive to remove this requirement for only the two necessary users:

.. code:: ruby

  Defaults:<git user>      !requiretty
  Defaults:<redmine user>  !requiretty


5. Make sure that Redmine user has Gitolite server in his known_hosts list (This is also a good check to see if Gitolite works)

.. code:: ruby

  $ sudo su - redmine
  $ ssh git@localhost
  * [accept key]

You should get something like that :

.. code:: ruby

    hello redmine_gitolite_admin_id_rsa, this is gitolite v2.3.1-0-g912a8bd-dt running on git 1.7.2.5
    the gitolite config gives you the following access:
        R   W  gitolite-admin
        @R_ @W_ testing

Or

.. code:: ruby

    hello redmine_gitolite_admin_id_rsa, this is git@dev running gitolite3 v3.3-11-ga1aba93 on git 1.7.2.5
        R W  gitolite-admin
        R W  testing


6. Configure email and name of Gitolite user for your Redmine account

.. code:: ruby

    $ sudo su - redmine
    $ git config --global user.email "redmine@gitolite.org"
    $ git config --global user.name "Redmine Gitolite"


7. Add post-receive hook to common Gitolite hooks (script is in contrib dir) and configure it (Redmine Host and API key)

.. code:: ruby

    $ sudo su - gitolite

    $ cat > .gitolite/hooks/common/post-receive
    * [paste hook from contrib dir]

    * [enable WS for repository management in administration->settings->repositories]

    $ vim .gitolite/hooks/common/post-receive
    * [copy generated API key] (DEFAULT_REDMINE_KEY)
    * [set Redmine server URL] (DEFAULT_REDMINE_SERVER)

    $ chmod +x .gitolite/hooks/common/post-receive

    $ vim .gitolite.rc
    * If you are running Gitolite v2 :
    * [ set $GL_GITCONFIG_KEYS = ".*"; ]
    * [ set $REPO_UMASK = 0022; ]

    * If you are running Gitolite v3 :
    * [ set GIT_CONFIG_KEYS => '.*', ]
    * [ set UMASK => 0022, ]

8. Configure plugin in Redmine settings

Found a bug?
------------

Open new issue and complain. You can also fix it and sent pull request.
This plugin is in active usage in current, edge Redmine. Any suggestions are welcome.
