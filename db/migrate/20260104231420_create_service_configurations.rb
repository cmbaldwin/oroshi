class CreateServiceConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :service_configurations do |t|
      t.string :service, null: false
      t.boolean :enabled, default: false, null: false
      t.text :description

      t.timestamps
    end

    add_index :service_configurations, :service, unique: true
    add_index :service_configurations, :enabled
  end
end
