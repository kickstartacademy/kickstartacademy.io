require_relative '../lib/blog'

describe Blog do

  let(:blog) { Blog.new(urls) }
  let(:urls) { [ 'http://blog.mattwynne.net/tag/bdd/feed/atom'] }

  it "has no articles by default" do
    blog.articles.should be_empty
  end

  it "fetches articles when asked" do
    blog.refresh(sync: true)
    blog.articles.should_not be_empty
  end
end
