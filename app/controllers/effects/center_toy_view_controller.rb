
# Lets call this an abstract class!
class CenterToyViewController < UIViewController
  attr_writer :selected
  attr_reader :toy_origin
  attr_writer :scene_creator_view_controller

  def viewDidAppear(animated)
    #Refresh UIView for moved toy
    @toy_origin = @selected.position
    toy_center = CGPointMake(100, 0)
    center = @main_view.center
    true_center = center - toy_center
    @selected.change_position(true_center)

    @scene_creator_view_controller.refresh
  end

  def viewDidDisappear(animated)
    @selected.change_position(@toy_origin)
  end

end