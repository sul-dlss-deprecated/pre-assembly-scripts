# Checksum verification script. Verificaton is intended to detect against
# errors in file transfers and/or other unintended bit changes. MD5 checksums
# are used because of their low computational overhead.
#
# Run as 'ruby verify_checksum.rb -h' to see syntax of options.
#
# This script is intended for verification and deletion of content using the
# checksum files where # each line has the following syntax:
# "druid:[druid], [filename], [md5], [sha1], [sha256], [file_size]"
#
# Since the checksum files do not contain the original directory strucutre,
# duplicate file names are ignored by default.

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
  opts.on('-u', '--duplicates', 'Attempt to delete duplicates.') do |v|
    options[:duplicates] = v
  end
  opts.on('-o', '--output FILENAME', 'Print results to csv at FILENAME.') do |v|
    options[:output] = v
  end
  opts.on('-v', '--verbose', 'Print all results to terminal.') do |v|
    options[:verbose] = v
  end
  opts.on('-q', '--quiet', 'Do not output to terminal.') do |v|
    options[:quiet] = v
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

# Some sanity checking on input.
begin
  if options[:checksum_file].nil? || options[:path].nil?
    raise 'Neet to specify both checksum file and file path.'
  end
  unless File.exist?(options[:checksum_file])
    raise "Checksum file #{options[:checksum_file]} does not exist."
  end
  unless File.exist?(options[:path])
    raise "File path #{options[:path]} does not exist."
  end
rescue StandardError => e
  puts e
  exit
end

# Find all local files and store them in Hash.
def get_local_files(path)
  local_files = {}
  Find.find(path) do |element|
    next if File.directory?(element)

    # Get filename from file path
    basename = File.basename(element)

    # There can be multiple files with the same name.
    # Store files paths in array in a hash with file name as key.
    # hash will look like:
    # { 'some_local_file.txt' => ['relative/path/to/some_local_file.txt',
    #                             'relative/path/to/different/some_local_file.txt']
    if local_files.key?(basename)
      local_files[basename].push(element)
    else
      local_files[basename] = [element]
    end
  end
  local_files
end

# Read DOR checksum file and put values into Hash.
def read_checksum_file(checksum_file)
  checksums = []
  File.readlines(checksum_file).map do |line|
    line.chomp!
    values = line.split(', ')

    info = { 'druid'     => values.at(0),
             'file_name' => values.at(1),
             'md5'       => values.at(2),
             'sha1'      => values.at(3),
             'sha256'    => values.at(4),
             'size'      => values.at(5) }

    checksums.push(info)
  end
  checksums
end

# Instantiate option variables
quiet           = !options[:quiet].nil?
verbose         = !options[:verbose].nil?
delete          = !options[:delete].nil?
output          = !options[:output].nil?
output_file     = options[:output]
skip_duplicates = options[:duplicates].nil?
content_dir     = options[:path]
checksum_file   = options[:checksum_file]

# Store some statistics
valid      = []
errors     = []
missing    = []
duplicates = []
log        = nil

if output
  begin
    log = open(output_file, 'a')
  rescue StandardError => e
    puts e
    exit
  end
end

print "Getting list of files from: #{content_dir}.. " unless quiet
local_files = get_local_files(content_dir)
print "Found: #{local_files.size}\n" unless quiet

print "Getting list of checksums from: #{checksum_file}.. " unless quiet
checksums = read_checksum_file(checksum_file)
print "Found: #{checksums.size}\n" unless quiet

puts 'Verifying checksums:' unless quiet
checksums.each_with_index do |checksum_info, index|

  # Check to see if file is in the checksum manifest, but not in the filesystem.
  if local_files[checksum_info['file_name']].nil?
    missing.push("#{checksum_info['druid']}:#{checksum_info['file_name']}")

    message = "#{checksum_info['druid']},#{checksum_info['file_name']},NOT_FOUND"
    puts "#{index + 1} of #{checksums.size},#{message}" if verbose
    log.puts message if output
    next
  end

  # Check to see if there are duplicates of filename on filesystem.
  # Checksum manifest is only at the file-level, skip by default until 
  # error handling can be improved. You can bypass this by using
  # the --duplicates command-line option.
  if local_files[checksum_info['file_name']].size >= 2 && skip_duplicates
    duplicates.push("#{checksum_info['druid']}:#{checksum_info['file_name']}")

    message = "#{checksum_info['druid']},#{checksum_info['file_name']},SKIP_DUPLICATE"
    puts "#{index + 1} of #{checksums.size},#{message}" if verbose
    log.puts message if output
    next
  end

  # Attempt to find a local file that matches the checksum in the digest manifest.
  matched      = false
  matched_file = ''
  local_files[checksum_info['file_name']].each do |local_file|
    next unless File.exist?(local_file)

    local_file_md5 = Digest::MD5.hexdigest(File.read(local_file))
    next unless checksum_info['md5'].eql?(local_file_md5)

    matched = true
    matched_file = local_file
    break
  end

  if matched
    valid.push(matched_file)
    File.unlink(matched_file) if delete && File.exist?(matched_file)

    message = "#{checksum_info['druid']},#{checksum_info['file_name']},OK"
    message += ',DELETED' if delete

    puts "#{index + 1} of #{checksums.size},#{message}" if verbose
    log.puts message if output
    # The "\r\e[2K" in the print will return to beginning of line (\r)
    # and will clear the rest of the line (\e[2K)
    print "\r\e[2K" + "(#{index + 1} of #{checksums.size}): #{message}" if !quiet && !verbose
    print ' ...unlinking' if delete && !quiet && !verbose
    STDOUT.flush

  else
    errors.push("#{checksum_info['druid']}:#{checksum_info['file_name']}")

    message = "#{checksum_info['druid']},#{checksum_info['file_name']},ERROR"
    puts "#{index + 1} of #{checksums.size},#{message}" if verbose
    log.puts message if output

  end
end

# A brief summary of the results.
unless quiet
  puts "\n\nSummary:"
  puts ''
  puts "Filesystem : #{local_files.size}"
  puts "Digest List: #{checksums.size}"
  puts 'Results:'
  puts "OK  :       #{valid.size}"
  puts "FAIL:       #{errors.size}"
  puts "DUPLICATES: #{duplicates.size}" 
  puts ''
  puts "Not on disk       : #{missing.size}"
  puts "Not in digest list: #{local_files.size - (valid.size + errors.size + duplicates.size)}"
end

