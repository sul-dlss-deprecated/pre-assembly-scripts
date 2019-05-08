require 'find'
require 'digest/md5'

content_dir = ARGV[0]
digest_list = ARGV[1]

find_hash = {}
digest_hash = {}

checked = 0
valid = []
errors = []
missing = []

Find.find(content_dir) do |element|
  next if File.directory?(element)
  basename = File.basename(element)
  find_hash.merge! basename => element
end

File.readlines(digest_list).map do |line| 
  line.chomp!
  line.gsub!(/, /, ',')
  values = line.split(',')
  digest_hash.merge! values.at(1) => { 'md5' => values.at(2),
                                       'sha1' => values.at(3),
                                       'sha256' => values.at(4),
                                       'size' => values.at(5) }
end

digest_hash.each_key do |key|
  file_path = find_hash[key]
  file_digest_md5 = File.exists?(file_path) ? Digest::MD5.hexdigest(File.read(file_path)) : nil

  if digest_hash[key]['md5'].eql?(file_digest_md5)
    puts "OK: #{file_path}"
    valid.push(file_path)
  elsif file_digest_md5.nil?
    puts "MISSING: #{file_path}"
    missing.push(file_path)
  else
    puts "ERROR: #{file_path}"
    errors.push(file_path)
  end
end

puts ""
puts "File Counts, Filesystem: #{find_hash.size}, Digest List: #{digest_hash.size}"
puts "Results, OK: #{valid.size}, FAIL: #{errors.size}, MISSING: #{missing.size}"
puts "Not in Digest List: #{digest_hash.size - (valid.size + errors.size + missing.size)}"

