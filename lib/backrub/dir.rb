class Dir
  def self.list(directory, options = {})
    directory = File.expand_path(directory)
    valid_options = {
      :exclude => ['.', '..'],
      :directories_only => true
    }.merge(options)
    
    directories = []  
    self.foreach(directory) do |d|
      if ( ( (valid_options[:directories_only] && File.directory?(File.join(directory, d))) || (!valid_options[:directories_only]) ) && !valid_options[:exclude].include?(d) )
        directories << d
      end   
    end
    directories
  end
end
