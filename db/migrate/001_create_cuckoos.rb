class CreateCuckoos < ActiveRecord::Migration
  def change
    create_table :cuckoos do |t|
      t.integer :project_id
      t.integer :tracker_id
      t.integer :days
      t.boolean :sendto_author
      t.boolean :sendto_assignee
      t.boolean :sendto_watcher
      t.boolean :sendto_custom_user
      t.string :trigger_cycle
      t.integer :trigger_point
      t.boolean :send_by_package
    end
  end
end
