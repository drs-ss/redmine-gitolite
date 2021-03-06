# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :public_keys, :controller => 'gitolite_public_keys'
match 'gitolite_hook' => 'gitolite_hook#index'
match "#{GitoliteConfig.gitolite_smart_http_prefix}/:repo_path/:path" => 'gitolite_http#index', :constraints => { :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :path => /.*/ }
