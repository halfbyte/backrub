# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'backrub'

task :default => 'test'

PROJ.name = 'backrub'
PROJ.authors = "Jan 'half/byte' Krutisch"
PROJ.email = 'jan@krutisch.de'
PROJ.url = 'http://halfbyte.github.com/backrub'
PROJ.version = Backrub::VERSION
PROJ.rubyforge.name = 'backrub'

PROJ.spec.opts << '--color'

# EOF
