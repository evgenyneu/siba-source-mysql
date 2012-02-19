# encoding: UTF-8

require 'helper/require_unit'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Init do
  before do                    
    @yml_path = File.expand_path('../yml', __FILE__)
    options_hash = load_options "valid" 
    @fmock = mock_file :shell_ok?, true, [String]
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
    Siba::Source::Mysql::Init.new({})
  end

  it "plugin should load options from environment variables" do
    begin
      env_user = ENV[env_var_name("USER")]
      env_password = ENV[env_var_name("PASSWORD")]
      env_host = ENV[env_var_name("HOST")]

      ENV[env_var_name("USER")] = "myuser"
      ENV[env_var_name("PASSWORD")] = "mypassword"
      ENV[env_var_name("HOST")] = "myhost"
      @plugin = Siba::Source::Mysql::Init.new({"host"=> "thishost"})
      @plugin.db.user.must_equal "myuser"
      @plugin.db.password.must_equal "mypassword"
      @plugin.db.host.must_equal "thishost" # this is specified, do not get from environment
    ensure
      ENV[env_var_name("USER")] = env_user
      ENV[env_var_name("PASSWORD")] = env_password
      ENV[env_var_name("HOST")] = env_host
    end
  end

  def env_var_name(name)
    "#{Siba::Source::Mysql::ENV_PREFIX}#{name}"
  end

  it "should call backup" do
    @fmock.expect :run_this, true, []
    @fmock.expect :dir_entries, [], [String]
    @fmock.expect :run_shell, nil, [String, String]
    @fmock.expect :file_file?, true, [String]
    @plugin.backup "/dest/dir"
  end

  it "should call restore" do
    @fmock.expect :file_file?, true, [String]
    @fmock.expect :run_shell, nil, [String, String]
    @plugin.restore "/from_dir"
  end
end
