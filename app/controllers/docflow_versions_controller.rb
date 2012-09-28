class DocflowVersionsController < ApplicationController
  unloadable

  helper :docflows
  # helper :docflow_files

  before_filter :check_settings
  before_filter :modification_allowed?, :only => [:add_checklists, :remove_checklist, :remove_file, :checklist, :edit, :update, :destroy]
  before_filter :new_allowed?, :only => [:new, :create]

  before_filter :authorize
  

  def check_settings
    flash[:warning] = "Setup Plugin! Groups was not selected" if Setting.plugin_docflows['approve_allowed_to'].nil?
    redirect_to "/docflows/plugin_disabled" unless Setting.plugin_docflows['enable_plugin']
  end

  def authorize
    return false if params[:id].nil? || params[:id] == ""
    ver = DocflowVersion.find(params[:id])

    if ( params[:action] == "show")
      render_403 unless ver.visible_for_user?
    elsif ( params[:action] == "postpone" )
      render_403 unless [ver.author_id, ver.approver_id].include?(User.current.id) || User.current.admin?
    elsif ( params[:action] == "accept" )
      render_403 unless ver.user_in_checklist?(User.current.id)
    elsif  (params[:action] == "cancel" )
      render_403 unless User.current.cancel_docflows?
    elsif ( params[:action] == "approve" )
      render_403 unless User.current.approve_docflows? && ver.approver_id == User.current.id
    else
      render_403 unless ver.editable_by_user?
    end
  end

  def modification_allowed?
    cur_version = DocflowVersion.find(params[:id]) unless params[:id].nil? || params[:id] == ""

    unless cur_version.id == cur_version.docflow.last_version.id && cur_version.docflow_status_id == 1
      respond_to do |format|
        format.html do
          flash[:warning] = l(:label_docflow_request_failed) + l(:label_docflow_only_last_and_new_editable)
          redirect_to cur_version
        end
        format.json { render :json =>{:result => "fail", :msg => l(:label_docflow_only_last_and_new_editable)} }
      end
    end
  end

  def new_allowed?
    doc = Docflow.find(params[:docflow_id]) unless params[:docflow_id].nil?
    doc = Docflow.find(params[:docflow_version][:docflow_id]) unless params[:docflow_version].nil?

    if doc.nil?
      flash[:warning] = l(:label_docflow_document_not_found)
      redirect_to 'docflows#index'
    end
    unless doc.last_version.status.id == 3 || doc.last_version.status.id == 4
      flash[:warning] = l(:label_docflow_cant_create_new_version)
      redirect_to doc.last_version
    end
  end


  def show
    @version = DocflowVersion.find(params[:id])
  end

  def new
    @version = DocflowVersion.new
    @version.docflow_id = params[:docflow_id]
    @version.version = Docflow.find(params[:docflow_id]).last_version.version+1
    @version.author_id = User.current.id
    @version.docflow_status_id = DocflowStatus::DOCFLOW_STATUS_NEW
  end

  def create
    @version = DocflowVersion.new(params[:docflow_version])
    @version.approver_id = @version.docflow.last_version.approver_id if params[:inherit_approver] == 'y'

    # todo: inherit know-list

    respond_to do |format|
      if @version.save
        @version.save_files(params[:new_files])
        flash[:warning] = (l(:label_docflow_files_not_saved, :num_files => @version.failed_files.size.to_s)+"<br>").html_safe if @version.failed_files.size > 0
        flash[:warning] +=  @version.errors_msgs.join("<br>").html_safe if @version.errors_msgs.any?
        format.html { redirect_to(@version, :notice => ((flash[:warning].nil? || flash[:warning] == "") ? nil : l(:label_docflow_version_saved)) ) }
        format.xml  { render :xml => @version, :status => :created, :location => @version }
      else
        flash[:warning] = l(:label_docflow_request_failed)
        flash[:warning] += @version.errors.full_messages.join(" ") if @version.errors.any?
        format.html { render :action => "new" }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
      end
    end

  end

  def edit
    @version = DocflowVersion.find(params[:id])
    @files = @version.files.order('filetype DESC')
  end

  def update
    @version = DocflowVersion.find(params[:id])

    respond_to do |format|
      if @version.update_attributes(params[:docflow_version])
        @version.save_files(params[:new_files])
        flash[:warning] = (l(:label_docflow_files_not_saved, :num_files => @version.failed_files.size.to_s)+"<br>").html_safe if @version.failed_files.size > 0
        flash[:warning] +=  @version.errors_msgs.join("<br>").html_safe if @version.errors_msgs.any?
        format.html { redirect_to(@version, :notice => ((flash[:warning].nil? || flash[:warning] == "") ? nil : l(:label_docflow_version_saved)) ) }
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
    @version = DocflowVersion.find(params[:id])
    respond_to do |format|
      if @version.docflow.first_version.id != @version.id && @version.destroy
        flash[:warning] = @version.errors.full_messages.join("<br>".html_safe) if @version.errors.any?
        format.html { redirect_to(@version.docflow.last_version, :notice => l(:label_docflow_version_deleted)) }
        format.xml  { head :ok }
      else
        flash[:warning] = l(:label_docflow_version_delete_failed)
        format.html { redirect_to(@version.docflow.last_version) }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  def checklist
    @version = DocflowVersion.find(params[:id])
    @users = User.all
    @user_departments = UserDepartment.all
    @user_titles = UserTitle.all
    render 'docflow_checklists/checklist'
  end

  def add_checklists
    @version = DocflowVersion.find(params[:id])
    @version.save_checklists(params[:all_users], params[:users], params[:titles],params[:department_id])

    respond_to do |format|
      if @version.processed_checklists.any?
        err = ""
        @version.processed_checklists.each { |r|  err += (r[:name]+"<br>").html_safe if r[:err] != "" }
        flash[:warning] = (l(:label_docflow_check_list_similar_records)+"<br>" + err).html_safe unless err == ""
        format.html { redirect_to(:action => "checklist")}
        format.json { render :json => {:result => "ok", :msg => "", :saved => @version.processed_checklists}.to_json }
      else
        flash[:warning] = l(:label_docflow_check_list_error_db)
        format.html { redirect_to(:action => "checklist")}
        format.json { render :json =>{:result => "fail", :msg => l(:label_docflow_check_list_error_db)} }
      end
    end
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
        format.html { render :inline => "Record dropped!"}
        format.json { render :json => {:result => "ok", :msg => "", :id => params[:cid]}.to_json }
      else
        format.html { render :inline => "Failed to drop record!"}
        format.json { render :json =>{:result => "fail", :msg => "Fail remove checklist record"} }
      end
    end
  end

  def accept
    @version = DocflowVersion.find(params[:id])
    @fam = DocflowFamiliarization.new(:user_id => User.current.id,
                                      :docflow_version_id => params[:id],
                                      :done_date => Time.now)
    unless @fam.save
      flash[:warning] = @fam.errors.full_messages.join(" ") if @fam.errors.any?
    end
    redirect_to(@version)
  end

  # todo: avoid magick numbers
  # todo: insert version status: old/archive - to improve know-list queries
  # todo: investigate of rejection status table and bring status to version model
  def to_approvial
    change_status 2
  end

  def approve
    @version = DocflowVersion.find(params[:id])
    @version.actual_date = Date.parse(params[:actual_date]).to_date unless params[:actual_date].nil?
    @version.approve_date = Time.now
    change_status 3
  end

  def postpone
    change_status 1
  end

  def cancel
    change_status 4
  end

  def change_status (status)
    @version = DocflowVersion.find(params[:id]) if @version.nil?
    @version.docflow_status_id = status

    unless @version.save
      flash[:warning] = @version.errors.full_messages.join(" ") if @version.errors.any?
    end
    redirect_to(@version)
  end

end
