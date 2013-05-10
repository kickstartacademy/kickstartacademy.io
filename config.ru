require 'bundler/setup'
require 'sinatra'
require 'twitter'
require 'feedzirra'

require 'dalli'
require 'rack-cache'

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
    dates.first.strftime("%-d") + '-' + dates.last.strftime("%-d %B %Y")
  end

  def slugify(id)
    id.gsub(/\W/, '-')
  end

  def events
    [
      Event.new('London', Time.parse('22 May 2013'), 5231034164),
      Event.new('Barcelona', Time.parse('11 Sep 2013')),
    ]
  end

  def subject
    # Define training subject locally to get the right website
    subject = {
      'bdd' => Subject.new("BDD Kickstart", "BDD", "Behaviour-driven Development", [
                           Promo.new("A masterclass in Behaviour-driven Development.", "Get a flying start with BDD, the collaborative process that's changing the face of software development.", Image.new("images/hero-shot-students.jpeg", "students")),
                           Promo.new("Less time hunting bugs<br/>More time shipping features", "Learn to catch bugs before they've even been written, giving you more time to focus on building software that matters."),
                           Promo.new("Learn from the experts.", "With 2 books and over 30 years' in software development, Matt and Chris have a wealth of experience to share with you.", Image.new("images/hero-shot-book.jpeg", "book")),
    ]
                          ),
    }[ENV['TRAINING_SUBJECT'] || 'bdd']
  end
end

set :static_cache_control, [:public, max_age: 1800]

before do
  cache_control :public, max_age: 1800  # 30 mins
end

get '/' do
  erb :index
end

[:about, :details, :dates, :blog, :thanks, :'in-house-courses', :coaching].each do |page|
  get "/#{page}" do
    erb page
  end
end

get '/in-house-training' do
  redirect '/in-house-courses'
end

run Sinatra::Application
