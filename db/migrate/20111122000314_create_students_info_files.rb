class CreateStudentsInfoFiles < ActiveRecord::Migration
  def self.up
    create_table :students_info_files do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :students_info_files
  end
end
