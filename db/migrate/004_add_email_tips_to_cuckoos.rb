class AddEmailTipsToCuckoos < ActiveRecord::Migration
  def change
    add_column :cuckoos, :email_tips, :string
  end
end
