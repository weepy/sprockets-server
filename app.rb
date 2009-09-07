require 'rubygems'
require 'sinatra'
require 'sprockets'
require 'hpricot'
require 'settings'
require 'find'

LOAD_PATHS = Settings[:paths].map {|p| File.expand_path(p) }

get /^\/$|\/\?(.+)/ do
  
  search = request.fullpath.split("?")[1]

  html = "<style>body {font-family: arial; sans; color: black; line-height: 1.5em} a {color: gray; text-decoration: none; } a:hover {background: black; color: white} li {list-style: none;}</style>"
  html += search ? "<h2>Sprocket Tests containing '#{search}'</h2>" : "<h2>All Sprocket Tests</h2>"
  
  LOAD_PATHS.each do |path|
    files = []
    html += "<h3>#{path}</h3>"
    Find.find(path) do |f|
      next if search && !f.match(search) 
      files << f if f.match /.html$/
    end
    
  
    html += "<ul>"
    files.each do |f|
      l = f.gsub(path, "")
      html += "<li><a href='#{l}'>#{l.gsub("/", " : ")}</a></li>"
    end
    html += "</ul>"
  end

  html
end


get '/*/*.html' do
  time = Time.now
  url = request.fullpath.split("?")[0]
  search = url.split("?")[1]
  
  file, root, full_path = find_file(url)
  
  doc = Hpricot(open(full_path))
  script = find_script_with_require(doc)
  
  load_paths = LOAD_PATHS.map {|p| [ "#{p}/**",  "#{p}/**/**"]}.flatten
  
  if script 
    
    File.open("#{root}/#{Settings[:cache]}", "w") {|f| f.write(script[0].innerText)}
    secretary = Sprockets::Secretary.new :root => root, :load_path => load_paths, :source_files => [Settings[:cache]]
    to_load = []

    secretary.preprocessor.source_files.each do |source_file|
      to_load << source_file.pathname.to_s if source_file.contains_source?
    end
        
    to_load = to_load.map do |s| 
      LOAD_PATHS.each { |ss| s.gsub!(ss,"") }
      s
    end
  
    to_load = to_load.map {|m| "<script src='#{m}'></script>"}
    new_scripts = to_load.length > 0 ? to_load.join("\n") : "<script></script>"

    #script.remove
    script.after(new_scripts)
  end

  doc.to_html 
end

get '*/*' do
  content_type 'text/js'
  url = request.fullpath
  file, full_path, root = find_file(url)
  
  file
end

def find_file url

  LOAD_PATHS.each do |path|
    full_path = "#{path}#{url}"
    root = File.dirname(full_path)
    file = nil
    
    begin
      f = File.new(full_path)
      file = f.readlines
      f.close
    rescue
    end
    
    return file, root, full_path unless(file == nil || file.length == 0)

  end
  raise "didn't find file: #{url}"
end


module Sprockets
  class SourceFile
    def contains_source?
      each_source_line do |line|
        return true if !line.comment? && line.line.strip != ""
      end
      false
    end
  end
end


def find_script_with_require(doc)
  scripts = doc / "script"
  i = 0
  scripts.each do |script|
    script.innerText.split("\n").each do |line|
      if line.strip.match(/^\/\/=/)
        return doc / "script:nth-of-type(#{i})"  
      end
    end
    i+=1
  end
  nil
end






