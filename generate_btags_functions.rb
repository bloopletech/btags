
COMMANDS = {}
EXTENSIONS = {}
def add_extensions(command, arguments, extensions, source)
  COMMANDS[command] = { :arguments => arguments, :extensions => [], :source => source }
  extensions.each do |extension|
    EXTENSIONS[extension] = command
  end
end

require_relative 'extensions.rb'

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

function btags_generate() {
  cd "$SRCDIR"

  grep -r -l -I "^" | grep -v -E '(^\\.|/\\.)' > "$TAGSDIR/files"

EOF

COMMANDS.each_pair do |command, options|
  regex = "'^(#{options[:extensions].map { |e| e.gsub(".", "\\.").gsub("%", ".*") }.join("|")})$'"
  f << <<-EOF
  grep -E --color=never #{regex} "$TAGSDIR/files" > "$TAGSDIR/#{command}.files"
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

  ESCAPEDTAGSDIR="$(printf '%q' "$TAGSDIR")"

EOF

COMMANDS.each_pair do |command, options|
  f << <<-EOF
  parallel --gnu mkdir -p "$ESCAPEDTAGSDIR"/{//} "2>/dev/null" "&&" "#{command} #{options[:arguments]}" {} ">" "$ESCAPEDTAGSDIR"/{}.tags "2>/dev/null" "&&" echo -n "." < "$TAGSDIR/#{command}.changed.files"

EOF
end

f << <<-EOF
  while read file; do
    cat "$TAGSDIR/$file.tags"
  done < <(cat "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.files) > "$TAGSDIR/tags.tags"

  sed -e 's/^\\([^ ]\\+\\) \\+\\([A-Za-z ]\\+\\) \\+\\([0-9]\\+\\) \\+\\([^ ]\\+\\).*$/\\1\\t\\4\\t\\3/' -e '/^$/d' -e 's/\\x00/ /g' < "$TAGSDIR/tags.tags" > "$TAGSDIR/tags.vimtags"

  sed -e 's/ /\\x00/g' -e 's/^.*$/& path 1 & path/g' < "$TAGSDIR/files" >> "$TAGSDIR/tags.tags"

  sed -i -e '/^$/d' "$TAGSDIR/tags.tags"

  rm "$TAGSDIR/files" "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.files "$TAGSDIR"/{#{COMMANDS.keys.join(",")}}.changed.files
}

EOF

btags = File.read("btags")
btags.gsub!(/\n#Start btags dynamic functions\n.*#End btags dynamic functions\n/m, "\n#Start btags dynamic functions\n#{f.gsub('\\', '\\\\\\')}#End btags dynamic functions\n")
File.open("btags", "w") { |w| w << btags }

