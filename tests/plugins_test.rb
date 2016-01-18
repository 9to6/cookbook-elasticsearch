describe_recipe 'elasticsearch2::plugins' do

  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  it "creates the file in plugins" do
    if node.recipes.include?("elasticsearch2::plugins")
      file("/usr/local/elasticsearch/plugins/paramedic/_site/index.html").must_exist.with(:owner, 'elasticsearch')
    end
  end if Chef::VERSION > '10.14'

end
