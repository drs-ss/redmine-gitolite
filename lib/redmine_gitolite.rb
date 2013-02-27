## Redmine dependencies
# require project first!
require_dependency 'project'
require_dependency 'projects_controller'
require_dependency 'principal'
require_dependency 'repository'
require_dependency 'repositories_controller'
require_dependency 'repositories_helper'
require_dependency 'user'

## Redmine Gitolite Libs
require_dependency 'libs/gitolite_redmine'
require_dependency 'libs/gitolite_hosting'
require_dependency 'libs/gitolite_recycle'
require_dependency 'libs/gitolite_config'

## Redmine Gitolite Patches
require_dependency 'redmine_gitolite/patches/project_patch'
require_dependency 'redmine_gitolite/patches/projects_controller_patch'

require_dependency 'redmine_gitolite/patches/repository_patch'
require_dependency 'redmine_gitolite/patches/repositories_controller_patch'
require_dependency 'redmine_gitolite/patches/repositories_helper_patch'

require_dependency 'redmine_gitolite/patches/user_patch'

## Redmine Gitolite Hooks
require_dependency 'redmine_gitolite/hooks/gitolite_project_show_hook'
require_dependency 'redmine_gitolite/hooks/gitolite_public_key_hook'
