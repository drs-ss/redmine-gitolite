require 'redmine'

require 'redmine_gitolite'

VERSION_NUMBER = '0.0.3'

Redmine::Plugin.register :redmine_gitolite do
  name 'Redmine Gitolite plugin'
  author 'Arkadiusz Hiler, Joshua Hogendorn, Jan Schulz-Hofen, Kah Seng Tay, Jakob Skjerning, Nicolas Rodriguez'
  description 'Enables Redmine to manage Gitolite repositories.'
  version VERSION_NUMBER
  url 'https://github.com/pitit-atchoum/redmine-gitolite/'
  author_url 'http://ivyl.0xcafe.eu/'

  requires_redmine :version_or_higher => '2.0.0'

  settings({
    :partial => 'settings/redmine_gitolite',
    :default => {
      # global settings
      'gitoliteIdentityPrivateKeyFile'     => (ENV['HOME'] + "/.ssh/redmine_gitolite_admin_id_rsa").to_s,
      'gitoliteRepositoryAbsoluteBasePath' => '/home/git/repositories/',
      'gitoliteUser'                       => 'git',
      'gitoliteServerDomain'               => 'example.com',
      'gitoliteSmartHttpPrefix'            => 'smart',
      'gitoliteLockWaitTime'               => '10',
      'gitoliteSslEnabled'                 => false,
      'gitoliteAllProjectsUseGit'          => true,
      'gitoliteDefaultSmartHttp'           => true,
      'gitoliteDefaultGitDaemon'           => true,

      # recycle bin settings
      'gitoliteRecycleBinDeleteRepositories' => true,
      'gitoliteRecycleBinExpireTime'         => '24.0',
    }
  })
end

# initialize observer
ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitoliteObserver

Rails.configuration.after_initialize do
  ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitoliteHostingSettingsObserver
  GitoliteHostingSettingsObserver.instance.reload_this_observer
end
