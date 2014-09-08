$: << File.dirname(__FILE__) + '/lib'
ENV["RACK_ENV"] = 'test'

require 'app'
require 'test/unit'
require 'rack/test'

describe "integration testing" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  [
    '/',
    '/blog',
    '/blog/archive',
    '/courses',
    '/courses/bdd-kickstart',
    '/courses/continuous-delivery-kickstart',
    '/courses/practical-object-oriented-design',
    '/dates',
    '/team',
    '/coaching',
    '/thanks',
    '/remote',
    '/in-house-courses/bdd',
    '/in-house-courses/cd',
    '/in-house-courses/poodr',
  ].each do |page|
    it "returns #{page} with a non failure code" do
      get page
      expect(last_response).to be_ok
    end
  end
end

