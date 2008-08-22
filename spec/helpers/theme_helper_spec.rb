require File.dirname(__FILE__) + '/../spec_helper'

# TODO wow, this sux. patch asset_tag_helpers to use an overwriteable 
ActionView::Helpers::AssetTagHelper.module_eval <<-eoc
  ASSETS_DIR.replace "#{RAILS_ROOT}/tmp/cache/site.host"
  JAVASCRIPTS_DIR.replace "#{RAILS_ROOT}/tmp/cache/site.host/javascripts"
  STYLESHEETS_DIR.replace "#{RAILS_ROOT}/tmp/cache/site.host/stylesheets"
eoc

describe "the action pack asset_helper" do
  include ActionView::Helpers::AssetTagHelper

  before :each do
    helper.stub!(:join_asset_file_contents).and_return "joined_asset_file_contents"
    helper.stub!(:page_cache_subdirectory).and_return 'tmp/cache/site.host'

    ActionController::Base.perform_caching = true
    @cache_dir = "#{RAILS_ROOT}/#{helper.page_cache_subdirectory}"
    FileUtils.rm_r @cache_dir if File.exists? @cache_dir
  end
  
  after :each do
    ActionController::Base.perform_caching = false
    FileUtils.rm_r @cache_dir if File.exists? @cache_dir
  end
  
  it "#stylesheet_link_tag scopes the stylesheet cache file path to the site's page_cache_subdirectory" do
    touch_assets(ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR, 'foo.css', 'bar.css')
    helper.stylesheet_link_tag('foo', 'bar', :cache => 'default') =~ /href="([^"\?]*)(\?|")/
    File.exists?("#{@cache_dir}/stylesheets/default.css").should be_true
  end
  
  it "#javascript_include_tag scopes the javascript cache file path to the site's page_cache_subdirectory" do
    touch_assets(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, 'foo.js', 'bar.js')
    helper.javascript_include_tag('foo', 'bar', :cache => 'default') =~ /src="([^"\?]*)(\?|")/
    File.exists?("#{@cache_dir}/javascripts/default.js").should be_true
  end
  
  def touch_assets(dir, *filenames)
    FileUtils.mkdir_p dir
    FileUtils.touch filenames.map{|filename| "#{dir}/#{filename}" }
  end
end

describe ThemeAssetTagHelper do
  include ThemeAssetTagHelper
  
  before :each do
    theme = mock(Theme)
    theme.stub!(:id).and_return('theme.id')
    theme.stub!(:local_path).and_return('site-1/theme.id')
    @controller.stub!(:current_themes).and_return [theme]
    
    @theme_path = "themes/theme.id/asset"
  end
  
  def controller
    @controller
  end

  describe "#add_theme_path" do  
    it "should add the theme path to a source" do
      add_theme_path('theme.id', 'asset').should == @theme_path
    end
  end
  
  describe "#add_theme_paths" do  
    it "should add the theme path to a single source" do
      add_theme_paths('theme.id', ['asset']).should == [@theme_path]
    end
    
    it "should add the theme path to multiple sources and leave options untouched" do
      add_theme_paths('theme.id', ['asset', 'else', {:foo => :bar}]).should == [@theme_path, 'themes/theme.id/else', {:foo => :bar}]
    end
  end
  
  describe "#theme_image_tag" do  
    it "should call add_theme_path when building an image tag" do
      should_receive(:add_theme_path).with('theme.id', 'asset').and_return @theme_path
      theme_image_tag('theme.id', 'asset')
    end
  
    it "should return an image tag with the theme path added to src" do
      theme_image_tag('theme.id', 'asset.png') =~ /src="([^"\?]*)(\?|")/
      $1.should == '/images/themes/theme.id/asset.png'
    end
  end
  
  describe "#theme_javascript_include_tag" do  
    it "should call add_theme_path when building a javascript include tag" do
      should_receive(:add_theme_path).with('theme.id', 'asset').and_return @theme_path
      theme_javascript_include_tag('theme.id', 'asset')
    end
  
    it "should return an javascript include tag with the theme path added to source" do
      theme_javascript_include_tag('theme.id', 'asset') =~ /src="([^"\?]*)(\?|")/
      $1.should == '/javascripts/themes/theme.id/asset.js'
    end
  end
  
  describe "#theme_stylesheet_link_tag" do  
    it "should call add_theme_path when building a stylesheet link tag" do
      should_receive(:add_theme_path).with('theme.id', 'asset').and_return @theme_path
      theme_stylesheet_link_tag('theme.id', 'asset')
    end
  
    it "should return a stylesheet link tag with the theme path added to link" do
      theme_stylesheet_link_tag('theme.id', 'asset') =~ /href="([^"\?]*)(\?|")/
      $1.should == '/stylesheets/themes/theme.id/asset.css'
    end
  end
end