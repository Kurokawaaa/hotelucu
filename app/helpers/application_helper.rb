module ApplicationHelper
  def status_label(value)
    value.to_s.humanize
  end

  def booking_overdue_label(booking)
    "Telat" if booking.respond_to?(:overdue_checkout?) && booking.overdue_checkout?
  end
end
