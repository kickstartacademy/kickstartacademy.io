Subject = Struct.new(:short_name, :long_name, :twitter, :domain_name, :promos)

Promo = Struct.new(:heading, :strapline, :image)
Image = Struct.new(:url, :alt_text)
