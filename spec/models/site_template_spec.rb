require File.dirname(__FILE__) + "/../spec_helper"

describe SiteTemplate do

  reset_domain_tables :editor_changes,  :site_feature, :site_template, :domain_file

  
  before(:each) do
    @site_template = SiteTemplate.new(:name => 'Test Template')
  end

  it "should update the special attribute of a folder after a save" do
    folder1 = DomainFile.create_folder("Original")
    folder2 = DomainFile.create_folder("Second")
    @site_template.domain_file = folder1
    @site_template.save
    
    folder1.reload
    folder1.special.should == 'template'
    
    @site_template.domain_file_id = folder2.id
    @site_template.save
    
    folder1.reload
    folder2.reload
    
    folder1.special.should be_blank
    folder2.special.should == 'template'
  end

  it "should be able to create the default template" do
    assert_difference 'SiteTemplate.count', 1 do
      SiteTemplate.create_default_template
    end
  end

  it "should be able to update zones and options" do
    @site_template.template_html = '<cms:zone name="Main"/><cms:zone name="Sidebar"/>'
    assert_difference 'SiteTemplate.count', 1 do
      assert_difference 'SiteTemplateZone.count', 0 do
        @site_template.save
      end
    end

    assert_difference 'SiteTemplateZone.count', 2 do
      @site_template.update_zones_and_options
    end
  end
end
