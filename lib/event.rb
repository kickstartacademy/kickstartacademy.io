Event = Struct.new(:type, :title, :start_date, :end_date, :eventbrite_id, :venue) do
  def id
    "#{type.to_s.downcase}-#{title.downcase}"
  end

  def course_type
    { :bdd => "BDD Kickstart", :cd => "Continuous Delivery Kickstart" }[type]
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

