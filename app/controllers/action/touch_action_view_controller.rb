# A touch action is to one of 6 buttons on the side of the screen.
class TouchActionViewController < UIViewController



  attr_writer :delegate

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame(@bounds)
    command_label = UILabel.alloc.initWithFrame(CGRectMake(95, 0, @bounds.size.width - 190, @bounds.size.height))
    command_label.backgroundColor = SceneCreatorView::DEFAULT_SCENE_COLOUR
    command_label.text = Language::CHOOSE_TOUCH_BUTTON
    command_label.font = UIFont.systemFontOfSize(36)
    command_label.textAlignment = NSTextAlignmentCenter
    view.addSubview(command_label)
    #left_bounds = CGRectMake(0, 0, 95, @bounds.size.height)
    #right_bounds = CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height)
    left_panel = UIView.alloc.initWithFrame(CGRectMake(0, 0, 95, 712))
    left_panel.backgroundColor = UIColor.darkGrayColor
    @left_top_button = setup_button([PlayViewController::LEFT, PlayViewController::TOP], left_panel, :left_top)
    @left_middle_button = setup_button([PlayViewController::LEFT, PlayViewController::MIDDLE], left_panel, :left_middle)
    @left_bottom_button = setup_button([PlayViewController::LEFT, PlayViewController::BOTTOM], left_panel, :left_bottom)
    view.addSubview(left_panel)
    right_panel = UIView.alloc.initWithFrame(CGRectMake(929, 0, 95, 712))
    right_panel.backgroundColor = UIColor.darkGrayColor
    @right_top_button = setup_button([PlayViewController::LEFT, PlayViewController::TOP], right_panel, :right_top)
    @right_middle_button = setup_button([PlayViewController::LEFT, PlayViewController::MIDDLE], right_panel, :right_middle)
    @right_bottom_button = setup_button([PlayViewController::LEFT, PlayViewController::BOTTOM], right_panel, :right_bottom)
    view.addSubview(right_panel)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  def setup_button(position, panel, action)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed('side_button'), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed('side_button_selected'), forState: UIControlStateHighlighted)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: action, forControlEvents: UIControlEventTouchUpInside)
    panel.addSubview(button)
    button
  end

  # The button actions
  def left_top
    #@left_top_button.selected = true
    @delegate.action_button_name = :left_top
    @delegate.close_touch_view_controller
  end

  def left_middle
    @delegate.action_button_name = :left_middle
    @delegate.close_touch_view_controller
  end

  def left_bottom
    @delegate.action_button_name = :left_bottom
    @delegate.close_touch_view_controller
  end

  def right_top
    @delegate.action_button_name = :right_top
    @delegate.close_touch_view_controller
  end

  def right_middle
    @delegate.action_button_name = :right_middle
    @delegate.close_touch_view_controller
  end

  def right_bottom
    @delegate.action_button_name = :right_bottom
    @delegate.close_touch_view_controller
  end

end