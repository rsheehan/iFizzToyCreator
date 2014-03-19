# A drag action is usually associated with an effect.
# e.g. dragging a toy here probably means apply a force in the direction of the drag.
class DragActionViewController < UIViewController

  attr_writer :scene_creator_view_controller #, :delegate
  attr_writer :selected

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    action_over_view = UIView.alloc.init
    self.view = action_over_view
    @main_view = @scene_creator_view_controller.main_view
    @main_view.mode = :force
    view.addSubview(@main_view)
    @main_view.change_label_text_to(Language::FORCE_ADDER)
    @main_view.selected = @selected
    command_label = UILabel.alloc.initWithFrame([[0, @bounds.size.height], [@bounds.size.width, 768 - @bounds.size.height]])
    command_label.backgroundColor = Constants::GOLD
    command_label.text = Language::TOUCH_FORCE
    command_label.textAlignment = NSTextAlignmentCenter
    view.addSubview(command_label)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

end