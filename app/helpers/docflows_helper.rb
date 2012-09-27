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

end
