require 'fileutils'

# Main class for Kate-Get.
class KateGet

	# Reads in a YAML config file or hash.
	# @param [String, Hash] config YAML config file or hash of config options
	def initialize config
		@config = \
			if config.is_a? String
				require 'yaml'
				file = File.expand_path config
				YAML.load File.read file if File.exists? file
			elsif config.is_a? Hash
				config
			end

		fail "Failed to load config." unless @config.is_a? Hash

		#update

	end

	# Addes a file to the array of files to be copied.
	# @param [String] file path to file
	def add_file file
		@files = [] unless @files
		@files << file
	end

	# Uses rsync to download files based on config options.
	def get

		@files.each do |f|

			# Look for the first source that matches the file.
			site, name = nil
			@config[:sources].each do |n, s|
				name, site = [n, s] if f[/^#{s[:base].sub "##source_name##", n}/ ]
				break if site
			end

			# Skip the file if there is no matching source.
			next if site.nil?

			# Load global connection settings and merge with source specific ones.
			remote = @config[:global]
			remote.merge! site[:remote] unless site[:remote].nil?

			# Prepare the elements for the rsync command.
			root_dir = site[:root].sub "##source_name##", name
			base = site[:base].sub "##source_name##", name

			# Skip the file if it is not in the root directory of the source.
			next unless f[root_dir]

			f.sub! base, ""

			dir = "#{File.expand_path site[:local]}#{File.dirname f}"
			FileUtils.mkdir_p dir unless File.directory? dir

			rsync = "rsync -a -e 'ssh -p #{remote[:port]}' #{remote[:user]}@#{remote[:host]}:#{root_dir}/#{f} #{site[:local]}/#{f}"

			# Get the file using rsync.
			system rsync
		end
	end
end