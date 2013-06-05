require 'bundler/setup'
require 'sinatra'
require 'twitter'
require 'feedzirra'

require 'dalli'
require 'rack-cache'
require 'yaml'

require File.dirname(__FILE__) + '/lib/event'
require File.dirname(__FILE__) + '/lib/subject'

# Defined in ENV on Heroku. To try locally, start memcached and uncomment:
# ENV["MEMCACHE_SERVERS"] = "localhost"
if memcache_servers = ENV["MEMCACHE_SERVERS"]
  use Rack::Cache,
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"

  # Flush the cache
  Dalli::Client.new.flush
end

Twitter.configure do |config|
  config.consumer_key = '5sD8eQtceH3dFX53KAmBrg'
  config.consumer_secret = 'Bs4maTs0neLCs1Hm7LnjooOmkQITLLDahclCzQINW74'
  config.oauth_token = '860940638-JdRZgiJ878yOdLR757akKn8FfmsCVW5l73buMCeR'
  config.oauth_token_secret = 'b6nHS25AmaPjVInwfF1DjpoNQo0ufwtkpny9lK00'
end

helpers do
  def active(page)
  end

  def tweets
    return [] unless ENV['RACK_ENV'] == 'production'
    Twitter.user_timeline('bddkickstart', count: 3) rescue []
  end

  def markup_tweet(raw)
    raw.
      gsub(/(https?[^ ]+)/, %Q{<a target="_blank" href="\\1">\\1</a>}).
      gsub(/@(\w+)/, %Q{<a target="_blank" href="http://twitter.com/\\1">@\\1</a>}).
      gsub(/#(\w+)/, %Q{<a target="_blank" href="http://twitter.com/search?q=%23\\1">#\\1</a>})
  end

  def blog_articles
    blog_urls.map do |url|
      blog_entries(url)
    end.flatten.uniq(&:id).sort do |a,b|
      b.published <=> a.published
    end[0..15]
  end

  def blog_entries(url)
    Timeout.timeout(3) do
      Feedzirra::Feed.add_common_feed_entry_element('posterous:firstName', as: 'author')
      feed = Feedzirra::Feed.fetch_and_parse(url)
      return [] if feed == 0 || feed == 404 # this is what Feedzirra gives us if the request timed out
      feed.entries
    end
  rescue TimeoutError
    []
  end

  def blog_urls
    return [] unless ENV['RACK_ENV'] == 'production'
    [
      'http://chrismdp.com/tag/cucumber/atom.xml',
      'http://chrismdp.com/tag/bddkickstart/atom.xml',
      'http://chrismdp.com/tag/bdd/atom.xml',
      'http://blog.mattwynne.net/tag/cucumber/atom',
      'http://blog.mattwynne.net/tag/bdd/atom',
      'http://claysnow.co.uk/?tag=bdd&feed=rss2',
    ]
  end

  def friendly_date(date)
    date.strftime("%a %-d %b %Y %H:%M")
  end

  def course_date(date)
    date.strftime("%-d %B %Y")
  end

  def course_date_range(dates)
    if (spans_month_boundary(dates))
      dates.first.strftime("%-d %B") + '-' + dates.last.strftime("%-d %B %Y")
    else
      dates.first.strftime("%-d") + '-' + dates.last.strftime("%-d %B %Y")
    end
  end
  
  def spans_month_boundary(daterange)
    daterange.first.month != daterange.last.month
  end

  def slugify(id)
    id.gsub(/\W/, '-')
  end

  def course_type
    # Define training subject locally to get the right website
    chosen_subject = ENV['TRAINING_SUBJECT'] || 'bdd'
  end

  def events(type)
    all_events.select { |e| e.type == type }
  end

  def all_events
    [
      # Event.new(:bdd, 'London', Time.parse('22 May 2013'), Time.parse('24 May 2013'), 5231034164, Venue.new("Unboxed Consulting", "17 Blossom St, London, E1 6PL", 51.521288,-0.07804)),
      Event.new(:bdd, 'Barcelona', Time.parse('11 Sep 2013'), Time.parse('13 Sep 2013')),
      Event.new(:cd,  'London', Time.parse('30 Sep 2013'), Time.parse('1 Oct 2013')),
    ]
  end

  def subject
    subject = {
      'bdd' => YAML.load(File.read('data/bddkickstart.yml')),
      'cd'  => YAML.load(File.read('data/cdkickstart.yml')),
    }[course_type]
  end
end

set :static_cache_control, [:public, max_age: 1800]

before do
  cache_control :public, max_age: 1800  # 30 mins
end

get '/' do
  erb :index
end

get '/bdd-details' do
  erb :bdd_details
end

get '/cd-details' do
  erb :cd_details
end


get '/in-house-courses' do
  if (ENV['TRAINING_SUBJECT'] == 'cd')
    erb :'cd-in-house-courses'
  else
    erb :'bdd-in-house-courses'
  end
end

[:about, :dates, :blog, :thanks, :coaching].each do |page|
  get "/#{page}" do
    erb page
  end
end

get '/in-house-training' do
  redirect '/in-house-courses'
end

run Sinatra::Application
