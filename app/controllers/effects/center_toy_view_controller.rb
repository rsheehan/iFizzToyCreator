
# Lets call this an abstract class!
class CenterToyViewController < UIViewController
  attr_writer :selected
  attr_reader :toy_origin
  attr_writer :scene_creator_view_controller

  def viewDidAppear(animated)
    #Refresh UIView for moved toy
    @toy_origin = @selected.position
    toy_center = CGPointMake(@selected.image.size.width/2, @selected.image.size.height/2)
    center = @main_view.center - toy_center
    @selected.change_position(center)

    @scene_creator_view_controller.refresh
  end

  def viewDidDisappear(animated)
    @selected.change_position(@toy_origin)
  end

end