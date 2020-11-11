class CreateContestants < ActiveRecord::Migration[6.0]
  def change
    create_table :contestants do |t|
      t.string :phone_number, unique: true

      t.timestamps
    end
  end
end
