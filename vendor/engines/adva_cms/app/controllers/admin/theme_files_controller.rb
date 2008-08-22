class Admin::ThemeFilesController < Admin::BaseController
  layout "admin"
  
  before_filter :set_theme
  before_filter :set_file, :only => [:show, :update, :destroy]
  
  guards_permissions :theme, :update => [:show, :new, :create, :edit, :update, :destroy]
  
  def show
  end

  def new
    @file = Theme::File.new @theme
  end

  def create
    @file = Theme::File.create @theme, params[:file]
    if @file = Array(@file).first
      expire_pages_by_site! # TODO use active_model?
      expire_template! @file
      flash[:notice] = "The file has been created."
      redirect_to admin_theme_file_path(@site, @theme.id, @file.id)
    else
      flash.now[:error] = "The file could not be created."
      render :action => :new
    end
  end
  
  def update
    if @file.update_attributes params[:file]
      expire_pages_by_site! # TODO use active_model?
      expire_template! @file
      flash[:notice] = "The file has been updated."
      redirect_to admin_theme_file_path(@site, @theme.id, @file.id)
    else
      flash.now[:error] = "The file could not be updated."
      render :action => :show
    end
  end

  def destroy
    if @file.destroy
      expire_pages_by_site! # TODO use active_model?
      expire_template! @file
      flash[:notice] = "The file has been deleted."
      redirect_to admin_theme_path(@site, @theme.id)
    else
      flash.now[:error] = "The file could not be deleted."
      render :action => :show
    end
  end
  
  private
  
    def expire_pages_by_site!
      # this misses assets like stylesheets which aren't tracked
      # expire_pages CachedPage.find_all_by_site_id(@site.id)
      expire_site_page_cache
    end
  
    def expire_template!(file)
      return unless file.is_a? Theme::Template
      ActionView::Base.new.view_paths.reload!
      
      # need to steal this from ActionView::Template because it's not reusable for non-existant files
      segment = file.fullpath.to_s
      segment.sub!(/^#{Regexp.escape(File.expand_path(RAILS_ROOT))}/, '') if defined?(RAILS_ROOT)
      segment.gsub!(/([^a-zA-Z0-9_])/) { $1.ord }

      compiled = ActionView::Base::CompiledTemplates.instance_methods(false).select{|name| name =~ /#{segment}/ }
      compiled.each do |method|
        ActionView::Base::CompiledTemplates.send :remove_method, method
      end
    end
  
    def set_theme
      @theme = @site.themes.find(params[:theme_id]) or raise "can not find theme #{params[:theme_id]}"
    end
  
    def set_file
      @file = @theme.files.find params[:id]
      raise "can not find file #{params[:id]}" unless @file and @file.valid?      
    end
end
