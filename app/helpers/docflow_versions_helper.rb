module DocflowVersionsHelper

  def options_for_checklist_department_select(departments)
    options = ""
    dep_ids =  departments.inject([]){|ar,el| ar << el.id}
    UserDepartment.all.sort_by{|el| el.name.to_s}.unshift(UserDepartment.new(:name => "-")).each do |dep|
      disabled = dep_ids.include?(dep.id) ? " disabled" : ""
      options << "<option value=\"#{dep.id}\"#{disabled}>#{dep.name}</option>"
    end
    options.html_safe
  end  

  def version_checklists_tabs
        tabs = [ {:name => 'users', :partial => 'docflow_checklists/users', :label => :label_docflows_users},
                 {:name => 'groups', :partial => 'docflow_checklists/groups', :label => :label_docflows_groups} ]
  end

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

    result = "<p class='attached_file "+attached_file.filetype.to_s+"' id='df"+attached_file.id.to_s+"'>"
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
    result += link_to(attached_file.filename, {:controller => "docflow_versions", :action => "show_file", :fid => attached_file.id}, :class => icon_class)
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

  def link_to_version (ver, css="", show_date=false)
    label = 'ver.'+ver.version.to_s
    title = (ver.actual_date.nil?) ? "" : l(:label_docflow_actual_from)+" "+format_date(ver.actual_date.utc.getlocal);
    if show_date && !ver.actual_date.nil?
      label += " "+content_tag(:span,"("+format_date(ver.actual_date.utc.getlocal)+")", :style=>"font-size: 10px;")
    end
    label = link_to( label.html_safe, ver, :title => title) 

    render :inline => content_tag(:span, label.html_safe, :class => css)
  end




  def docflow_version_edit_button
    if @version.status.id == 1 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id))
      link_to( image_tag("edit.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_edit_version), :class => "line_link"),
               edit_docflow_version_path(@version),
               :class => "btn btn-right") 
    end
  end

  def docflow_version_new_button      
    if @version.docflow.last_version.status.id == 3 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id))
      link_to( image_tag("add.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_new_version), :class => "line_link"),
               {:controller => 'docflow_versions', :action => 'new', :docflow_id => @version.docflow_id},
               :class => "btn btn-right") 
    end
  end

  def docflow_version_checklist_button
    if @version.status.id == 1 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id))
      link_to( image_tag("group.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_check_list), :class => "line_link"),
                {:controller => 'docflow_versions', :action => 'checklist'},
                 :class => "btn btn-right") 
    end
  end

  def docflow_version_delete_button
    if @version.status.id == 1 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id))
      link_to( image_tag("delete.png", :class=>'img-b')+' '+content_tag(:span, l(:label_docflow_version_delete), :class => "line_link"),
               docflow_version_path(@version),
               :confirm => l(:label_docflow_delete_confirm),
               :method => :delete, :action => :destory, :class => "btn btn-right") 
    end
  end

  def docflow_version_approve_button      
    if @version.status.id == 2 && (User.current.admin? || @version.approver_id == User.current.id)
      link_to( image_tag("exclamation.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_version_approve), :class => "dotted_link"), 
                 '#', :class => 'btn', :id => "show-approve-btn")
    end
  end

  def docflow_version_postpone_button
    if @version.status.id == 2 && (User.current.admin? || (@version.approver_id == User.current.id || @version.author_id == User.current.id))
      link_to( image_tag("bullet_end.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_version_ro_rework), :class => "line_link"), 
               {:controller => 'docflow_versions', :action=> 'postpone'}, :class => 'btn') 
    end
  end

  def docflow_version_to_approvial_button
    if @version.status.id == 1 && (User.current.admin? || (@version.author_id == User.current.id))
      link_to( image_tag("bullet_go.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_version_to_approvial), :class => "line_link"), 
               {:controller => 'docflow_versions', :action=> 'to_approvial'}, :class => 'btn')
    end
  end

  # No button for admin due ambigous behaviour if user accepts document which not should
  def docflow_version_accept_button
    if ( @version.status.id == 3 && @version.user_in_checklist?(User.current.id) && 
         DocflowFamiliarization.where('user_id=? and docflow_version_id=?', User.current.id, @version.id).first.nil? )

      link_to( image_tag("true.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflows_familiarize), :class => "line_link"),
                 {:controller => 'docflow_versions', :action=> 'accept'},
                 :class => 'btn', :id => "accept-ver-btn") 
    end    
  end

  def docflow_version_cancel_button
    if @version.status.id == 3 && (User.current.admin? || (@version.id == @version.docflow.last_version.id && User.current.cancel_docflows?))
      link_to( image_tag("false.png", :class=>'img-b')+' '+content_tag(:span,l(:label_docflow_version_cancel), :class => "line_link"), 
               {:controller => 'docflow_versions', :action=> 'cancel'}, :class => 'btn', :id => "cancel-doc-btn") 
    end
  end


end
