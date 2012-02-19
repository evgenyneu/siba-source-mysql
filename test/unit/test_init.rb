# encoding: UTF-8

require 'helper/require_unit'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Init do
  before do                    
    @yml_path = File.expand_path('../yml', __FILE__)
    options_hash = load_options "valid" 
    @plugin = Siba::Source::Mysql::Init.new options_hash
  end

  it "should load plugin" do
    @plugin.must_be_instance_of Siba::Source::Mysql::Init
    @plugin.db.must_be_instance_of Siba::Source::Mysql::Db
    opt = @plugin.db.options
    opt[:host].must_equal "myhost"
    opt[:port].must_equal "123"
    opt[:protocol].must_equal "TCP"
    opt[:socket].must_equal "/tmp/mysql.sock"
    
    opt[:user].must_equal "myuser"
    opt[:password].must_equal "mypassword"

    opt[:databases].must_equal ["db1"]
    opt[:tables].must_equal ["table1", "table2"]
    opt[:ignore_tables].must_equal ["db1.table1", "db1.table2"]
    opt[:custom_parameters].must_equal "--parameters"
  end

  it "should load plugin with empty options" do
    @plugin = Siba::Source::Mysql::Init.new({})
    @plugin.db.options.values.all? {|a| a.nil?}.must_equal true
  end

  it "should call backup" do
    @plugin.backup "/dest/dir"
  end

  it "should call restore" do
    @plugin.restore "/from_dir"
  end
end
