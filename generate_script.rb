
COMMANDS = {}
EXTENSIONS = {}
def add_extensions(command, arguments, extensions, source)
  COMMANDS[command] = { :arguments => arguments, :extensions => [], :source => source }
  extensions.each do |extension|
    EXTENSIONS[extension.gsub("%", "*")] = command
  end
end

require_relative 'extensions.rb'

#COMMANDS["ag"] = { :source => "Download source from https://github.com/ggreer/the_silver_searcher and then follow the build instructions in the README.md document." }

EXTENSIONS.each_pair do |extension, command|
  COMMANDS[command][:extensions] << extension
end


f = File.new("btags_core", "w")

f << <<-EOF
#!/bin/bash

shopt -s globstar
shopt -s nullglob

cd "$SRCDIR"

for file in **/; do
  mkdir -p "$TAGSDIR/$file"
done

EOF

COMMANDS.keys.each do |command|
  f << <<-EOF2
if [ -e "$TAGSDIR/#{command}.files" ]; then
  rm "$TAGSDIR/#{command}.files"
fi
touch "$TAGSDIR/#{command}.files"

EOF2
end

COMMANDS.each_pair do |command, options|
  f << <<-EOF3
for file in **/{#{options[:extensions].join(",")}}; do
  if [ ! -e "$TAGSDIR/$file.tags" ]; then
    echo "$file"
  elif [ "$file" -nt "$TAGSDIR/$file.tags" ]; then
    echo "$file"
  fi
done > "$TAGSDIR/#{command}.files"

EOF3
end

COMMANDS.each_pair do |command, options|
  f << <<-EOF4
parallel --verbose "#{"#{command} #{options[:arguments]} {} > \"$TAGSDIR/{}.tags\"".gsub('"', '\\"')}" < "$TAGSDIR/#{command}.files"

EOF4
end

=begin
  #{command} #{COMMANDS[command][:arguments]} "$file" > '$@' #{show_progress}
  f << "vpath #{extension} $(srcdir)\n"
end

show_progress = "; echo -n '.'"

f << <<-EOF

tags.tags : $(addsuffix .tags,$(shell cd $(srcdir) && ag --search-files --nocolor -g '.*'))
\techo '$^' | tr ' ' "\\n" | sed 's/^\\(.*\\)\\.tags$$/\\1 path 1 \\1 path/g' > files.tags #{show_progress}
\tcat $(addprefix ',$addsuffix ',$^)) files.tags | sed '/^$$/d' > tags.tags #{show_progress}

clean : 
\trm -r ./* #{show_progress}

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
	mkdir -p '$(<D)' && touch '$<'

EOF2

EXTENSIONS.each_pair do |extension, command|
  f << <<-EOE2
#{extension}.tags : #{extension}
\tmkdir -p '$(@D)' && #{command} #{COMMANDS[command][:arguments]} '$<' > '$@' #{show_progress}

EOE2
end

f.close
=end
