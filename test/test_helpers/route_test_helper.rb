module RouteTestHelper
  # Verifies that a route helper exists and can be called
  # Raises a helpful error if the route doesn't exist
  def assert_route_exists(route_helper_name, *args)
    assert_respond_to self, route_helper_name,
      "Route helper '#{route_helper_name}' does not exist. Check config/routes.rb"

    begin
      send(route_helper_name, *args)
    rescue NoMethodError, ArgumentError => e
      flunk "Route helper '#{route_helper_name}' exists but failed with: #{e.message}"
    end
  end

  # Verifies that a route generates the expected path
  def assert_route_generates(route_helper_name, expected_path, *args)
    assert_route_exists(route_helper_name, *args)
    actual_path = send(route_helper_name, *args)
    assert_equal expected_path, actual_path,
      "Route '#{route_helper_name}' generated '#{actual_path}' but expected '#{expected_path}'"
  end
end
