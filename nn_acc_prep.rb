require 'fileutils'

evis_name     = ARGV.first
evis_content  = "#{evis_name}_content"
evis_register = "#{evis_name}_register.txt"

if evis_name.nil?
  puts 'usage: ruby evis_acc_prep.rb path'
  exit
end

# Create file-level directories.
# We're using glob with the './' prefix and then removing it
#   to prevent searchhing '/' if evis_name ends up being a nil.
dirs = Dir.glob("./#{evis_name}/*/*/*")
dirs.map! { |e| e.match(%r{^.\/}) ? e.gsub!('./', '') : e }

# Create _content directory.
FileUtils.mkdir(evis_content) unless File.directory?(evis_content)

dirs.each do |dir|
  target = dir.split('/').to_a[1..3].join('-')
  next if File.exist?(target)

  # Create the symlinks to each object instead of creating copies.
  # Equivalent of "ln -s ../mone/1960/07/06_01 mone_content/1960-07-06_01"
  FileUtils.ln_s("../#{dir}", "#{evis_content}/#{target}")

  # Append new object to register.txt.
  message = "\tevis:#{evis_name}-#{target}\t\t#{target}\n"
  File.open(evis_register, 'a') { |file| file.write(message) }
end
