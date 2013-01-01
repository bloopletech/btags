
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
COMMANDS["perl"] = { :source => "Your system should already have this; try sudo apt-get install perl or similar. See also http://www.perl.org/." }
COMMANDS["sed"] = { :source => "Your system should already have this; try sudo apt-get install sed or similar. See also http://www.gnu.org/software/sed/." }


f = File.new("Makefile", "w")

EXTENSIONS.each_pair do |extension, command|
  f << "vpath #{extension} $(srcdir)\n"
end

f << <<-EOF

btags : files.list files.tags files.mak tags.tags 

.PHONY : btags

files.tags : files.list
\tperl -pe 's/^(.*)$$/\\1\\tpath\\t\\1\\t1/g' < $< > $@

files.list : 
\tcd $(srcdir) && ag --search-files --nocolor --ignore '*.tags' -L '.{1000,}' | xclude_long_files > $(abspath $@)

files.mak : files.list
\tperl -pe 's/^(.*\\/)?(.*)$$/tags.tags : \\1 \\1\\2.tags\\n/g' < $< > $@
\tperl -pe 's/^(.*\\/)?(.*)$$/\\1/g' < $< | sed '/^$$/d' | sort -u | perl -pe 's/^(.*)$$/\\1 : \\n\\tmkdir -p \\$$@\\n/g' >> $@

.DEFAULT : 
	touch $<

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

EOF2

EXTENSIONS.each_pair do |extension, command|
  f << <<-EOE2
#{extension}.tags : #{extension}
\t#{command} #{COMMANDS[command][:arguments]} $< | perl -pe 's/^([^ ]+) +(\\d+) +([^ ]+?) +(.+?)$$/\\1\\t\\4\\t\\3\\t\\2/g' > $@

EOE2
end

f << <<-EOF3
tags.tags : files.tags
	cat $(filter %.tags,$^) | sed '/^$$/d' > tags.tags

ifeq ($(MAKECMDGOALS),btags)
-include files.mak
endif
EOF3

f.close

