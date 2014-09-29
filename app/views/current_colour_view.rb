class CurrentColourView < UIView

  def current_colour_image=(colour_image)
    @current_colour_image = colour_image
    setNeedsDisplay
  end

  # Shows the currently selected colour.
  def draw_current_colour_indicator(context)
    @current_colour_image.drawInRect(CGRectMake(10, 10, *@current_colour_image.size))
  end

  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()
    draw_current_colour_indicator(context)
  end

end