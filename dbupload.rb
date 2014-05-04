require 'dropbox_sdk'

flines = File.readlines("dbtoken")

access_token = flines[0]
target_dirs = [ "/Doble Grado UAM/Apuntes LaTeX/", "/Archivo/Apuntes/" ]
file = ARGV[0]

def db_upload(client, dir, file, name)
	begin
		puts 'Uploading %s...' % name
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
	dp_upload(client, dir, file, filename)
end

puts 'DbUpload end'
		
