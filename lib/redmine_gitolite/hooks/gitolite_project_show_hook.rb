module RedmineGitolite
  module Hooks
    class GitoliteProjectShowHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_left, :partial => 'redmine_gitolite'
    end
  end
end
