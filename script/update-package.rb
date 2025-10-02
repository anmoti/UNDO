require 'uri'
require 'json'
require 'net/http'
require 'open-uri'
require 'fileutils'

dir = "vendor/javascript"

package = ARGV[0]
specified_version = ARGV[1]

if package.nil? || package.empty?
  puts "Usage: ruby update-package.rb <package-name> [version]"
  puts "If version is not specified, the latest version will be used."
  exit 1
end

puts "Fetching info for '#{package}'..."
uri = URI.parse("https://registry.npmjs.org/#{package}")

response = Net::HTTP.get_response(uri)
if response.code != "200"
  puts "Error: Failed to fetch package info for '#{package}' (HTTP #{response.code})"
  exit 1
end

data = JSON.parse(response.body)

# 引数でバージョンが指定されていればそれを使い、なければ 'latest' タグのバージョンを使う
version = specified_version || data["dist-tags"]["latest"]

tgz_url = data["versions"][version]["dist"]["tarball"]
tgz_filename = File.basename(tgz_url)
tgz_path = File.join(dir, tgz_filename)
package_tmp_dir = File.join(dir, "package")
destination_dir = File.join(dir, package)

puts "Downloading #{package}@#{version} from #{tgz_url}..."
File.open(tgz_path, "wb") do |file|
  # 大きなファイルでもメモリを使いすぎないようにストリームで書き込む
  URI.open(tgz_url) do |stream|
    file.write(stream.read)
  end
end

puts "Extracting #{tgz_filename}..."
system("tar -xzf #{tgz_path} -C #{dir}")

puts "Moving files to #{destination_dir}..."
FileUtils.mkdir_p(destination_dir)
Dir.glob(File.join(package_tmp_dir, "*")).each do |file|
  FileUtils.mv(file, destination_dir, force: true) # 既存のファイルを上書き
end

puts "Cleaning up..."
FileUtils.rm(tgz_path)
FileUtils.rm_rf(package_tmp_dir)

puts "✅ Done! Package #{package} (version: #{version}) was successfully installed."
