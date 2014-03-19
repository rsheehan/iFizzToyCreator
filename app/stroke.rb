class Stroke
  attr_reader :position
  attr_reader :old_position
  attr_reader :colour
  attr_reader :image

  # Move the stroke by the vector
  def move(vpoint)
    @position += vpoint
  end

  # Called when a move in the UI is completed.
  def change_position(position)
    @old_position = @position = position
  end

  # Called when the colour is changed.
  def change_colour(colour)
    @colour = colour
    generate_image
    # need to change the angle back to zero as redrawn
  end
end