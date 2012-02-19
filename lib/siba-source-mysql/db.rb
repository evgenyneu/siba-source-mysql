# encoding: UTF-8

module Siba::Source
  module Mysql                 
    class Db                 
      HIDE_PASSWORD_TEXT = "****p7d****"
      BACKUP_FILE_NAME = "mysql_dump"
      include Siba::FilePlug
      include Siba::LoggerPlug

      attr_accessor :options

      def initialize(options)
        @options = options

        if !tables.nil? && !tables.empty? && 
          (databases.nil? || (!databases.nil? && databases.size != 1))
          raise Siba::CheckError, "When 'tables' option is set there must be a single database specified in 'databases' option."
        end

        Siba::Source::Mysql::Db.check_spaces_in_arrays databases, 'databases'
        Siba::Source::Mysql::Db.check_spaces_in_arrays tables, 'tables'
        Siba::Source::Mysql::Db.check_spaces_in_arrays ignore_tables, 'ignore_tables'

        check_installed
      end


      def check_installed
        msg =  "utility is not found. Please make sure MySQL is installed and its bin directory is added to your PATH."
        raise Siba::Error, "'mysqldump' #{msg}" unless siba_file.shell_ok? "mysqldump --help"
        raise Siba::Error, "'mysql' #{msg}" unless siba_file.shell_ok? "mysql --help"
        logger.debug "Mysql backup utilities verified"
      end

      def backup(dest_dir)        
        unless Siba::FileHelper.dir_empty? dest_dir
          raise Siba::Error, "Failed to backup MySQL: output directory is not empty: #{dest_dir}"
        end

        path_to_backup = File.join dest_dir, BACKUP_FILE_NAME
        command_without_password = %(mysqldump #{get_mysqldump_params} --routines --result-file="#{path_to_backup}")
        command = command_without_password
        unless password.nil?
          command = command_without_password.gsub HIDE_PASSWORD_TEXT, password
        end
        logger.debug command_without_password
        output = siba_file.run_shell command, "failed to backup MySQL: #{command_without_password}"
        raise Siba::Error, "failed to backup MySQL: #{output}" if output =~ /ERROR:/

        unless siba_file.file_file? path_to_backup
          raise Siba::Error, "Failed to backup MySQL: backup file was not created"
        end
      end

      def restore(from_dir)
        path_to_backup = File.join from_dir, BACKUP_FILE_NAME
        unless siba_file.file_file? path_to_backup
          raise Siba::Error, "Failed to restore MySQL: backup file does not exist: #{path_to_backup}"
        end

        command_without_password = %(mysql -e "source #{path_to_backup}" --silent #{get_mysql_params})
        command = command_without_password
        unless password.nil?
          command = command_without_password.gsub HIDE_PASSWORD_TEXT, password
        end
        logger.debug command_without_password
        output = siba_file.run_shell command, "failed to restore MySQL: #{command_without_password}"
        raise Siba::Error, "Failed to restore MySQL: #{output}" if output =~ /ERROR/
      end

      def get_mysqldump_params
        params = []
        OPTION_NAMES.each do |name|
          val = options[name]
          next if val.nil? && name != :databases
          if MULTIPLE_CHOISES.include? name
            case name
            when :databases
              if val.nil? || val.empty?
                params << "--all-databases" 
              else
                params << "--databases #{val.join(" ")}"  
              end
            when :tables
              params << "--tables #{val.join(" ")}"  
            when :ignore_tables
              val.each do |ignore_table|
                params << %(--ignore-table=#{ignore_table})
              end
            end
          elsif name == :custom_parameters
            params << val
          else
            params << Siba::Source::Mysql::Db.format_mysql_parameter(name, val)
          end
        end
        params.join " "
      end

      def get_mysql_params
        params = []
        LOGIN_PARAMETERS.each do |name|
          val = options[name]
          next if val.nil?
          params << Siba::Source::Mysql::Db.format_mysql_parameter(name, val)
        end
        params.join " "
      end

      def self.format_mysql_parameter(name, val)
        val = HIDE_PASSWORD_TEXT if name == :password
        val = escape_for_shell val
        %(--#{name.to_s}="#{val}")
      end

      def self.escape_for_shell(str)
        str.gsub "\"", "\\\""
      end

      def self.check_spaces_in_arrays(array, option_name)
        unless array.nil? || array.empty?
          array.each do |value|
            value.strip!
            if value.gsub(/[,;]/," ").split(" ").size > 1  
              raise Siba::CheckError, "'#{option_name}' value can not contain spaces or commas. If you need to specify multiple values please use YAML array sytax instead:
- one
- two
- three"
            end
          end
        end
      end

      def method_missing(meth, *args, &block)
        if method_defined? meth
          options[meth]
        else
          super
        end
      end

      def respond_to?(meth)
        if method_defined? meth
          true
        else
          super
        end
      end

      def method_defined?(meth)
        OPTION_NAMES.include? meth.to_sym
      end
      
      def db_and_table_names
        names = []
        unless databases.nil? || databases.empty?
          names << "DB#{databases.size > 1 ? "s": ""}: #{databases.join(", ")}" 
        else
          names << "all databases" 
        end

        unless tables.nil? || tables.empty?
          names << "table#{tables.size > 1 ? "s": ""}: #{tables.join(", ")}"
        end
        out = names.join(", ")
        out = " > " + out unless out.empty?
        out
      end
    end
  end
end
