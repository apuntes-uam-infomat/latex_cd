require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, ENV["PORT"].to_i

script_path = ENV["PULLANDBUILD_PATH"]

post '/payload' do
  system script_path + ' 2>&1 &'
end

get '/' do
  body 'Sinatra says hi.'
  puts 'Saying hi'
end
