# encoding: UTF-8

require "siba-source-mysql/db"

module Siba::Source
  module Mysql                 
    class Init                 
      include Siba::LoggerPlug

      attr_accessor :db

      def initialize(options)
        host = Siba::SibaCheck.options_string options, "host", true
        port = Siba::SibaCheck.options_string options, "port", true
        protocol = Siba::SibaCheck.options_string options, "protocol", true
        socket = Siba::SibaCheck.options_string options, "socket", true

        user = Siba::SibaCheck.options_string options, "user", true
        password = Siba::SibaCheck.options_string options, "password", true

        databases = Siba::SibaCheck.options_string_array options, "databases", true
        tables = Siba::SibaCheck.options_string_array options, "tables", true
        ignore_tables = Siba::SibaCheck.options_string_array options, "ignore_tables", true
        
        custom_parameters = Siba::SibaCheck.options_string options, "custom_parameters", true

        @db = Siba::Source::Mysql::Db.new({
          host: host, 
          port: port, 
          protocol: protocol,
          socket: socket,
          user: user,
          password: password,
          databases: databases,
          tables: tables,
          ignore_tables: ignore_tables,
          custom_parameters: custom_parameters
        })
      end                      

      # Collect source files and put them into dest_dir
      # No return value is expected
      def backup(dest_dir)
      end

      # Restore source files from_dir 
      # No return value is expected
      def restore(from_dir)
      end
    end
  end
end
