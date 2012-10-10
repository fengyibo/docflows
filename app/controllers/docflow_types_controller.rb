class DocflowTypesController < ApplicationController
  unloadable
  before_filter :check_settings, :authorize

  def check_settings
    flash[:warning] = "Setup Plugin! Groups was not selected" if Setting.plugin_docflows['approve_allowed_to'].nil?
    redirect_to "/docflows/plugin_disabled" unless Setting.plugin_docflows['enable_plugin']
  end

  def authorize
    render_403 unless User.current.admin?
  end

  def index
    @types = DocflowType.order("name")
  end

  def new
    @type = DocflowType.new
  end

  def edit
    @type = DocflowType.find(params[:id])
  end

  def create
    @type = DocflowType.new(params[:docflow_type])

    respond_to do |format|
      if @type.save
        format.html { redirect_to(:action => "index", :notice => l(:label_docflow_type_saved)) }
        format.xml  { render :xml => @type, :status => :created, :location => @type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @type = DocflowType.find(params[:id])

    respond_to do |format|
      if @type.update_attributes(params[:docflow_type])
        format.html { redirect_to(:action => "index", :notice => l(:label_docflow_type_saved)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @type = DocflowType.find(params[:id])
    @type.destroy
    
    flash[:error] = @type.errors.full_messages.join("<br>").html_safe if @type.errors.any?

    respond_to do |format|
      format.html { redirect_to(docflow_types_url) }
      format.xml  { head :ok }
    end
  end  
end