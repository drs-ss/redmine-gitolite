module RedmineGitolite
  module Patches
    module UserPatch
      unloadable

      def self.included(base)
        base.class_eval do
          has_many :gitolite_public_keys, :dependent => :destroy
        end
      end

    end
  end
end

unless User.included_modules.include?(RedmineGitolite::Patches::UserPatch)
  User.send(:include, RedmineGitolite::Patches::UserPatch)
end
