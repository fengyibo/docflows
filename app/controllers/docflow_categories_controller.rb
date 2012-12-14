class DocflowCategoriesController < ApplicationController
  unloadable

  before_filter :check_settings, :authorized_globaly?

  def check_settings
    flash[:warning] = "Setup Plugin! Groups was not selected" if Setting.plugin_docflows['approve_allowed_to'].nil?
    redirect_to "/docflows/plugin_disabled" unless Setting.plugin_docflows['enable_plugin']
  end

  # def authorize
  #   render_403 unless authorized_globaly_to?(params[:controller], params[:action])
  # end

  def index
    @categories = DocflowCategory.order("lft")
  end

  def new
    @category = DocflowCategory.new
    @category.parent_id = params[:parent_id] unless params[:parent_id].nil?
  end

  def edit
    @category = DocflowCategory.find(params[:id])
  end

  def create
    @category = DocflowCategory.new(params[:docflow_category])

    respond_to do |format|
      if @category.save
        format.html { redirect_to(:action => "index", :notice => l(:label_docflow_category_saved)) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @category = DocflowCategory.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:docflow_category])
        format.html { redirect_to(:action => "index", :notice => l(:label_docflow_category_saved)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @category = DocflowCategory.find(params[:id])
    @category.destroy

    if @category.errors.any?
      @category.errors.full_messages.each do |msg|
        flash[:warning] = msg
      end
    end

    respond_to do |format|
      format.html { redirect_to(docflow_categories_url) }
      format.xml  { head :ok }
    end
  end

end
