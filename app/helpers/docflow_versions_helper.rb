module DocflowVersionsHelper

  def link_to_remove_checklist_record (rec)
    result = "<li class='checklist_record' id='ch"+rec.id.to_s+"'>"
    result += "<span class='right-marg'>"+ (rec.display_name) +"</span>"
    result += link_to('', {:controller => "docflow_versions", :action => "remove_checklist", :cid => rec.id}, :class => 'remove_checklist_rec icon icon-del')
    result += "</li>"
    render :inline => result unless result.nil?
  end


  # define proper icon for docfile content-type
  # link to async delete
  # link to show
  def link_to_edit_attached_file (attached_file)
    icon_class,ftype = detect_type (attached_file)

    result = "<p class='attached_file' id='df"+attached_file.id.to_s+"'>"
    result += content_tag(:label,ftype) unless ftype.empty?
    result += link_to( attached_file.filename,
                       {:controller => "docflow_versions", :action => "show_file", :fid => attached_file.id},
                       :class => icon_class+' '+attached_file.filetype )
    result += " - " +attached_file.description.to_s+" " unless attached_file.description.empty?
    result += content_tag( :span," ("+number_to_human_size(attached_file.filesize).to_s+")", :class =>"size" )
    result += link_to( '',
                       {:controller => "docflow_versions", :action => "remove_file", :fid => attached_file.id},
                       :class => 'remove_attached_file icon icon-del' )
    result += "</p>"
    render :inline => result unless result.nil?
  end

  def link_to_show_attached_file (attached_file)
    icon_class,ftype = detect_type (attached_file)

    result = "<p class='attached_file'>"
    result += content_tag(:strong,ftype)+' ' unless ftype.empty?
    result += link_to(attached_file.filename, {:controller => "docflow_versions", :action => "show_file", :fid => attached_file.id},:class => icon_class)
    result += " - " +attached_file.description.to_s+" " unless attached_file.description.empty?
    result += content_tag(:span," ("+number_to_human_size(attached_file.filesize).to_s+")", :class =>"size")
    result += "</p>"
    render :inline => result unless result.nil?
  end

  def detect_type (attached_file)
    icon_class = 'icon icon-file'
    icon_class += ' application-pdf' if attached_file.pdf?
    icon_class += ' text-xml' if attached_file.docx?
    icon_class += ' image-jpeg' if attached_file.image?
    ftype = l(:label_docflow_source_file) if !attached_file.filetype.empty? && attached_file.filetype.to_s == "src_file"
    ftype = l(:label_docflow_public_file) if !attached_file.filetype.empty? && attached_file.filetype.to_s == "pub_file"
    ftype = "" if ftype.nil?

    return [icon_class,ftype]
  end

end
