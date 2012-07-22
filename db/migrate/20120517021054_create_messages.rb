class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :guid
      t.string :country
      t.string :carrier
      t.string :channel
      t.string :application
      t.string :from
      t.string :to
      t.string :subject
      t.string :body

      t.timestamps
    end
  end
end
