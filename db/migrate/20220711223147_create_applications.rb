class CreateApplications < ActiveRecord::Migration[7.0]
  def change
    create_table :applications do |t|
      t.string :name, null: false
      t.string :token, null: false, index: {unique: true, name: 'UK_APPLICATION_TOKEN'}, :limit => 36
      t.integer :chats_count, null: false

      t.timestamps
    end
  end
end
