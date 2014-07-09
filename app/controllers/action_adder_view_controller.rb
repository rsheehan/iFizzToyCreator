# The view controller when adding actions.

class ActionAdderViewController < UIViewController

  # Actions are hashes with the following keys.
  # toy:, action_type:, action_param:, effect_type:, effect_param:

  ACTIONS = [:touch, :timer, :collision, :shake, :score_reaches, :when_created, :loud_noise, :toy_touch]
  EFFECTS = [:apply_force, :explosion, :apply_torque, :create_new_toy, :delete_effect, :score_adder, :play_sound]
  MODES = [:show_actions,:show_properties]

  FORCE_SCALE = 250
  EXPLODE_SCALE = 80
  ROTATION_SCALE = 2
  DELETE_FADE_TIME = 0.4 # seconds


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

    @main_view = @scene_creator_view_controller.main_view
    @main_view.add_delegate(self)
    @main_view.mode = :toys_only # only toys can be selected

    #setup mode buttons - show actions and properties
    position = [10, 10]
    @show_actions_btn = setup_button(:show_actions, position, @main_view)
    position[0] += CGRectGetWidth(@show_actions_btn.frame) + 10
    @show_properties_btn = setup_button(:show_properties, position, @main_view)

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
    button_scrollview = UIScrollView.alloc.initWithFrame(frame)
    button_scrollview.backgroundColor = UIColor.darkGrayColor
    button_scrollview
  end

  # Add buttons.
  def buttons(button_names, button_view)
    buttons = {}
    position = [10, 10]
    button_names.each do |button_name|
      button = setup_button(button_name, position, button_view)
      buttons[button_name] = button
      position[1] += CGRectGetHeight(button.frame) + 3
      label = UILabel.alloc.initWithFrame([[0, position[1]], [95, 10]])
      label.font = UIFont.systemFontOfSize(12)
      label.textColor = UIColor.whiteColor
      label.text = name_for_label(button_name)
      label.textAlignment = NSTextAlignmentCenter
      button_view.addSubview(label)
      position[1] += CGRectGetHeight(label.frame) + 8
    end
    button_view.setContentSize(CGSizeMake(95,position[1]))
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
    if(@selected_toy)
      #show modal with view of all associated actions and effects
      action_list_view_controller = ActionListViewController.alloc.initWithNibName(nil, bundle: nil)
      action_list_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      action_list_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
      action_list_view_controller.delegate = self
      action_list_view_controller.state = @state
      action_list_view_controller.scene_creator_view_controller = @scene_creator_view_controller
      action_list_view_controller.selected = @selected_toy
      presentViewController(action_list_view_controller, animated: true, completion: nil)
    end
  end

  def show_properties
    puts 'Show properties'
    if(@selected_toy)
      prop_list_view_controller = PropertyListViewController.alloc.initWithNibName(nil, bundle: nil)
      prop_list_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      prop_list_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
      prop_list_view_controller.delegate = self
      prop_list_view_controller.state = @state
      prop_list_view_controller.scene_creator_view_controller = @scene_creator_view_controller
      prop_list_view_controller.selected = @selected_toy
      presentViewController(prop_list_view_controller, animated: true, completion: nil)
    end
  end

  def enable_action_buttons(enable)
    @action_button_view.backgroundColor = enable ? Constants::GOLD : UIColor::darkGrayColor
    @action_buttons.each { |name, button| button.enabled = enable }
  end

  def enable_show_mode_buttons(enable)
    if @show_properties_btn
      @show_actions_btn.enabled = enable;
      @show_properties_btn.enabled = enable;
    end
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
  def repeat_time(seconds)
    @repeat_time_secs = seconds
    puts('Time SET',seconds)
  end

  def close_touch_view_controller
    dismissModalViewControllerAnimated(false, completion: nil)
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
  end

  def selected_toy=(toy)
    @selected_toy = toy
    enable_action_buttons(@selected_toy)
    enable_show_mode_buttons(@selected_toy)
    enable_effect_buttons(false)
    #@view_mode = @selected_toy ? :toy_selected : :nothing_chosen
  end

  def colliding_toy=(toy)
    @colliding_toy = toy
    dismissModalViewControllerAnimated(false, completion: nil)
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
  end

  def get_action
    if @action_button_name
      action_type = :button
      action_param = @action_button_name
    elsif @repeat_time_secs
      action_type = :timer
      action_param = [@repeat_time_secs]
    elsif @colliding_toy
      action_type = :collision
      action_param = @colliding_toy.template.identifier
    elsif @loud_noise
      action_type = :loud_noise
      action_param = nil
    elsif @when_created
      action_type = :when_created
      action_param = nil
    elsif @shake
      action_type = :shake
      action_param = nil
    elsif @score_reaches
      action_type = :score_reaches
      action_param = [@score_reaches]
    elsif @toy_touch
      action_type = :toy_touch
      action_param = nil
    else
      action_type = :unknown
      action_param = :unknown
    end
    reset_action_params
    return action_type, action_param
  end

  def reset_action_params
    @action_button_name = nil
    @repeat_time_secs = nil
    @colliding_toy = nil
    @loud_noise = nil
    @when_created = nil
    @shake = nil
    @score_reaches = nil
    @toy_touch = nil
  end

  # Gets the force information for the actions effect.
  # When this is received the action info is complete.
  def force=(force_vector)
    action_type, action_param = get_action
    effect_type = :apply_force
    effect_param = force_vector * FORCE_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
    @main_view.secondary_selected = nil
    @main_view.setNeedsDisplay
  end

  def rotation=(force)
    action_type, action_param = get_action
    effect_type = :apply_torque
    effect_param = force * ROTATION_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
    @main_view.secondary_selected = nil
    @main_view.setNeedsDisplay
  end

  def explosion=(force)
    action_type, action_param = get_action
    effect_type = :explosion
    effect_param = force * EXPLODE_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
    @main_view.secondary_selected = nil
    @main_view.setNeedsDisplay
  end

  def create_new_toy=(args)
    action_type, action_param = get_action
    effect_type = :create_new_toy
    effect_param = args
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    @main_view.secondary_selected = nil
    @main_view.setNeedsDisplay
  end

  # This is where we create the action/effect.
  def create_action_effect(toy, action_type, action_param, effect_type, effect_param)
    puts "ACTION on toy #{toy.template.identifier}: when #{action_type}(#{action_param}) do #{effect_type}(#{effect_param})"
    action = {toy: toy.template.identifier, action_type: action_type, action_param: action_param,
              effect_type: effect_type, effect_param: effect_param}
    @scene_creator_view_controller.main_view.add_action(action)
    toy.template.actions << action
    #save actions
    @state.save
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
  def close_modal_view (animation = false)
    dismissModalViewControllerAnimated(animation, completion: nil)
  end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    super
    #@state.save
    # collect the scene information to pass on to the play view controller
    #@state.scenes = [@main_view.gather_scene_info] # only one scene while developing
    #@play_view_controller.update_play_scene
  end

  def name_for_label(name)
    case name
      when :touch
        Language::TOUCH
      when :collision
        Language::COLLISION
      when :timer
        Language::REPEAT
      when :hold
        Language::HOLD
      when :shake
        Language::SHAKE
      when :when_created
        Language::WHEN_CREATED
      when :loud_noise
        Language::LOUD_NOISE
      when :toy_touch
        Language::TOY_TOUCH
      when :score_reaches
        Language::SCORE_REACHES
      when :apply_force
        Language::FORCE
      when :apply_torque
        Language::ROTATION
      when :explosion
        Language::EXPLOSION
      when :create_new_toy
        Language::CREATE_NEW_TOY
      when :transition
        Language::TRANSITION
      when :sound
        Language::SOUND
      when :delete_effect
        Language::DELETE
      when :score_adder
        Language::SCORE_ADDER
      when :play_sound
        Language::PLAY_SOUND
    end
  end

  def drop_toy(toy)
    drag_action_view_controller = CreateActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    #drag_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    drag_action_view_controller.new_toy = ToyInScene.new(@state.toys[toy])
    #drag_action_view_controller.delegate = self
    #@scene_creator_view_controller.main_view.truly_selected = @saved_selected_toy
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller

    dismissViewControllerAnimated(true, completion: lambda { presentViewController(drag_action_view_controller, animated: false, completion: nil)})
  end

  def close_toybox
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  def create_toy_action_viewer (toy)
    drag_action_view_controller = CreateActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    #drag_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    drag_action_view_controller.new_toy = toy
    #drag_action_view_controller.delegate = self
    #@scene_creator_view_controller.main_view.truly_selected = @saved_selected_toy
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(drag_action_view_controller, animated: false, completion: nil)
  end

  #======================
  # Actions
  #======================

  # Adding a touch event.
  def touch
    reset_action_params
    touch_action_view_controller = TouchActionViewController.alloc.initWithNibName(nil, bundle: nil)
    touch_action_view_controller.bounds_for_view = @bounds
    touch_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    touch_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    touch_action_view_controller.delegate = self
    presentViewController(touch_action_view_controller, animated: false, completion: nil)
  end

  # Adding a repeat event.
  def timer
    reset_action_params
    #disable buttons when showing modal screen
    enable_show_mode_buttons(false)

    #create a picker view controller pop up to define how long to repeat for
    # repeat_action_view_controller = RepeatActionViewController.alloc.initWithNibName(nil, bundle: nil)
    # repeat_action_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    # repeat_action_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
    # repeat_action_view_controller.delegate = self
    # presentViewController(repeat_action_view_controller, animated: false, completion: nil)
    @popover_type = :timer
    content = RepeatActionViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    @popover.presentPopoverFromRect(@action_buttons[:timer].frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionAny, animated:true)

  end

  #adding a collision event
  def collision
    reset_action_params
    #disable buttons when showing modal screen
    enable_show_mode_buttons(false)

    #make a modal to select another toy - must disable selecting same toy?
    collision_action_view_controller = CollisionActionViewController.alloc.initWithNibName(nil, bundle: nil)
    collision_action_view_controller.bounds_for_view = @bounds
    collision_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    collision_action_view_controller.other_toy = @selected_toy
    collision_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    presentViewController(collision_action_view_controller, animated: false, completion: nil)
  end

  def shake
    reset_action_params
    #store shake and switch to effect
    @shake = true
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
  end

  def score_reaches
    reset_action_params
    #TODO make user select score global or local
    #ask which value it reaches - popup
    #then move on to effect
    @popover_type = :score_reaches
    content = NumericInputPopOverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.setTitle('Enter the score that will trigger the event')
    content.delegate = self
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    @popover.presentPopoverFromRect(@action_buttons[:score_reaches].frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionAny, animated:true)
  end

  def popoverControllerShouldDismissPopover(popoverController)
    if popoverController.contentViewController.is_a?(NumericInputPopOverViewController)
      return false
    elsif popoverController.contentViewController.is_a?(RepeatActionViewController)
      return false
    elsif popoverController.contentViewController.is_a?(SoundSelectPopoverViewController)
      return false
    end
    true
  end

  def close_popover
    @popover_type = nil
    @popover.dismissPopoverAnimated(true)
  end

  def submit_number(number_str)
    case @popover_type
      when :score_reaches
        #set action
        @score_reaches = number_str.to_i
      when :timer
        repeat_time(number_str)
    end
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
    close_popover
  end

  def submit_score_adder (number, type)
    action_type, action_param = get_action
    effect_type = :score_adder
    effect_param = [number.to_i, type]
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)

    enable_action_buttons(true)
    enable_show_mode_buttons(true)
    enable_effect_buttons(false)

    close_popover
  end

  def when_created
    reset_action_params
    #include start?
    #move straight to effect as have already selected toy
    @when_created = true
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
  end

  def loud_noise
    reset_action_params
    #store loud noise and switch to effect
    @loud_noise = true
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
  end

  def toy_touch
    reset_action_params
    #store selected toy and switch to effect
    @toy_touch = @selected_toy
    enable_action_buttons(false)
    enable_show_mode_buttons(false)
    enable_effect_buttons(true)
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

  def apply_torque
    drag_action_view_controller = RotationActionViewController.alloc.initWithNibName(nil, bundle: nil)
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

  def create_new_toy
    toybox_view_controller = ToyBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    toybox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    toybox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    toybox_view_controller.delegate = self
    toybox_view_controller.state = @state
    presentViewController(toybox_view_controller, animated: true, completion: nil)
  end

  def delete_effect
    action_type, action_param = get_action
    effect_type = :delete_effect
    effect_param = DELETE_FADE_TIME
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    @main_view.secondary_selected = nil
    enable_action_buttons(true)
    enable_effect_buttons(false)
    @main_view.setNeedsDisplay
  end

  def score_adder
    @popover_type = :score_adder
    content = ScoreAdderActionViewController.alloc.initWithNibName(nil, bundle: nil)
    content.setTitle('Enter the change in score')
    content.delegate = self
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    frame = @effect_buttons[:score_adder].frame
    frame.origin.x = @effect_button_view.frame.origin.x + frame.origin.x
    @popover.presentPopoverFromRect(frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionAny, animated:true)
  end

  def play_sound
    #show popover to select sound to play
    @popover_type = :play_sound
    content = SoundSelectPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    @popover.presentPopoverFromRect([[@effect_buttons[:play_sound].frame.origin.x+@effect_button_view.frame.origin.x,@effect_buttons[:play_sound].frame.origin.y],@effect_buttons[:play_sound].frame.size], inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionAny, animated:true)


  end

  def set_sound(sound_name)
    action_type, action_param = get_action
    effect_type = :play_sound
    effect_param = sound_name
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    @main_view.secondary_selected = nil
    enable_action_buttons(true)
    enable_effect_buttons(false)
    @main_view.setNeedsDisplay
    close_popover
  end

end