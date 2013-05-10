Subject = Struct.new(:course_title, :short_name, :long_name, :promos)

Promo = Struct.new(:heading, :strapline, :image)
Image = Struct.new(:url, :alt_text)
