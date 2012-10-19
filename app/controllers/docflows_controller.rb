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

  def render_default
    respond_to do |format|   
      format.html { render 'versions_list' }
      format.js   { 
        render(:update) {|page| page.replace_html "view_container", :partial => ( params[:view_as] == "tree" ? 'tree_versions' : 'list_versions') } 
      }       
    end
  end

  def index
    @unread = DocflowVersion.unread_for_user
    @waiting = DocflowVersion.waiting_for_my_approvial
    @in_work = DocflowVersion.in_work

    respond_to do |format|   
      format.html { render 'important_versions' }
      format.js {
        @versions = @in_work if params[:sel] == "in_work"
        @versions = @waiting if params[:sel] == "waiting_for_my_approvial"
        @versions = @unread if params[:sel] == "unread"

        partial = (params[:sel] == "in_work") ? "list_versions" : "list_with_author"
        partial = (params[:view_as] == "tree") ? "tree_versions" : partial

        render(:update) {|page| page.replace_html "view_container_"+params[:sel], :partial => partial, :locals => {:sel => params[:sel]} } 
      }       
    end
  end

  def all
    @docs = Docflow.all
    render 'index'
  end

  # Versions which shoud be accepted by User, but not yet
  def unread
    @versions = DocflowVersion.unread_for_user
    @page_title = l(:label_docflows_actual)
    render_default
  end

  # Created by user versions which is in work (not approved yet)
  def in_work
    @versions = DocflowVersion.in_work
    @page_title = l(:label_docflows_in_work)
    render_default
  end

  # Approved by User document's versions
  def approved_by_me
    @versions = DocflowVersion.approved_by_me
    @page_title = l(:label_docflows_approved_by_me)
    render_default
  end

  # Approved by User document's versions
  def created_by_me
    @versions = DocflowVersion.created_by_me
    @page_title = l(:label_docflows_created_by_me)
    render_default
  end

  #
  def waiting_for_my_approvial
    @versions = DocflowVersion.waiting_for_my_approvial
    @page_title = l(:label_docflows_waiting_for_my_approvial)
    render_default
  end

  #
  def sent_to_approvial
    @versions = DocflowVersion.sent_to_approvial
    @page_title = l(:label_docflows_sent_to_approvial)
    render_default
  end

  def under_control
    @versions = DocflowVersion.joins(:docflow).where("responsible_id=#{User.current.id}")
    @page_title = l(:label_docflows_under_control)
    render_default
  end

  # Read and accepted documents which was not canceled
  def actual
    @versions = DocflowVersion.actual_for_user
    @page_title = l(:label_docflows_actual)
    respond_to do |format|   
      format.html { render 'versions_list' }
      format.js   { 
        render(:update) {|page| page.replace_html "view_container", :partial => ( params[:view_as] == "tree" ? 'tree_versions' : 'actual_versions') } 
      }       
    end    
  end

  # Canceled documents which was read and accepted by user
  def canceled
    @versions = DocflowVersion.canceled_for_user
    @page_title = l(:label_docflows_canceled)

    respond_to do |format|   
      format.html { render 'versions_list' }
      format.js   { 
        render(:update) {|page| page.replace_html "view_container", :partial => ( params[:view_as] == "tree" ? 'tree_versions' : 'canceled_versions') } 
      }       
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