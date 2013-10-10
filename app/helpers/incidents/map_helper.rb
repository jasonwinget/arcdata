module Incidents::MapHelper
  def map_config
    chapter = current_chapter
    bounds = chapter.incidents_geocode_bounds || '0,0,0,0'
    bounds = bounds.split(',').map(&:to_f)
    {lat: current_chapter.incidents_map_center_lat, lng: current_chapter.incidents_map_center_lng, zoom: current_chapter.incidents_map_zoom, geocode_bounds: bounds}
  end
end