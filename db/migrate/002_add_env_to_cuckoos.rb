class AddEnvToCuckoos < ActiveRecord::Migration
  def change
    add_column :cuckoos, :env, :string
  end
end
