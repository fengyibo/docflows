class DocflowsController < ApplicationController
  unloadable

  helper :docflow_versions
  helper :docflow_categories

  before_filter :check_settings
  before_filter :authorize, :only => [:new,:edit,:destory] # :create,:update, - need not due model validation

  def check_settings
    flash[:error] = "Setup Plugin! Groups was not selected" if Setting.plugin_docflows['approve_allowed_to'].nil?
    redirect_to "/docflows/plugin_disabled" unless Setting.plugin_docflows['enable_plugin']
  end

  def authorize
    return true if User.current.admin?

    return false if params[:id].nil? || params[:id] == ""
    doc = Docflow.find(params[:id])    
    
    if (params[:action] == "new")
      render_403 unless User.current.edit_docflows_in_some_category?
    else
      render_403 unless User.current.edit_docflows? || ( !doc.nil? && User.current.edit_docflows_in_category?(doc.docflow_category_id) )
    end

    removial_allowed? if params[:action] == "destroy"
  end

  def removial_allowed?
    cur_doc = Docflow.find(params[:id]) unless params[:id].nil? || params[:id] == ""

    if !cur_doc.nil? && cur_doc.versions.count > 1 || (cur_doc.versions.count == 1 && cur_doc.last_version.status.id != 1)
      flash[:error] = l(:label_docflow_request_failed)+' '+l(:label_docflow_removial_not_allowed)
      redirect_to cur_doc.last_version
    end
  end

  def plugin_disabled
    render 'settings/plugin_disabled'
  end

  def index
    if params[:view_as].nil?
      @unread = DocflowVersion.unread_for_user
      @waiting = DocflowVersion.waiting_for_my_approvial
      @in_work = DocflowVersion.in_work
      render 'important_versions'
    else
      @versions = DocflowVersion.in_work if params[:sel] == "in_work"
      @versions = DocflowVersion.waiting_for_my_approvial if params[:sel] == "waiting"
      @versions = DocflowVersion.unread_for_user if params[:sel] == "unread"
      if params[:view_as] == "tree"
        render :partial => 'tree_versions', :layout => false, :locals => {:selection => params[:sel]}
      elsif params[:view_as] == "list"
        render :partial => 'list_versions', :layout => false, :locals => {:selection => params[:sel]}
      end
    end  
  end

  def all
    # todo:
    # Show 3 blocks at one: Waiting for my approvial, In work and unread
    @docs = Docflow.all
    render 'index'
  end

  # todo: select only one version for unread, accepted - equal to current

  # Versions which shoud be accepted by User
  # todo: exclude read versions
  def unread
    @versions = DocflowVersion.unread_for_user
    @page_title = l(:label_docflows_actual)
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  def in_work
    @versions = DocflowVersion.in_work
    @page_title = l(:label_docflows_in_work)
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  # Approved by User document's versions
  def approved_by_me
    @versions = DocflowVersion.approved_by_me
    @page_title = l(:label_docflows_approved_by_me)
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  # Approved by User document's versions
  def created_by_me
    @versions = DocflowVersion.created_by_me
    @page_title = l(:label_docflows_created_by_me)
    # @as_tree = params[:as_tree]
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  #
  def waiting_for_my_approvial
    @versions = DocflowVersion.waiting_for_my_approvial
    @page_title = l(:label_docflows_waiting_for_my_approvial)
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  #
  def sent_to_approvial
    @versions = DocflowVersion.sent_to_approvial
    @page_title = l(:label_docflows_sent_to_approvial)
    if params[:view_as].nil?
      render 'versions_list'      
    else
      render :partial => 'versions_list', :layout => false
    end
  end

  def under_control
    @docs = Docflow.where("responsible_id=?", User.current.id)
    render 'index'
  end

  # Read and accepted documents which was not canceled
  def actual
    @versions = DocflowVersion.actual_for_user
    @page_title = l(:label_docflows_actual)

    if params[:view_as] == "tree"
      render :partial => 'tree_versions', :layout => false
    elsif params[:view_as] == "list"
      render :partial => 'actual_versions', :layout => false
    else
      render 'actual_versions'
    end      
  end

  # Canceled documents which was read and accepted by user
  def canceled
    @versions = DocflowVersion.canceled_for_user
    @page_title = l(:label_docflows_canceled)

    if params[:view_as] == "tree"
      render :partial => 'tree_versions', :layout => false
    elsif params[:view_as] == "list"
      render :partial => 'canceled_versions', :layout => false
    else
      render 'canceled_versions'
    end  
  end

  def new
    @doc = Docflow.new
    @doc.versions.build
  end

  def edit
    @doc = Docflow.find(params[:id])
  end

  def create
    @doc = Docflow.new(params[:docflow])
    @doc.versions.first.author_id = User.current.id
    @doc.versions.first.docflow_status_id = DocflowStatus::DOCFLOW_STATUS_NEW

    respond_to do |format|
      if @doc.save
        @doc.versions.first.save_files(params[:new_files])
        flash[:error] = @doc.versions.first.errors_msgs.join("<br>".html_safe) if @doc.versions.first.errors_msgs.any?
        format.html { redirect_to(:controller => "docflow_versions",:action => "checklist", :id => @doc.versions.first.id) }
        format.xml  { render :xml => @doc, :status => :created, :location => @doc }
      else
        # flash[:error] = l(:label_docflow_doc_failed) 
        format.html { render :action => "new" }
        format.xml  { render :xml => @doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @doc = Docflow.find(params[:id])

    respond_to do |format|
      if @doc.update_attributes(params[:docflow])
        format.html { redirect_to(@doc.last_version) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    # todo: before destroy check if any users know about document!
    @doc = Docflow.find(params[:id])
    @doc.destroy

    respond_to do |format|
      format.html { redirect_to(docflows_url) }
      format.xml  { head :ok }
    end
  end
end