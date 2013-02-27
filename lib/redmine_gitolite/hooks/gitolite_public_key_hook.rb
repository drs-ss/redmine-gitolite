module RedmineGitolite
  module Hooks
    class GitolitePublicKeyHook < Redmine::Hook::ViewListener
      render_on :view_my_account_contextual, :inline => "| <%= link_to(l(:label_public_keys), public_keys_path) %>"
    end
  end
end
