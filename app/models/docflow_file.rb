class DocflowFile < ActiveRecord::Base
  unloadable

  belongs_to :docflow_version

  validates_presence_of :filename
  validates_length_of :filename, :maximum => 255
  validates_length_of :disk_filename, :maximum => 255

  cattr_accessor :storage_path
  @@storage_path = Setting.plugin_docflows['storage_path'].to_s || File.join(Rails.root, "files")

  # todo: investigate problem of possible leaving files on disk while io-errors (risk of quota overflow)
  # Strong solution: redefine model.destroy method

  after_destroy :delete_from_disk!
  before_save :save_on_disk!



  def file=(uploaded_file)
    @tmp_file = uploaded_file

    self.filename = @tmp_file.original_filename if @tmp_file.respond_to?(:original_filename)
    self.filename.force_encoding("UTF-8") if self.filename.respond_to?(:force_encoding)
    self.content_type = @tmp_file.content_type.to_s.chomp if @tmp_file.respond_to?(:content_type)
    self.content_type = Redmine::MimeType.of(filename) if content_type.blank? && filename.present?

    # Don't save the content type if it's longer than the authorized length
    self.content_type = nil if content_type && content_type.length > 255
  end


  # Redefined save because when model used via nested-attributes
  # the function 'update_attributes' not called during model update
  # def save(options={})
  #   return if @tmp_file.nil? # nothing to save
  #   return super(options) if save_on_disk!
  # end


  # def destroy
  #   return super if delete_from_disk!
  # end

  def allowed_type?    
    Setting.plugin_docflows['enabled_extensions'].to_s.split(',').include?(filename.split('.')[-1])
  end

  def image?
    filename =~ /\.(bmp|gif|jpg|jpe|jpeg|png)$/i
  end

  def pdf?
    filename =~ /\.pdf$/i
  end

  def docx?
    filename =~ /\.docx$/i
  end

  def detect_content_type
    (content_type.nil?) ? Redmine::MimeType.of(filename).to_s : content_type
  end

  # Returns file's location on disk.
  # Based on class and plugin storage settings

  def diskfile
    File.join(self.class.storage_path.to_s, self.disk_filename)
  end

  #############################
  ##    PRIVATE METHODS
  #############################

  private

  # Saves file to disk and updates instance attributes before model updates
  # uncommenting lines with prev_file provides of updating model

  def save_on_disk!
    return false if @tmp_file.size <= 0 || !allowed_type?
    # prev_file = DocflowFile.find(id) unless id.nil?

    # todo: regenerate timestamp if file exists
    self.disk_filename = Time.new.to_i.to_s + File.extname(@tmp_file.original_filename)

    self.filesize = @tmp_file.size
    Rails.logger.info("\n\n Saving attachment '#{diskfile}' (#{@tmp_file.size} bytes)")
    File.open(diskfile, "wb") do |f|
      if @tmp_file.respond_to?(:read)
        buffer = ""
        while (buffer = @tmp_file.read(8192))
          f.write(buffer)
        end
      else
        f.write(@tmp_file)
      end
    end
    File.exist?(diskfile)
    # prev_file.delete_from_disk! if prev_file.nil?
  end

  def delete_from_disk!
    if self.disk_filename.present? && File.exist?(diskfile)
      File.delete(diskfile)
    end
  end

end