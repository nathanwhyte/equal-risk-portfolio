module ApplicationHelper
  def format_percentage(value)
    return "0.000" if value.nil?

    format("%.2f", value.to_f)
  end
end
