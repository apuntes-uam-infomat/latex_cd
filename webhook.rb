require 'sinatra'
require 'json'

set :bind, '0.0.0.0'

post '/payload' do
  puts "Payload received"
  system './pullandbuild.sh &> pullandbuild.log &'
end

get '/' do
  body 'Sinatra says hi.'
  puts 'Saying hi'
end
