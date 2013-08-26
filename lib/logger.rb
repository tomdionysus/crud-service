module CrudService
  # This class provides a Generic Logger.
  class Logger
    # Log a debug message
    def debug(str)
      puts "DEBUG: #{str}"
    end

    # Log an info message
    def info(str)
      puts "INFO: #{str}"
    end

    # Log a warning message
    def warn(str)
      puts "WARN: #{str}"
    end

    # Log an error message
    def error(str)
      puts "ERROR: #{str}"
    end
  end
end
