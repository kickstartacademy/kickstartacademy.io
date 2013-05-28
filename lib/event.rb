Event = Struct.new(:type, :title, :start_date, :end_date, :eventbrite_id, :venue) do
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
    [start_date, end_date]
  end

  def fundamentals_date
    start_date
  end

  def applied_date
    [start_date + 1.day, end_date]
  end

  def with_venue
    yield venue if venue?
  end
end

Venue = Struct.new(:name, :address, :lat, :lng)

