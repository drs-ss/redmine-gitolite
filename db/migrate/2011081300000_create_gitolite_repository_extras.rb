class CreateGitoliteRepositoryExtras < ActiveRecord::Migration
  def self.up
    create_table :gitolite_repository_extras do |t|
      t.column :repository_id, :integer
      t.column :git_daemon,    :integer, :default => 1
      t.column :git_http,      :integer, :default => 1
    end
  end

  def self.down
    drop_table :gitolite_repository_extras
  end

end
