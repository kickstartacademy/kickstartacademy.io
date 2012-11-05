require 'bundler/setup'
require 'sinatra'

Bundler.require :default, Sinatra::Application.environment

get '/' do
  erb :index
end

get '/thanks' do
  erb :thanks
end

run Sinatra::Application
