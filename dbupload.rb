require 'dropbox_sdk'

access_token = ARGV[0]
target_dirs = [ "/Doble Grado UAM/Apuntes LaTeX/", "/Archivo/Apuntes/" ]
file = ARGV[1]

def db_upload(client, dir, file, name)
	begin
		puts 'Uploading %s to %s...' % [ name, dir ]
		response = client.put_file(dir + name, open(file), true)
	rescue => e
		puts 'Error uploading %s to %s directory' % [ name, dir]
		puts response.inspect
		puts e.inspect
	end
end

puts 'DbUpload start'

client = DropboxClient.new(access_token)

target_dirs.each do |dir|
	db_upload(client, dir, file, File.basename(file))
end

puts 'DbUpload end'
		
