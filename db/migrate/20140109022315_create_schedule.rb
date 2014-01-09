class CreateSchedule < ActiveRecord::Migration
	def change
		create_table :schedules do |t|
			t.string :time
			t.string :command
			t.string :requester
			t.boolean :executed, :default => 0
		end
	end
end
