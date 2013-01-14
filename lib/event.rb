Event = Struct.new(:title, :date, :eventbrite_id, :venue) do
  def id
    title.downcase
  end

  def tickets?
    !!eventbrite_id
  end

  def venue?
    !!venue
  end

  def full_date
    [date, date + 2.days]
  end

  def fundamentals_date
    date
  end

  def applied_date
    [date + 1.day, date + 2.days]
  end

  def with_venue
    yield venue if venue?
  end
end

Venue = Struct.new(:name, :address, :lat, :lng)

