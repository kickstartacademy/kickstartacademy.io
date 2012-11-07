require 'bundler/setup'
require 'sinatra'

get '/' do
  erb :index
end

get '/details' do
  erb :details
end

get '/thanks.html' do
  erb :thanks
end

run Sinatra::Application
