module DocflowsHelper

  def docflow_new_button
    if User.current.edit_docflows? || User.current.edit_docflows_in_some_category?
      link_to(l(:label_docflow_add), {:controller => 'docflows', :action => 'new'}, :class => 'icon icon-add')
    end    
  end

  def docflow_delete_button
    @doc = @version.docflow if @doc.nil?
    if @doc.versions.size == 1 && @doc.last_version.status.id < 3 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@doc.docflow_category_id))

      link_to(l(:label_docflow_remove), docflow_path(@doc), :confirm => l(:label_docflow_delete_confirm),
              :method => :delete, :action => :destory, :class => 'icon icon-del')
    end
  end

  def docflow_edit_button
    @doc = @version.docflow if @doc.nil?
    if @version.docflow.last_version.status.id  < 4 && (User.current.edit_docflows? || User.current.edit_docflows_in_category?(@doc.docflow_category_id))
      link_to l(:label_docflow_edit), edit_docflow_path(@doc), :class=>"icon icon-edit" 
    end    
  end  

  def docflow_query_annotation(qu)
    # html = "<div class='anno_helper'>"
    html = ""
    html << link_to(l(:label_docflow_query_legend), '#', :class => 'icon icon-help show_annotation')
    html << link_to(l(:label_docflow_query_legend_hide), '#', :class => 'icon icon-help hide_annotation_a', :style => "display:none;")
    # html << "</div>"

    html << "<div class='annotation' style='display:none;'>"
    html << link_to('', '#', :class => 'icon close-icon hide_annotation', :style=>"margin-left:-18px; margin-top:-1px;", :legend => l(:label_docflow_query_legend_hide))    
    html << content_tag(:span, l( "label_docflow_#{qu}_query_legend".to_sym ).html_safe )
    html << "</div>"

    html.html_safe
  end

end
