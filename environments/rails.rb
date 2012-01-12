# set up rails environment, if any
begin
  require 'rails/version'
  if Rails::VERSION::MAJOR < 3
    require File.expand_path('../environments/rails-2.3/config/environment', File.dirname(__FILE__))
  else
    require File.expand_path('../environments/rails-3.1/config/environment', File.dirname(__FILE__))
    
    at_exit do
      # You ready for this? At rails/application/bootstrap.rb:40 an at_exit handler is registered,
      # which flushes the log. But for some reason it's failing, saying Rails is undefined. This
      # hack is the only way I've found to silence the error and let the process exit with code 0.
      module Rails
        def self.logger
          nil
        end
      end
    end
    
  end
rescue LoadError
  # if we're in a pure ruby environment, that's OK
  unless $!.message['rails/version']
    raise $!
  end
end
