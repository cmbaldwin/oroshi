class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.references :user, null: true, foreign_key: true, index: true
      t.string :service, null: false
      t.string :key_name, null: false
      t.text :value # encrypted by Active Record Encryption
      t.datetime :expires_at
      t.integer :status, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :credentials, [ :service, :key_name, :user_id ], unique: true, name: "index_credentials_on_service_key_user"
    add_index :credentials, :status
    add_index :credentials, :expires_at
  end
end
