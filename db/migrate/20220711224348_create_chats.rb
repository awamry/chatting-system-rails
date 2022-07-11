class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.integer :number, null: false
      t.integer :messages_count, null: false
      t.references :application, null: false, foreign_key: true

      t.timestamps
    end
    add_index :chats, [:application_id, :number]
  end
end
