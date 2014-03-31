Event = Struct.new(:type, :title, :start_date, :end_date, :tickets, :venue, :coaches, :details) do
  def id
    "#{type.to_s.downcase}-#{title.downcase}"
  end

  def course_type
    { :bdd => "BDD Kickstart", :cd => "Continuous Delivery Kickstart", :poodr => "Practical Object Oriented Design Kickstart" }[type]
  end

  def tickets?
    !!tickets
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

  def draft?
    false
  end
end

DraftEvent = Class.new(Event) do
  def draft?
    true
  end
end

Eventbrite = Struct.new(:eventbrite_id)
Tito = Struct.new(:tito_id)

Venue = Struct.new(:name, :address, :lat, :lng)

Coach = Struct.new(:name, :twitter, :avatar) do
  def bio
    "/team##{twitter}"
  end
end
