# The template for the edge (part) and background information.

# I don't use this yet, but should separate this out from
# SceneTemplate eventually.

class BackgroundTemplate

  def initialize(parts) # will eventually have background image info too
    @parts = parts
  end

  # Turns the BackgroundTemplate into json compatible data.
  def to_json_compatible
    json_background = {}
    json_background[:id] = @identifier

    json_background[:image_name] = @background_image

    json_background[:parts] = []
    @parts.each do |part|
      json_background[:parts] << part.to_json_compatible
    end
    json_background
  end

end