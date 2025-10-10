require "uri"
require "json"
require "net/http"
require "open-uri"
require "fileutils"

namespace :npm do
  desc "Update or install an npm package to vendor/javascript\nUsage: rake npm:update[package-name,version]\nIf version is not specified, the latest version will be used."
  task :update, [ :package, :version ] => :environment do |_t, args|
    package = args[:package]
    version = args[:version]

    # ヘルプ表示
    if package == "-h" || package == "--help" || package == "help" || package.nil? || package.empty?
      show_update_help
      exit 0
    end

    vendor_dir = Rails.root.join("vendor", "javascript")
    FileUtils.mkdir_p(vendor_dir) unless Dir.exist?(vendor_dir)

    package_info = fetch_package_info(package)
    return unless package_info

    version_to_install = version || package_info["dist-tags"]["latest"]

    unless package_info["versions"].key?(version_to_install)
      puts "Error: Version '#{version_to_install}' not found for package '#{package}'"
      puts "Available versions: #{package_info["versions"].keys.sort.join(', ')}"
      exit 1
    end

    install_package(package, version_to_install, package_info["versions"][version_to_install], vendor_dir)
  end

  desc "List all installed packages in vendor/javascript"
  task :list do
    vendor_dir = Rails.root.join("vendor", "javascript")

    unless Dir.exist?(vendor_dir)
      puts "No packages installed (vendor/javascript directory not found)"
      exit 0
    end

    packages = Dir.glob(vendor_dir.join("*")).select { |f| File.directory?(f) }

    if packages.empty?
      puts "No packages installed in vendor/javascript"
    else
      puts "Installed packages in vendor/javascript:"
      packages.each do |pkg_path|
        package_name = File.basename(pkg_path)
        package_json = File.join(pkg_path, "package.json")

        if File.exist?(package_json)
          data = JSON.parse(File.read(package_json))
          puts "  - #{data['name']} (#{data['version']})"
        else
          puts "  - #{package_name} (version unknown)"
        end
      end
    end
  end

  desc "Show help for npm tasks"
  task :help do
    show_general_help
  end

  private

  def show_general_help
    puts <<~HELP
      📦 NPM Package Manager for Rails

      Available tasks:
        rake npm:update[package,version]  - Install or update an npm package
        rake npm:list                     - List all installed packages
        rake npm:help                     - Show this help message

      Examples:
        # Install the latest version of a package
        rake npm:update[@hotwired/stimulus]

        # Install a specific version
        rake npm:update[@hotwired/stimulus,3.2.2]

        # Show help for update task
        rake npm:update[-h]

        # List installed packages
        rake npm:list

      Package location:
        Packages are installed to vendor/javascript/

      For more information about a specific task, use:
        rake -D npm
    HELP
  end

  def show_update_help
    puts <<~HELP
      📦 NPM Package Updater

      Usage:
        rake npm:update[package-name,version]

      Arguments:
        package-name  - The npm package name (required)
                       Example: @hotwired/stimulus, lodash
        version       - Package version (optional)
                       If not specified, the latest version will be installed

      Options:
        -h, --help   - Show this help message

      Examples:
        # Install the latest version
        rake npm:update[@hotwired/stimulus]

        # Install a specific version
        rake npm:update[@hotwired/stimulus,3.2.2]
        rake npm:update[lodash,4.17.21]

        # Install scoped packages
        rake npm:update[@popperjs/core,2.11.8]

      Notes:
        - Packages are downloaded from the npm registry
        - Files are extracted to vendor/javascript/<package-name>/
        - Existing versions will be overwritten

      See also:
        rake npm:list  - List all installed packages
        rake npm:help  - Show general help
    HELP
  end


  def fetch_package_info(package)
    puts "Fetching info for '#{package}'..."
    uri = URI.parse("https://registry.npmjs.org/#{package}")

    response = Net::HTTP.get_response(uri)

    unless response.code == "200"
      puts "Error: Failed to fetch package info for '#{package}' (HTTP #{response.code})"
      return nil
    end

    JSON.parse(response.body)
  rescue StandardError => e
    puts "Error: Failed to fetch package info: #{e.message}"
    nil
  end

  def install_package(package, version, version_data, vendor_dir)
    tgz_url = version_data["dist"]["tarball"]
    tgz_filename = File.basename(tgz_url)
    tgz_path = vendor_dir.join(tgz_filename)
    package_tmp_dir = vendor_dir.join("package")
    destination_dir = vendor_dir.join(package)

    puts "Downloading #{package}@#{version} from #{tgz_url}..."
    download_file(tgz_url, tgz_path)

    puts "Extracting #{tgz_filename}..."
    extract_tarball(tgz_path, vendor_dir)

    puts "Moving files to #{destination_dir}..."
    install_files(package_tmp_dir, destination_dir)

    puts "Cleaning up..."
    cleanup_temporary_files(tgz_path, package_tmp_dir)

    puts "✅ Done! Package #{package} (version: #{version}) was successfully installed."
  rescue StandardError => e
    puts "Error during installation: #{e.message}"
    cleanup_temporary_files(tgz_path, package_tmp_dir) if defined?(tgz_path) && defined?(package_tmp_dir)
    exit 1
  end

  def download_file(url, destination)
    File.open(destination, "wb") do |file|
      URI.open(url) do |stream|
        file.write(stream.read)
      end
    end
  rescue StandardError => e
    raise "Failed to download file from #{url}: #{e.message}"
  end

  def extract_tarball(tarball_path, extract_dir)
    system("tar", "-xzf", tarball_path.to_s, "-C", extract_dir.to_s) or raise "Failed to extract tarball"
  end

  def install_files(source_dir, destination_dir)
    FileUtils.rm_rf(destination_dir)
    FileUtils.mkdir_p(destination_dir)
    Dir.glob(source_dir.join("*")).each do |file|
      FileUtils.mv(file, destination_dir, force: true)
    end
  end

  def cleanup_temporary_files(tgz_path, tmp_dir)
    FileUtils.rm(tgz_path) if File.exist?(tgz_path)
    FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
  end
end
