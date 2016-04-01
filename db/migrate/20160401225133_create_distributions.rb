class CreateDistributions < ActiveRecord::Migration
  def change
    create_table :distributions do |t|

      t.timestamps null: false
    end
  end
end
