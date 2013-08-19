require 'bundler/setup'
require 'sinatra'

helpers do
  def new(path)
    "http://kickstartacademy.io/#{path}"
  end
end

get('/')            { redirect new('courses/bdd-kickstart') }
get('/details')     { redirect new('courses/bdd-kickstart') }
get('/bdd-details') { redirect new('courses/bdd-kickstart') }
get('/cd-details')  { redirect new('courses/continuous-delivery-kickstart') }
get('/in-house-courses')  { redirect new('in-house') }
get('/in-house-training') { redirect new('in-house') }

%i(about dates blog thanks).each do |page|
  get("/#{page}") { redirect new(page) }
end

run Sinatra::Application
