class AddOtherUsersToCuckoos < ActiveRecord::Migration
  def change
    add_column :cuckoos, :other_users, :string, array: true, default: []
  end
end
