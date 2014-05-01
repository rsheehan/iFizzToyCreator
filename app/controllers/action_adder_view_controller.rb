# The view controller when adding actions.

class ActionAdderViewController < UIViewController

  # Actions are hashes with the following keys.
  # toy:, action_type:, action_param:, effect_type:, effect_param:

  ACTIONS = [:touch, :repeat, :collision]
  EFFECTS = [:apply_force, :explosion]

  FORCE_SCALE = 10

  attr_writer :state, :scene_creator_view_controller, :play_view_controller
  #attr_reader :selected_toy

  # TODO: undo/redo for placing, moving, resizing toys
  # Make sure that a list of added toys is maintained. These are removed when
  # reverting to SceneCreatorViewController or PlayViewController.

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    #@view_mode = :nothing_chosen
    action_over_view = UIView.alloc.init
    self.view = action_over_view

    #create a show actions button
    # Add the mode buttons


    location_of_action = [95, 0]
    size_of_action = [@bounds.size.width - 190, @bounds.size.height]

    action_bounds = CGRectMake(0, 0, 95, @bounds.size.height)
    @action_button_view = button_view(action_bounds)
    @action_buttons = buttons(ACTIONS, @action_button_view)
    effect_bounds = CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height)
    @effect_button_view = button_view(effect_bounds)
    @effect_buttons = buttons(EFFECTS, @effect_button_view)
    @action_button_name = nil
    #setup_label(Language::ACTION_ADDER)
    #@main_view.change_label_text_to(Language::ACTION_ADDER)
    #@main_view = ActionCreatorView.alloc.initWithFrame([location_of_action, size_of_action])
    @main_view = @scene_creator_view_controller.main_view
    @main_view.add_delegate(self)
    @main_view.mode = :toys_only # only toys can be selected

    #@main_view.mode = :toys_only  # only toys can be selected
    #@main_view.state = @state
    view.addSubview(@main_view)

    button = setup_button(:show_actions, [10,10], @main_view)
    button.enabled = true
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  def viewDidAppear(animated)
    @main_view.change_label_text_to(Language::ACTION_ADDER)
    @main_view.add_delegate(self)
    @main_view.mode = :toys_only # only toys can be selected
    view.addSubview(@main_view)
    super # MUST BE CALLED
    #if @view_mode == :nothing_chosen
    #enable_action_buttons(false)
    #enable_effect_buttons(false)
    #end
    #self.selected_toy = nil
  end

  def button_view(frame)
    button_view = UIView.alloc.initWithFrame(frame)
    button_view.backgroundColor = UIColor.darkGrayColor
    button_view
  end

  # Add buttons.
  def buttons(button_names, button_view)
    buttons = {}
    position = [10, 10]
    button_names.each do |button_name|
      button = setup_button(button_name, position, button_view)
      buttons[button_name] = button
      position[1] += CGRectGetHeight(button.frame) + 10
      label = UILabel.alloc.initWithFrame([[0, position[1]], [95, 14]])
      label.font = UIFont.systemFontOfSize(12)
      label.textColor = UIColor.whiteColor
      label.text = name_for_label(button_name)
      label.textAlignment = NSTextAlignmentCenter
      button_view.addSubview(label)
      position[1] += CGRectGetHeight(label.frame) + 5
    end
    view.addSubview(button_view)
    buttons
  end

  def setup_button(image_name, position, super_view)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed(image_name + '_selected'), forState: UIControlStateSelected) rescue puts 'rescued'
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    button.enabled = false
    super_view.addSubview(button)
    button
  end

  def show_actions
    puts 'SHOW ACTIONS'
    # transition to toy selector view where selecting a toy brings up a table view with action info etc.
    #make a modal to select another toy - must disable selecting same toy?
    show_action_view_controller = ShowActionViewController.alloc.initWithNibName(nil, bundle: nil)
    show_action_view_controller.bounds_for_view = @bounds
    show_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    show_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    show_action_view_controller.delegate = self
    show_action_view_controller.state = @state
    presentViewController(show_action_view_controller, animated: false, completion: nil)
  end

  def enable_action_buttons(enable)
    @action_button_view.backgroundColor = enable ? Constants::GOLD : UIColor::darkGrayColor
    @action_buttons.each { |name, button| button.enabled = enable }
  end

  def enable_effect_buttons(enable)
    @effect_button_view.backgroundColor = enable ? Constants::GOLD : UIColor::darkGrayColor
    @effect_buttons.each { |name, button| button.enabled = enable }
  end

  # Gets the button information for the action.
  def action_button_name=(button_name)
    @action_button_name = button_name
  end

  # sets the time information for the repeat action.
  def repeat_time(minutes, seconds)
    @repeat_time_mins = minutes
    @repeat_time_secs = seconds
    puts('Time SET',minutes,seconds)
  end

  def close_touch_view_controller
    dismissModalViewControllerAnimated(false, completion: nil)
    enable_action_buttons(false)
    enable_effect_buttons(true)
  end

  def selected_toy=(toy)
    @selected_toy = toy
    enable_action_buttons(@selected_toy)
    enable_effect_buttons(false)
    #@view_mode = @selected_toy ? :toy_selected : :nothing_chosen
  end

  def colliding_toy=(toy)
    @colliding_toy = toy
    dismissModalViewControllerAnimated(false, completion: nil)
    enable_action_buttons(false)
    enable_effect_buttons(true)
  end

  def get_action
    if @action_button_name
      action_type = :button
      action_param = @action_button_name
    elsif @repeat_time_mins
      action_type = :timer
      action_param = [@repeat_time_mins,@repeat_time_secs]
    elsif @colliding_toy
      action_type = :collision
      action_param = @colliding_toy.template.identifier
    else
      action_type = :unknown
      action_param = :unknown
    end
    # reset action params
    @action_button_name = nil
    @repeat_time_mins = nil
    @colliding_toy = nil
    return action_type, action_param
  end

  # Gets the force information for the actions effect.
  # When this is received the action info is complete.
  def force=(force_vector)
    action_type, action_param = get_action
    effect_type = :applyForce
    effect_param = force_vector * FORCE_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
    @main_view.colliding_selected = nil
    @main_view.setNeedsDisplay
  end

  def explosion=(force_vector)
    action_type, action_param = get_action
    effect_type = :explosion
    effect_param = force_vector * FORCE_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
  end

  # This is where we create the action/effect.
  def create_action_effect(toy, action_type, action_param, effect_type, effect_param)
    puts "ACTION on toy #{toy.template.identifier}: when #{action_type}(#{action_param}) do #{effect_type}(#{effect_param})"
    action = {toy: toy.template.identifier, action_type: action_type, action_param: action_param,
              effect_type: effect_type, effect_param: effect_param}
    @scene_creator_view_controller.main_view.add_action(action)
  end

  # Called when undo state might change.
  def can_undo(possible)
    #@tool_buttons[:undo].enabled = possible
  end

  # Called when redo state might change.
  def can_redo(possible)
    #@tool_buttons[:redo].enabled = possible
  end

  # Closes any modal view.
  def close_modal_view
    dismissModalViewControllerAnimated(false, completion: nil)
  end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    super
    # collect the scene information to pass on to the play view controller
    @state.scenes = [@main_view.gather_scene_info] # only one scene while developing
    @play_view_controller.update_play_scene
  end

  def name_for_label(name)
    case name
      when :touch
        Language::TOUCH
      when :collision
        Language::COLLISION
      when :repeat
        Language::REPEAT
      when :hold
        Language::HOLD
      when :score
        Language::SCORE
      when :apply_force
        Language::FORCE
      when :apply_rotation
        Language::ROTATE
      when :explosion
        Language::EXPLOSION
      when :create_new_toy
        Language::CREATE_NEW_TOY
      when :transition
        Language::TRANSITION
      when :sound
        Language::SOUND
    end
  end

  #======================
  # Actions
  #======================

  # Adding a touch event.
  def touch
    touch_action_view_controller = TouchActionViewController.alloc.initWithNibName(nil, bundle: nil)
    touch_action_view_controller.bounds_for_view = @bounds
    touch_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    touch_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    touch_action_view_controller.delegate = self
    presentViewController(touch_action_view_controller, animated: false, completion: nil)
  end

  # Adding a repeat event.
  def repeat
    #create a picker view controller pop up to define how long to repeat for
    repeat_action_view_controller = RepeatActionViewController.alloc.initWithNibName(nil, bundle: nil)
    repeat_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    repeat_action_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
    repeat_action_view_controller.delegate = self
    presentViewController(repeat_action_view_controller, animated: false, completion: nil)
  end

  #adding a collision event
  def collision
    #make a modal to select another toy - must disable selecting same toy?
    collision_action_view_controller = CollisionActionViewController.alloc.initWithNibName(nil, bundle: nil)
    collision_action_view_controller.bounds_for_view = @bounds
    collision_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    collision_action_view_controller.other_toy = @selected_toy
    collision_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(collision_action_view_controller, animated: false, completion: nil)
  end

  #======================
  # Effects
  #======================

  # Show the force to apply.
  def apply_force
    drag_action_view_controller = DragActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    #drag_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    #drag_action_view_controller.delegate = self
    #@scene_creator_view_controller.main_view.truly_selected = @saved_selected_toy
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(drag_action_view_controller, animated: false, completion: nil)
  end

  def apply_rotation
    drag_action_view_controller = DragActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    #drag_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    #drag_action_view_controller.delegate = self
    #@scene_creator_view_controller.main_view.truly_selected = @saved_selected_toy
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(drag_action_view_controller, animated: false, completion: nil)
  end

  def explosion
    drag_action_view_controller = ExplosionActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    #drag_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    #drag_action_view_controller.delegate = self
    #@scene_creator_view_controller.main_view.truly_selected = @saved_selected_toy
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(drag_action_view_controller, animated: false, completion: nil)
  end

end