
COMMANDS = {}
EXTENSIONS = {}
def add_extensions(command, arguments, extensions, source)
  COMMANDS[command] = { :arguments => arguments, :extensions => [], :source => source }
  extensions.each do |extension|
    EXTENSIONS[extension] = command
  end
end

require_relative 'extensions.rb'

COMMANDS["ag"] = { :extensions => [], :source => "Download source from https://github.com/ggreer/the_silver_searcher and then follow the build instructions in the README.md document." }

EXTENSIONS.each_pair do |extension, command|
  COMMANDS[command][:extensions] << extension
end


f = <<-EOF
function btags_check_commands() {
  FAILED=0

EOF

COMMANDS.each_pair do |command, options|
  f << <<-EOF
  if [ "$(which "#{command}")" = "" ]; then
    echo "Cannot find '#{command}'. Either the command is not in your PATH, or the command isn't installed. To install '#{command}': #{options[:source]}"
    FAILED=1
  fi

EOF
end

COMMANDS.delete_if { |command, options| options[:extensions].empty? }

f << <<-EOF
  if [ "$FAILED" = "1" ]; then
    exit 1
  fi
}

function btags_clean() {
  rm -r "$TAGSDIR"/*
}

function btags_generate() {
  cd "$SRCDIR"

EOF

COMMANDS.each_pair do |command, options|
  regex = "'^(#{options[:extensions].map { |e| e.gsub(".", "\\.").gsub("%", ".*") }.join("|")})$'"
  f << <<-EOF
  ag --search-files --nocolor -g #{regex} > "$TAGSDIR/#{command}.files"
  while read file; do
    if [ "$file" -nt "$TAGSDIR/$file.tags" ]; then
      echo "$file"
    fi
  done < "$TAGSDIR/#{command}.files" > "$TAGSDIR/#{command}.changed.files"

EOF
end

f << <<-EOF
  if [ #{COMMANDS.keys.map { |c| "! -s \"$TAGSDIR/#{c}.changed.files\"" }.join(" -a ")} ]; then
    return 0
  fi

EOF

COMMANDS.each_pair do |command, options|
  f << <<-EOF
  parallel mkdir -p "$TAGSDIR"/{//} "&&" "#{command} #{options[:arguments]}" {} ">" "$TAGSDIR"/{}.tags "2>/dev/null" "&&" echo -n "." < "$TAGSDIR/#{command}.changed.files"

EOF
end

f << <<-EOF
  cat "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.files | sed 's/^.*$/& path 1 & path/g' > "$TAGSDIR/files.tags"

  while read file; do
    cat "$TAGSDIR/$file.tags"
  done < <(cat "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.files) > "$TAGSDIR/tags.tags"

  cat "$TAGSDIR/files.tags" >> "$TAGSDIR/tags.tags"

  rm "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.files "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.changed.files
}

EOF

btags = File.read("btags")
btags.gsub!(/\n#Start btags functions\n.*#End btags functions\n/m, "\n#Start btags functions\n#{f}#End btags functions\n")
File.open("btags", "w") { |w| w << btags }

