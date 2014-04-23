class CollisionActionViewController < UIViewController

  attr_writer :delegate, :other_toy, :scene_creator_view_controller

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    action_over_view = UIView.alloc.init
    self.view = action_over_view
    @main_view = @scene_creator_view_controller.main_view
    @main_view.mode = :collision
    view.addSubview(@main_view)
    @main_view.change_label_text_to(Language::COLLISION_ADDER)
    #@main_view.other_toy = @other_toy

    command_label = UILabel.alloc.initWithFrame([[0, @bounds.size.height], [@bounds.size.width, 768 - @bounds.size.height]])
    command_label.backgroundColor = Constants::GOLD
    command_label.text = Language::TOUCH_COLLISION
    command_label.textAlignment = NSTextAlignmentCenter
    view.addSubview(command_label)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

end