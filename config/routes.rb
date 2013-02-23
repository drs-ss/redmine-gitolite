# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :public_keys, :controller => 'gitolite_public_keys'
match 'gitolite_hook' => 'gitolite_hook#index'

def install_routes(map)
  map.connect ":repo_path/*path", :prefix => "", :repo_path => /([^\/]+\/)*?[^\/]+\.git/, :controller => 'gitolite_http'
end

if defined? map
  install_routes(map)
end
