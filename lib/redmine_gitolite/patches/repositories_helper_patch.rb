module RedmineGitolite
  module Patches
    module RepositoriesHelperPatch
      unloadable

      def self.included(base)
        base.send(:alias_method_chain, :git_field_tags, :disabled_configuration)
      end

      def git_field_tags_with_disabled_configuration(form, repository)
        content_tag('p', form.text_field(
                          :extra_protected_refexes, :label => l(:label_git_protected_refexes),
                          :size => 30) +
                          '<br />'.html_safe +
                          '<em class="info">Gitolite refexes that only repository managers can push to.</em>'.html_safe)
      end

    end
  end
end

unless RepositoriesHelper.include?(RedmineGitolite::Patches::RepositoriesHelperPatch)
  RepositoriesHelper.send(:include, RedmineGitolite::Patches::RepositoriesHelperPatch)
end
