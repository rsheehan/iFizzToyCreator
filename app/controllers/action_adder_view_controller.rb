# The view controller when adding actions.

class ActionAdderViewController < UIViewController

  # Actions are hashes with the following keys.
  # toy:, action_type:, action_param:, effect_type:, effect_param:

  ACTIONS = [:touch]
  EFFECTS = [:apply_force]

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

  # Gets the force information for the actions effect.
  # When this is received the action info is complete.
  def force=(force_vector)
    if @action_button_name
      action_type = :button
      action_param = @action_button_name
    else
      action_type = :unknown
      action_param = :unknown
    end
    effect_type = :applyForce
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

end