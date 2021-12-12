# load libraries
require 'rubygems'
begin
  require 'wirble'
  require 'utility_belt'

  # start wirble (with color)
  Wirble.init
  Wirble.colorize
rescue Exception
  puts "Install wirble and utility_belt for added features"
end

# set simple prompt mode
IRB.conf[:PROMPT_MODE] = :SIMPLE

if defined?(RUBY_DESCRIPTION)
 puts "# #{RUBY_DESCRIPTION}"
else
 puts "# ruby #{RUBY_VERSION}"
end

def cls
  system 'clear'
end

# Activate auto-completion.
require 'irb/completion'

# Add helper method to Object
module LocalMethods
  def local_methods
    self.methods.sort - Object.methods
  end
end

Object.class_eval { include LocalMethods }
