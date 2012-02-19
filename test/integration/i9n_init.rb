# encoding: UTF-8

require 'helper/require_integration'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Init do
  TEST_DB_NAME = "siba_test_mysql_0992"
  TEST_VALUE = rand 100000
  include Siba::FilePlug

  before do
    @cls = Siba::Source::Mysql::Init
  end

  it "should backup and restore" do
    puts "
------------------
Note: to run integration tests on your MySQL database, please set required access parameters in environment variables: SIBA_MYSQL_USER, SIBA_MYSQL_PASSWORD, SIBA_MYSQL_HOST etc.
------------------
"
    begin
      # insert test data into db
      @obj = @cls.new({"databases" => [TEST_DB_NAME]})
      drop_db
      create_db
      create_table
      insert_row
      count_rows.must_equal 1

      # backup
      out_dir = mkdir_in_tmp_dir "mysql"
      @obj.backup out_dir
      path_to_backup = File.join(out_dir, Siba::Source::Mysql::Db::BACKUP_FILE_NAME)
      File.file?(path_to_backup).must_equal true

      # add another row after backup
      insert_row
      count_rows.must_equal 2

      # restore
      @obj.restore out_dir
      count_rows.must_equal 1, "Should restore db to one row"
    ensure
      drop_db rescue nil
    end
  end  

  def drop_db
    sql("drop database if exists #{TEST_DB_NAME}")
  end

  def create_db
    sql("create database #{TEST_DB_NAME}")
  end

  def create_table
    sqldb("create table sibatest (id INT)")
  end

  def insert_row
    sqldb(%(insert into sibatest values (123)))
  end

  def count_rows
    sqldb(%(select count(*) from sibatest)).to_i
  end

  def sqldb(sql)
    sql("#{use_database}#{sql}")
  end

  def sql(sql)
    siba_file.run_shell(%(mysql --silent #{get_mysql_params} -e "#{sql}"))
  end

  def use_database
    "use #{TEST_DB_NAME}; "
  end

  def get_mysql_params
    params = @obj.db.get_mysql_params
    unless @obj.db.password.nil?
      params.gsub! Siba::Source::Mysql::Db::HIDE_PASSWORD_TEXT, @obj.db.password
    end
    params
  end

  def insert_value
    siba_file.run_shell(%(mongo #{TEST_DB_NAME} --quiet --eval "db.foo.save({a: #{TEST_VALUE}})"))
  end

  def count_values
    siba_file.run_shell(%(mongo #{TEST_DB_NAME} --quiet --eval "db.foo.count({a: #{TEST_VALUE}})")).to_i
  end
end
