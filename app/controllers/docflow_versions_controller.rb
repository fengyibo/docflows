class DocflowVersionsController < ApplicationController
  unloadable

  helper :docflows
  helper :docflow_categories

  before_filter :find_version, :except => [:new, :create]

  before_filter :check_settings
  before_filter :modification_allowed?, :only => [:add_checklists, :remove_checklist, :remove_file, :checklist, :edit, :update, :destroy, :edit_checklists, :remove_checklist_by_department]
  before_filter :new_allowed?, :only => [:new, :create]

  before_filter :authorize
  

  def check_settings
    flash[:error] = "Setup Plugin! Groups was not selected" if Setting.plugin_docflows['approve_allowed_to'].nil?
    redirect_to "/docflows/plugin_disabled" unless Setting.plugin_docflows['enable_plugin']
  end

  def authorize

    return true unless @version

    if ["show", "show_file"].include?(params[:action])
      render_403 unless @version.visible_for_user?
    elsif ( params[:action] == "postpone" )
      render_403 unless [@version.author_id, @version.approver_id].include?(User.current.id) || authorized_globaly_to?(:docflow_versions, :postpone) || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id)
    elsif ( params[:action] == "to_approvial" )
      render_403 unless (@version.author_id == User.current.id) || authorized_globaly_to?(:docflow_versions, :to_approvial) || User.current.edit_docflows_in_category?(@version.docflow.docflow_category_id)
    elsif ( params[:action] == "accept" )
      render_403 unless @version.user_in_checklist?(User.current.id)
    elsif  (params[:action] == "cancel" )
      render_403 unless authorized_globaly_to?(:docflow_versions, :cancel)
    elsif ( params[:action] == "approve" )
      render_403 unless authorized_globaly_to?(:docflow_versions, :approve) || @version.approver_id == User.current.id
    elsif ["show_comments","add_comment","update_comment","remove_comment"].include?(params[:action])
      render_403 unless [@version.approver_id, @version.author_id, @version.docflow.responsible_id].include?(User.current.id) || authorized_globaly_to?(:docflow_versions, :show_comments)
    else
      render_403 unless @version.editable_by_user?
    end
  end


  def modification_allowed?
    cur_version = DocflowVersion.find(params[:id]) unless params[:id].nil? || params[:id] == ""

    unless cur_version.id == cur_version.docflow.last_version.id && cur_version.docflow_status_id == 1
      respond_to do |format|
        format.html {
          flash[:error] = l(:label_docflow_request_failed) + l(:label_docflow_only_last_and_new_editable)
          redirect_to cur_version
        }
        format.json { render :json =>{:result => "fail", :msg => l(:label_docflow_only_last_and_new_editable)} }
      end
    end
  end

  def new_allowed?
    doc = Docflow.find(params[:docflow_id]) unless params[:docflow_id].nil?
    doc = Docflow.find(params[:docflow_version][:docflow_id]) unless params[:docflow_version].nil?

    if doc.nil?
      flash[:error] = l(:label_docflow_document_not_found)
      redirect_to 'docflows#index'
    end
    unless doc.last_version.status.id == 3 || doc.last_version.status.id == 4
      flash[:error] = l(:label_docflow_cant_create_new_version)
      redirect_to doc.last_version
    end
  end


  def show
    @comments = @version.comments.includes(:user) #.order("id")
  end

  def new
    @version = DocflowVersion.new
    @version.docflow_id = params[:docflow_id]
    @version.version = Docflow.find(params[:docflow_id]).last_version.version+1
    @version.author_id = User.current.id
    @version.docflow_status_id = DocflowStatus::DOCFLOW_STATUS_NEW
    # only approver_id transfer but not any changes in view to select approver from prev version
    # because approver should be selected only from target group while new version of document creation
    @version.approver_id = @version.docflow.last_version.approver_id unless @version.docflow.last_version.nil?
  end

  def create
    @version = DocflowVersion.new(params[:docflow_version])
    # @version.approver_id = @version.docflow.last_version.approver_id if params[:inherit_approver] == 'y'
    last_version = @version.docflow.last_version

    respond_to do |format|
      if @version.save        
        @version.copy_checklist(last_version) if params[:inherit_know_list] == 'y'

        @version.save_files(params[:new_files])        
        flash[:error] = @version.errors_msgs.join("<br>").html_safe if @version.errors_msgs.any?
        format.html { redirect_to(@version, :notice => ((flash[:error].nil? || flash[:error] == "") ? l(:label_docflow_version_saved) : nil) ) }
        format.xml  { render :xml => @version, :status => :created, :location => @version }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
      end
    end

  end

  def edit
    @files = @version.files.order('filetype DESC')
  end

  def update
    respond_to do |format|
      if @version.update_attributes(params[:docflow_version])
        @version.save_files(params[:new_files])        
        flash[:error] = @version.errors_msgs.join("<br>").html_safe if @version.errors_msgs.any?
        format.html { redirect_to(@version, :notice => ((flash[:error].nil? || flash[:error] == "") ? l(:label_docflow_version_saved) : nil) ) }
        format.xml  { head :ok }
      else
        @files = @version.files
        format.html { render :action => "edit" }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # todo: check if someone knows about version (already read document).
  # Generaly imposible variant - because of knowelege is after approvial
  def destroy
    respond_to do |format|
      if @version.docflow.first_version.id != @version.id && @version.destroy
        flash[:error] = @version.errors.full_messages.join("<br>").html_safe if @version.errors.any?
        format.html { redirect_to(@version.docflow.last_version, :notice => l(:label_docflow_version_deleted)) }
        format.xml  { head :ok }
      else
        flash[:error] = l(:label_docflow_version_delete_failed)
        format.html { redirect_to(@version.docflow.last_version) }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  def checklist
    render 'docflow_checklists/checklist'
  end

  def copy_checklist
    from_version = DocflowVersion.find(params[:vid])

    @version.copy_checklist(from_version)
    redirect_to(@version)
  end

  def show_comments
    @comments = @version.comments 
    respond_to do |format|
      format.js { render('show_comments') }
    end
  end

  def add_comment
    append_comment
    show_comments    
  end

  def update_comment
    @comment = DocflowComment.find(params[:cid])    
    @comment.update_attributes(params[:docflow_comment])

    show_comments    
  end

  def remove_comment
    @comment = DocflowComment.find(params[:cid])
    @comment.destroy

    show_comments
  end  

  # todo: change JS on async list generation
  def add_checklists
    @version.save_checklists(params[:all_users], params[:users], params[:titles], params[:department_id], params[:group_sets])
    result = "ok"    

    if @version.processed_checklists.blank? && !(params[:all_users].nil? && params[:users].nil? && params[:titles].nil? && params[:department_id].nil?)
      @version.errors_msgs << l(:label_docflow_check_list_error_db)
      result = "fail"
    end
    js_err = @version.errors_msgs.join("<br>").html_safe if @version.errors_msgs.any?    

    respond_to do |format|      
      format.html { 
        flash[:error] = js_err unless js_err.nil?
        redirect_to(:action => "checklist") }
      format.js   { 
        render(:update) {|page|          
          if(params[:tab_refresh] == "users")
            page.replace_html "tab-content-users", :partial => "docflow_checklists/users", :locals => {:js_err => js_err}
            @version.processed_checklists.each{ |rec| page.visual_effect(:highlight, "rec-#{rec[:id]}") }
          elsif(params[:tab_refresh] == "group_sets") 
            page.replace_html "tab-content-group_sets", :partial => "docflow_checklists/group_sets", :locals => {:js_err => js_err}
            @version.processed_checklists.each{ |rec| page.visual_effect(:highlight, "rec-#{rec[:id]}") }            
          else
            page.replace_html "tab-content-groups", :partial => "docflow_checklists/groups", :locals => {:js_err => js_err}
            hid = (params[:department_id].nil? || params[:department_id] == "")  ? "0" : params[:department_id]
            page.visual_effect(:highlight, "dep-#{hid}")
          end
        } 
      }
      format.json { render :json => {:result => result, :msg => (js_err.nil? ? nil : js_err.gsub("<br>","\n")), :saved => @version.processed_checklists}.to_json }
    end
  end


  def edit_checklists
    if params[:department_id] == "0"
      checklists = DocflowChecklist.where("user_department_id IS NULL AND user_title_id IS NOT NULL AND docflow_version_id=?",params[:id])
      params[:department_id] = nil
    else
      checklists = DocflowChecklist.where("user_department_id=? AND docflow_version_id=?",params[:department_id],params[:id])
    end
    checklists.each do |rec|
      rec.destroy
    end
    self.add_checklists
  end


  def autocomplete_for_user
    @users = User.active.not_in_version(@version).like(params[:q]).all(:limit => 100)
    render :layout => false
  end  

  def show_file
    docfile = DocflowFile.find(params[:fid])
    respond_to do |format|
      format.html{
        send_file docfile.diskfile, :filename => filename_for_content_disposition(docfile.filename),
                                    :type => docfile.detect_content_type,
                                    :disposition => ((docfile.image? || docfile.pdf?) ? 'inline' : 'attachment')
      }
    end
  end

  def remove_file
    docfile = DocflowFile.find(params[:fid])
    respond_to do |format|
      if docfile.destroy
        format.html { render :inline => "File dropped!"}
        format.json { render :json => {:result => "ok", :msg => "", :id => params[:fid]}.to_json }
      else
        format.html { render :inline => "Failed to drop file!"}
        format.json { render :json =>{:result => "fail", :msg => "Can't remove file"} }
      end
    end
  end

  def remove_checklist
    checklist = DocflowChecklist.find(params[:cid])

    respond_to do |format|
      if checklist.destroy
        if(params[:tab_refresh] == "users")     
          format.js   { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'docflow_checklists/users' } }       
          format.json { render :json => {:result => "ok", :msg => "", :id => params[:cid]}.to_json }
        else
          format.js { render(:update) {|page| page.replace_html "tab-content-group_sets", :partial => 'docflow_checklists/group_sets' } }       
        end
      else
        format.json { render :json =>{:result => "fail", :msg => "Fail remove checklist record"} }
      end
    end
  end

  def remove_checklist_by_department
    if params[:department_id] == "0"
      checklists = DocflowChecklist.where("user_department_id IS NULL AND user_title_id IS NOT NULL AND docflow_version_id=?",params[:id])
    else
      checklists = DocflowChecklist.where("user_department_id=? AND docflow_version_id=?",params[:department_id],params[:id])
    end

    checklists.each { |checklist|  checklist.destroy }

    respond_to do |format|
      format.js   { render(:update) {|page| page.replace_html "tab-content-groups", :partial => 'docflow_checklists/groups'} }
      format.json { render :json => {:result => "ok", :msg => "", :id => params[:department_id]}.to_json }
    end    
  end

  def accept
    @fam = DocflowFamiliarization.new(:user_id => User.current.id,
                                      :docflow_version_id => params[:id],
                                      :done_date => Time.now)
    unless @fam.save
      flash[:error] = @fam.errors.full_messages.join(" ") if @fam.errors.any?
    end
    redirect_to(@version)
  end

  # todo: avoid magick numbers
  # todo: insert version status: old/archive - to improve know-list queries
  # todo: investigate of rejection status table and bring status to version model
  def to_approvial
    change_status DocflowStatus::DOCFLOW_STATUS_TO_APPROVIAL
  end

  def approve
    @version.actual_date = Date.parse(params[:actual_date]).to_date unless params[:actual_date].nil? || params[:actual_date] == ""
    @version.approve_date = Time.now
    change_status DocflowStatus::DOCFLOW_STATUS_APPROVED
  end

  def postpone
    change_status DocflowStatus::DOCFLOW_STATUS_NEW
  end

  def cancel
    change_status DocflowStatus::DOCFLOW_STATUS_CANCELED
  end

  def change_status (status)
    @version.docflow_status_id = status

    append_comment

    unless @version.save
      flash[:error] = @version.errors.full_messages.join(" ") if @version.errors.any?
    end
    redirect_to(@version)
  end

  def append_comment
    if params[:docflow_comment]
      @comment = DocflowComment.new(params[:docflow_comment])      
      @comment.user_id = User.current.id
      @comment.commentable = @version
      @comment.save unless @comment.notes.empty?
    end 
  end

  private

  def find_version
    @version = DocflowVersion.find(params[:id])    
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
