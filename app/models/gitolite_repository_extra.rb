class GitoliteRepositoryExtra < ActiveRecord::Base

  belongs_to :repository, :class_name => 'Repository', :foreign_key => 'repository_id'
  validates_associated :repository
  attr_accessible :id, :repository_id, :git_http, :git_daemon

  def after_initialize
    if self.repository.nil?
      setup_defaults
    end
  end

  def setup_defaults
    write_attribute(:git_http, GitoliteConfig.gitolite_default_smart_http)
    write_attribute(:git_daemon, GitoliteConfig.gitolite_default_git_daemon)
  end

end
