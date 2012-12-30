
EXTENSIONS = {}
def add_extensions(exts, tool)
  exts.each do |extension|
    EXTENSIONS[extension] = tool
  end
end


require_relative 'extensions.rb'


def exts_file_var(extension)
  "tags_#{extension.gsub(/[^\w]/, "_")}"
end

f = File.new("Makefile", "w")
f << <<-EOF

tags : tags.tags

EOF


EXTENSIONS.each_pair do |extension, tool|
  f << <<-EOE
#{exts_file_var extension} := $(addsuffix .tags,$(shell find . -name '#{extension.sub("%", "*")}'))

$(info $(#{exts_file_var extension}))

#{extension}.tags : #{extension}
\t#{tool} $< > $<.tags

EOE
end

tags_sources_vars = EXTENSIONS.keys.map do |extension|
  "$(#{exts_file_var extension})"
end.join(" ")

f << <<-EOF2
tags.tags : #{tags_sources_vars}
\tcat $^ > tags.tags

EOF2

f.close

