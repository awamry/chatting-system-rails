class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.integer :number, null: false
      t.string :body, null: false
      t.references :chat, null: false, foreign_key: true

      t.timestamps

    end
    add_index :messages, [:chat_id, :number]

  end
end
