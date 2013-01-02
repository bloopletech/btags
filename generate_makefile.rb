
COMMANDS = {}
EXTENSIONS = {}
def add_extensions(command, arguments, extensions, source)
  COMMANDS[command] = { :arguments => arguments, :source => source }
  extensions.each do |extension|
    EXTENSIONS[extension] = command
  end
end

require_relative 'extensions.rb'

COMMANDS["ag"] = { :source => "Download source from https://github.com/ggreer/the_silver_searcher and then follow the build instructions in the README.md document." }

f = File.new("Makefile", "w")

EXTENSIONS.each_pair do |extension, command|
  f << "vpath #{extension} $(srcdir)\n"
end

f << <<-EOF

tags.tags : $(addsuffix .tags,$(shell cd $(srcdir) && ag --search-files --nocolor -g '.*'))
\techo '$^' | tr ' ' "\\n" | sed 's/^\\(.*\\)\\.tags$$/\\1 1 \\1 path/g' > files.tags
\tcat $^ files.tags | sed '/^$$/d' > tags.tags

clean : 
\trm -r ./*

.PHONY : clean

check_commands : 
EOF

COMMANDS.each_pair do |command, attributes|
  f << <<-EOE3
\tif [ "$$(which "#{command}")" = "" ]; then \\
\techo "Cannot find '#{command}'. Either the command is not in your PATH, or the command isn't installed. To install '#{command}': #{attributes[:source]}" && exit 1; fi
EOE3
end

f << <<-EOF2

.PHONY : check_commands

.DEFAULT : 
	mkdir -p $(<D) && touch $<

EOF2

EXTENSIONS.each_pair do |extension, command|
  f << <<-EOE2
#{extension}.tags : #{extension}
\tmkdir -p $(@D) && #{command} #{COMMANDS[command][:arguments]} $< > $@

EOE2
end

f.close

