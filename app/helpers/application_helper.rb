module ApplicationHelper
  def format_percentage(value)
    return "0.00" if value.nil?

    decimal_value = value.to_f

    # If value is between 0 and 1 (inclusive), assume it's a decimal and convert to percentage
    # Otherwise, assume it's already a percentage
    if decimal_value >= 0 && decimal_value <= 1
      format("%.2f", decimal_value * 100)
    else
      format("%.2f", decimal_value)
    end
  end
end
