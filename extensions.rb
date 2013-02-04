def etags_file_extensions
  lines = `etags --list-maps`.split("\n").map { |line| line.split }
  lines.each { |line| line.shift }
  lines.each do |types|
    types.map! do |type|
      `exrex.py '#{type.gsub("+", "\\+").gsub(".", "\\.").gsub(/^\*/, '')}'`.split("\n")
    end
  end
  extensions = lines.flatten
  extensions.each do |extension|
    extension.insert(0, "%") if extension[0, 1] == "."
  end
  extensions
end

def rtags_file_extensions
  ["%.rb", "%.rake", "%.ru", "Gemfile", "Guardfile", "Procfile", "Rakefile"]
end

#Add extensions, starting with least specific and moving to more specific
add_extensions("ctags", "-xu", etags_file_extensions, "sudo apt-get install ctags or similar; see also http://ctags.sourceforge.net.")
add_extensions("rtags", "-x -B", rtags_file_extensions, "gem install bloopletech-rtags; see also https://github.com/bloopletech/rtags.")

