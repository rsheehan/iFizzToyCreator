class EdgeView < UIView

  attr_writer :creator_view

  def touchesBegan(touches, withEvent: event)
    touch = touches.anyObject
    # pass the touch on to the creator view
    point = touch.locationInView(@creator_view)
    @creator_view.touch_began_from_edge(point)
  end

  def touchesMoved(touches, withEvent: event)
    touch = touches.anyObject
    point = touch.locationInView(@creator_view)
    @creator_view.touch_moved_from_edge(point)
  end

  def touchesEnded(touches, withEvent: event)
    @creator_view.touch_ended_from_edge
  end


end