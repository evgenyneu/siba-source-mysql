# encoding: UTF-8

require "siba-source-mysql/db"

module Siba::Source
  module Mysql                 
    OPTION_NAMES = [
      :host,
      :port,
      :protocol,
      :socket,
      :user,
      :password,
      :databases,
      :tables,
      :ignore_tables,
      :custom_parameters
    ]

    MULTIPLE_CHOISES = [:databases, :tables, :ignore_tables]
    LOGIN_PARAMETERS = [:host, :port, :protocol, :socket, :user, :password]
    ENV_PREFIX = "SIBA_MYSQL_"

    class Init                 
      include Siba::LoggerPlug

      attr_accessor :db

      def initialize(options)
        parsed_options = {}
        OPTION_NAMES.each do |option_name|
          if MULTIPLE_CHOISES.include? option_name
            value = Siba::SibaCheck.options_string_array options, option_name.to_s, true
          else
            value = Siba::SibaCheck.options_string options, option_name.to_s, true
            if value.nil?
              # try get the setting from environment variable
              value = ENV["#{ENV_PREFIX}#{option_name.to_s.upcase}"]
            end
          end
          parsed_options[option_name] = value
        end

        @db = Siba::Source::Mysql::Db.new parsed_options
      end                      

      # Collect source files and put them into dest_dir
      # No return value is expected
      def backup(dest_dir)
        logger.info "Dumping MySQL#{db.db_and_table_names}"
        @db.backup dest_dir
      end

      # Restore source files from_dir 
      # No return value is expected
      def restore(from_dir)
        logger.info "Restoring MySQL#{db.db_and_table_names}"
        @db.restore from_dir
      end
    end
  end
end
