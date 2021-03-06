# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'sinatra'
require 'twitter'
require 'feedzirra'
require 'memcachier'
require 'dalli'
require 'rack-cache'
require 'yaml'
require 'slim'
require 'rest_client'
require 'dotenv'

Dotenv.load(
  File.expand_path("../../.#{ENV["RACK_ENV"]}.env", __FILE__),
  File.expand_path("../../.env", __FILE__),
)

require_relative 'event'
require_relative 'blog'

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
  config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  config.oauth_token = ENV["TWITTER_OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["TWITTER_OAUTH_TOKEN_SECRET"]
end

before do
  @draft = params.fetch("draft") { false }
end

set :root, File.expand_path(File.dirname(__FILE__) + '/..')

helpers do
  def view_drafts?
    @draft
  end

  def draft_only
    return unless view_drafts?
    yield if block_given?
  end

  def active(page)
  end

  def tweets
    return [] unless ENV['RACK_ENV'] == 'production'
    Twitter.user_timeline('kickstartac', count: 3) rescue []
  end

  def markup_tweet(raw)
    raw.
      gsub(/(https?[^ ]+)/, %Q{<a target="_blank" href="\\1">\\1</a>}).
      gsub(/@(\w+)/, %Q{<a target="_blank" href="http://twitter.com/\\1">@\\1</a>}).
      gsub(/#(\w+)/, %Q{<a target="_blank" href="http://twitter.com/search?q=%23\\1">#\\1</a>})
  end

  def blog_articles
    all_articles[0..15]
  end

  def article
  end

  def all_articles
    settings.blog.articles.sort do |a,b|
      b.published <=> a.published
    end
  end

  def popular_posts
    settings.blog.popular_articles.sort do |a,b|
      b.published <=> a.published
    end[0..15]
  end

  def blog_loading?
    settings.blog.refreshing?
  end

  def friendly_date(date)
    date.strftime("%a %-d %b %Y %H:%M")
  end

  def course_date(date)
    date.strftime("%-d %B %Y")
  end

  def course_type_description(type)
    { :bdd => "BDD Kickstart", :cd => "Continuous Delivery", :poodr => "Practical Object Oriented Design" }[type]
  end

  def course_date_range(dates)
    if (spans_month_boundary(dates))
      dates.first.strftime("%-d %b") + '-' + dates.last.strftime("%-d %b %Y")
    else
      dates.first.strftime("%-d") + '-' + dates.last.strftime("%-d %b %Y")
    end
  end

  def spans_month_boundary(daterange)
    daterange.first.month != daterange.last.month
  end

  def slugify(id)
    id.gsub(/\W/, '-')
  end

  def events(type)
    all_events.select { |e| e.type == type }
  end

  def upcoming_events(type)
    events(type).reject { |e| e.start_date < Date.today }.sort_by(&:start_date)
  end

  def upcoming_event(type)
    upcoming_events(type).first
  end

  def all_events
    valtech  = Venue.new('Valtech', '103 Rue de Grenelle, 75007, Paris, France', 48.856993,2.319338)
    ustwo    = Venue.new('usTwo', '62 Shoreditch High Street, London, E1 6JJ, United Kingdom', 51.5228274,-0.0778368)
    anteo    = Venue.new('Anteo', '1230 Peachtree Street NE, Atlanta, GA 30309', 33.788424, -84.383851)
    bitcrowd = Venue.new('BitCrowd', 'Sanderstraße 28, 12047 Berlin, Germany', 52.49237, 13.423832)
    saucehq  = Venue.new('Sauce Labs', '539 Bryant Street #303, San Francisco, CA 94107, USA', 37.780122, -122.396915)

    seb     = Coach.new( 'Seb Rose',          'seb',        '/images/seb-sm-bw.png' )
    rob     = Coach.new( 'Rob Chatley',       'rob',        '/images/rob.png'       )
    matt    = Coach.new( 'Matt Wynne',        'matt',       '/images/matt.png'      )
    steve   = Coach.new( 'Steve Tooke',       'tooky',      '/images/tooky.jpg'     )
    aslak   = Coach.new( 'Aslak Hellesøy',    'aslak',      '/images/aslak.jpg'     )
    julien  = Coach.new( 'Julien Biezemans',  'julien',     '/images/julien.png'    )
    sandi   = Coach.new( 'Sandi Metz',        'sandimetz',  '/images/sandi.jpg'     )
    liz     = Coach.new( 'Liz Keogh',         'liz',        '/images/liz.jpg'       )
    pat     = Coach.new( 'Pat Maddox',        'pat',        '/images/pat.jpg'       )

    [
      Event.new(
        :bdd,
        'San Francisco, USA',
        Time.parse('21 April 2015'),
        Time.parse('23 April 2015'),
        Tito.new('sanfrancisco2015'),
        saucehq,
        [julien],
        %{<p>Get a headstart with <a href="/courses/bdd-kickstart">Behaviour-Driven Development</a>, the collaborative process that's changing the face of software development.</p>
          <p>In three days, we'll teach you everything you need to be off and running with Behaviour-Driven Development.</p>
        <p>We'll start by teaching you the fundamental principles of BDD, and how it fits into the wider world of agile. We'll show you how to run specification workshops to explore new functionality as a collaborative activity, and show you how to express those specifications as executable Cucumber tests.</p>
        <p>Then we'll start applying those fundamentals in practice. We'll show you how to automate your application, whether it's a Java web service, a rich AJAX web application or a Flash game. We'll explore what to do as your test suite grows in size, and prepare you for the major hurdles most teams run into as they start to adopt BDD.</p>
        <p>Learn more <a href="/courses/bdd-kickstart">about the course</a>.</p>}
      ),
    ]
  end
end

set :static_cache_control, [:public, max_age: 1800]

BLOG_URLS = if ENV['BLOG_DEV']
              [
                'http://chrismdp.com/tag/bdd/atom.xml',
              ]
            else
              [
                'http://chrismdp.com/tag/cucumber/atom.xml',
                'http://chrismdp.com/tag/bddkickstart/atom.xml',
                'http://chrismdp.com/tag/bdd/atom.xml',
                'http://blog.mattwynne.net/tag/cucumber/atom',
                'http://blog.mattwynne.net/tag/bdd/atom',
                'http://blog.mattwynne.net/tag/agile/atom',
                'http://claysnow.co.uk/tag/bdd/feed/',
                'http://chatley.com/atom.xml',
                'http://tooky.co.uk/feed.xml',
                'https://cucumber.pro/feed.xml',
                'http://www.sandimetz.com/atom.xml',
                'http://lizkeogh.com/feed/',
              ]
            end
set :blog, Blog.new(BLOG_URLS).refresh

before do
  cache_control :public, max_age: 1800  # 30 mins
end

get('/details')           { redirect '/bdd-details' }
get('/bdd-details')       { redirect '/courses/bdd-kickstart' }
get('/in-house')          { redirect '/in-house-courses' }
get('/in-house-training') { redirect '/in-house-courses' }
get('/in-house-courses/') { redirect '/in-house-courses' }
get('/in-house-courses')  { redirect '/in-house-courses/bdd' }
get('/about')             { redirect '/team' }
get('/subscribe')         { redirect 'https://confirmsubscription.com/h/r/98D0EAA88FC788CA' }

get("/")        { slim :index }

%i(
  courses/bdd-kickstart
  courses/continuous-delivery-kickstart
  courses/practical-object-oriented-design
  blog
  blog/archive
  coaching
  dates
  team
  courses
  thanks
  remote
).each do |page|
  path = "/#{page}"
  get(path) { slim page }
end

# draft pages
#%i(
#).each do |page|
  #path = "/#{page}"
  #get(path) do
    #return 404 unless view_drafts?
    #slim page
  #end
#end

get('/in-house-courses/:course_type') { |course_type|
  slim :"in-house-courses", :locals => { :course_type => course_type.to_sym }
}

get('/blog/:page_slug') { |page_slug|
  article = all_articles.detect { |a| a.page_slug == page_slug }
  slim :"blog/article", :locals => { :article => article }
}

get('/dates/:event_id') do |event_id|
  event = all_events.detect { |e| e.id == event_id }
  slim :"dates/course", :locals => { :event => event }
end

get('/maps.js') do
  content_type 'text/javascript'
  erb :'maps.js', layout: false
end

post('/integrations/tito/ticket') do
  # TODO: If this is useful pull out the message creation, and slack
  # posting
  ticket_data = JSON.parse(request.body.string)

  slack_message = {
    "channel" => "#general",
    "username" => "kickstartac",
    "icon_emoji" => ":rocket:",
    "text" => "#{ticket_data["release"]} created for #{ticket_data["name"]}"
  }

  begin
    RestClient.post ENV["SLACK_WEBHOOK_URL"],
      :payload => slack_message.to_json
  rescue Exception => e
    # TODO: log errors
  ensure
    200
  end
end
