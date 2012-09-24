class CreateDocflowFiles < ActiveRecord::Migration
  def change
    create_table :docflow_files do |t|
      t.integer :docflow_version_id
      t.string  :filename
      t.integer :filesize
      t.string  :disk_filename
      t.string  :content_type
      t.string  :description
      t.string  :filetype   # src_file, pub_file

      t.timestamps
    end
  end
end
