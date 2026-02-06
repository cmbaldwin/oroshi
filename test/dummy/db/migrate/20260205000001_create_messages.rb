# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.boolean :state
      t.text :message
      t.jsonb :data, default: {}

      t.timestamps
    end
  end
end
