require 'digest/md5'
require 'find'
require 'optparse'
require 'pp'

@local_files   = {}
@checksum_data = {}

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby verify_checksum.rb -f checksum_file.csv -p some/path/to/content\n" +
                "       ruby verify_checksum.rb -f checksum_file.csv -p some/path/to/content --delete\n"

  opts.on('-p', '--path PATH', 'Root path for files') do |v|
    options[:path] = v
  end
  opts.on('-f', '--file FILENAME', 'Verify checksums from FILENAME') do |v|
    options[:checksum_file] = v
  end
  opts.on('-d', '--delete', 'Delete files as they are verified') do |v|
    options[:delete] = v
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  if opts.default_argv.empty?
    puts opts
    exit
  end
end.parse!

# Some sanity checking
begin
  raise 'Neet to specify both checksum file and file path.' if options[:checksum_file].nil? || options[:path].nil?
  raise "Checksum file #{options[:checksum_file]} does not exist." unless File.exist?(options[:checksum_file])
  raise "File path #{options[:path]} does not exist." unless File.exist?(options[:path])
rescue StandardError => e
  puts e
  exit
end

def get_local_files(path)
  local_files = {}
  Find.find(path) do |element|
    next if File.directory?(element)

    # Get filename from file path
    basename = File.basename(element)

    # There can be multiple files with the same name.
    # Store files paths in array in a hash with file name as key.
    if local_files.key?(basename)
      local_files[basename].push(element)
    else
      local_files[basename] = [element]
    end
  end
  local_files
end

def read_checksum_file(checksum_file)
  checksums = []
  File.readlines(checksum_file).map do |line|
    line.chomp!
    values = line.split(', ')
    info   = { 'druid'     => values.at(0),
               'file_name' => values.at(1),
               'md5'       => values.at(2),
               'sha1'      => values.at(3),
               'sha256'    => values.at(4),
               'size'      => values.at(5) }

     checksums.push(info)
  end
  checksums
end

# Do not delete unless delete flag is explicitly defined
delete        = !options[:delete].nil?

content_dir   = options[:path]
checksum_file = options[:checksum_file]

# Store some statistics
# checked = 0
valid   = []
errors  = []
missing = []

print "Getting list of files from: #{content_dir}.. "
local_files = get_local_files(content_dir)
print "Found: #{local_files.size}\n"

print "Getting list of checksums from: #{checksum_file}.. "
checksums = read_checksum_file(checksum_file)
print "Found: #{checksums.size}\n"

puts 'Verifying checksums:'
checksums.each_with_index do |checksum_info, index|
  # Check to see if file is in the checksum file, but not in the filesystem.
  if local_files[checksum_info['file_name']].nil?
    # puts "MISSING: #{file}"
    missing.push("#{checksum_info['druid']}:#{checksum_info['file_name']}")
    next
  end

  matched      = false
  matched_file = ''
  local_files[checksum_info['file_name']].each do |local_file|
    local_file_md5 = Digest::MD5.hexdigest(File.read(local_file))

    # Useful for debugging
    # puts "\nlocalfile: " + local_file_md5
    # puts "cehcksum:  " + checksum_info['md5']

    if checksum_info['md5'].eql?(local_file_md5)
      matched_file = local_file
      matched = true
      break
    end
  end

  if matched
    print "\r" + "\e[2K"
    print "(#{index + 1} of #{checksums.size}) OK: #{matched_file}"
    valid.push(matched_file)
    print ' ...unlinking' if delete
    STDOUT.flush
    File.unlink(matched_file) if delete && File.exist?(matched_file)

  else
    print "\nERROR: #{checksum_info['druid']}:#{checksum_info['file_name']} -- No Match"
    errors.push("#{checksum_info['druid']}:#{checksum_info['file_name']}")

  end
end

puts ''
puts ''
puts "Filesystem: #{local_files.size}, Digest List: #{checksums.size}"
puts 'Results:'
puts "OK:      #{valid.size}"
puts "FAIL:    #{errors.size}"
puts "MISSING: #{missing.size}"
puts "Not in Digest List: #{local_files.size - (valid.size + errors.size)}"
