# A drag action is usually associated with an effect.
# e.g. dragging a toy here probably means apply a force in the direction of the drag.
class RotationActionViewController < CenterToyViewController

  #, :delegate

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    action_over_view = UIView.alloc.init
    self.view = action_over_view
    @main_view = @scene_creator_view_controller.main_view
    @main_view.mode = :rotation
    view.addSubview(@main_view)
    @main_view.selected = @selected

    @popover_title = Language::ROTATION_TITLE
    @popover_instr = Language::TOUCH_ROTATION

  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

end