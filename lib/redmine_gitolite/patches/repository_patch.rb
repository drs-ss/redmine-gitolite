module RedmineGitolite
  module Patches
    module RepositoryPatch
      unloadable

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :git_extra, :foreign_key =>'repository_id', :class_name => 'GitoliteRepositoryExtra', :dependent => :destroy
          after_create :update_values
        end
      end

      module InstanceMethods

        def update_values
          if self.is_a?(Repository::Git)
            new_url = File.join(GitoliteConfig.repository_absolute_base_path, GitoliteHosting.repository_name(self) + ".git")
            self.url = new_url
            self.root_url = new_url
            self.save!
          end
        end

        # Use directory notation: <project identifier>/<repo identifier>
        def git_label
          return "#{project.identifier}/#{identifier}"
        end

        def gitolite_browse_url
          GitoliteConfig.gitolite_ssl_enabled? ? scheme = 'https' : scheme = 'http'
          return "#{scheme}://#{GitoliteConfig.gitolite_server_domain}/projects/#{project.identifier}/repository/#{identifier}"
        end

        def gitolite_daemon_url
          return "git://#{GitoliteConfig.gitolite_server_domain}/#{project.identifier}/#{identifier}"
        end

        def gitolite_http_url
          GitoliteConfig.gitolite_ssl_enabled? ? scheme = 'https' : scheme = 'http'
          return "#{scheme}://#{User.current.login}@#{GitoliteConfig.gitolite_server_domain}/#{GitoliteConfig.gitolite_smart_http_prefix}/#{project.identifier}/#{identifier}.git"
        end

        def gitolite_git_url
          repo_name = GitoliteHosting.repository_name(self)
          return "#{GitoliteConfig.gitolite_user}@#{GitoliteConfig.gitolite_server_domain}:#{repo_name}.git"
        end
      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitolite::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitolite::Patches::RepositoryPatch)
end
