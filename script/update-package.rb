require 'uri'
require 'json'
require 'net/http'
require 'open-uri'

dir = "vendor/javascript"
uri = URI.parse("https://registry.npmjs.org/")
package = ARGV[0]

if package.nil? || package.empty?
  puts "Usage: ruby update-package.rb <package-name>"
  exit 1
end

uri.path = File.join(uri.path, package)

response = Net::HTTP.get_response(uri)
if response.code != "200"
  puts "Error: Failed to fetch package info (HTTP #{response.code})"
  exit 1
end

data = JSON.parse(response.body)
version = data["dist-tags"]["latest"]
tgz_url = data["versions"][version]["dist"]["tarball"]

tgz_filename = File.basename(tgz_url)
puts "Downloading #{tgz_filename}..."
File.open(File.join(dir, tgz_filename), "wb") do |file|
  file.write(URI.open(tgz_url).read)
end

puts "Extracting #{tgz_filename}..."
system("tar -xzf #{File.join(dir, tgz_filename)} -C #{dir}")

puts "Moving files to #{File.join(dir, package)}..."
FileUtils.mkdir_p(File.join(dir, package))
Dir.glob(File.join(dir, "package/*")).each do |file|
  FileUtils.mv(file, File.join(dir, package))
end

puts "Cleaning up..."
FileUtils.rm(File.join(dir, tgz_filename))
FileUtils.rm_rf(File.join(dir, "package"))

puts "Done! Package #{package} (#{version}) updated successfully."
