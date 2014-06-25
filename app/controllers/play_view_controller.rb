# The controller of the PlayScene.
class PlayViewController < UIViewController

  TOP = 10
  MIDDLE = 281
  BOTTOM = 552
  LEFT = 10
  #RIGHT = 939

  attr_writer :state

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    play_over_view = UIView.alloc.init
    self.view = play_over_view

    location_of_play = [95, 0]
    @size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @play_view = SKView.alloc.initWithFrame([location_of_play, @size_of_play])
    @play_view.showsDrawCount = true
    @play_view.showsNodeCount = true
    @play_view.showsFPS = true
    view.addSubview(@play_view)
    @button_actions = {} # keys = buttons, values = list of actions for that button
    setup_sides
    @timers = []
    @shake_actions = []
    @noise_actions = []
    setup_reset(view)
    @listening = false
    @lowPassResults = 0
  end

  def listen_to_mic
    puts AVAudioSession.sharedInstance.to_s

    AVAudioSession.sharedInstance.requestRecordPermission(lambda do |granted|
        if granted
          puts "Microphone is enabled.."
        else
          puts "Microphone is disabled.."

          Dispatch::Queue.main.async do
                UIAlertView.alloc.initWithTitle("Microphone Access Denied",
                                                message:"This app requires access to your device's Microphone.\n\nPlease enable Microphone access for this app in Settings / Privacy / Microphone",
                                                delegate:nil,
                                                cancelButtonTitle:"Dismiss",
                                                otherButtonTitles:nil).show
          end
        end
      end)

    audioSession = AVAudioSession.sharedInstance
    audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error:nil)
    audioSession.setActive(true, error:nil)

    @listening = true
    url = NSURL.fileURLWithPath("/dev/null");
    settings = NSDictionary.dictionaryWithObjectsAndKeys(
        NSNumber.numberWithFloat(44100.0),                 AVSampleRateKey,
        NSNumber.numberWithInt(KAudioFormatAppleLossless), AVFormatIDKey,
        NSNumber.numberWithInt(2),                         AVNumberOfChannelsKey,
        NSNumber.numberWithInt(AVAudioQualityMax),         AVEncoderAudioQualityKey,
        nil)
    error = nil
    @recorder = AVAudioRecorder.alloc.initWithURL(url, settings:settings, error:error)

    if (@recorder)
      @recorder.prepareToRecord
      @recorder.meteringEnabled = true
      res = @recorder.record
      puts "recording started = "+res.to_s
      @levelTimer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: 'levelTimerCallback:', userInfo: nil, repeats: true)
    else
      puts error.description
    end
  end

  def levelTimerCallback(timer)
    @recorder.updateMeters

    if (@recorder.peakPowerForChannel(0) >= 0)
      puts "loud noise detected"
      @play_scene.add_actions_for_update(@noise_actions)
    end

  end

  def viewDidAppear(animated)
    update_play_scene
    self.becomeFirstResponder
  end

  def viewWillDisappear(animated)
    @timers.each do |timer|
      timer.invalidate
    end
    @timers = []
    self.resignFirstResponder
    if @listening
      @levelTimer.invalidate
      @levelTimer = nil
      @listening = false
    end
  end

  def canBecomeFirstResponder
    true
  end

  def motionEnded(motion, withEvent:event)
    if (motion == UIEventSubtypeMotionShake)
      #trigger shake events
      @play_scene.add_actions_for_update(@shake_actions)
    end
  end

  def update_play_scene
    return unless @play_view # this is because of the orientation bug being worked around in app_delegate
    @play_scene = PlayScene.alloc.initWithSize(@play_view.frame.size)
    @play_scene.physicsWorld.contactDelegate = @play_scene

    # this is purely for development only uses the first scene

    # add the toys to the scene
    @play_scene.toys = @state.scenes[@state.currentscene].toys
    # add the edges to the scene
    @play_scene.edges = @state.scenes[@state.currentscene].edges
    # also go through the actions checking for button actions and enabling the buttons
    @button_actions.each_key do |button|
      @button_actions[button] = []
    end
    disableButtons
    actions = @state.scenes[@state.currentscene].actions
    actions.each do |action|
      case action[:action_type]
        when :button
          button = enable_button(action[:action_param])
          #add_action_to_button
          @button_actions[button] << action
        when :timer
          puts("Action",action)
          @timers << NSTimer.scheduledTimerWithTimeInterval(action[:action_param][0]*60 + action[:action_param][1], target: self, selector: "perform_action:", userInfo: action, repeats: true)
        when :collision
          @play_scene.add_collision(action)
        when :shake
          @shake_actions << action
        when :loud_noise
          @noise_actions << action
          if not @listening
            listen_to_mic
          end
      end
    end

    # end of development code

    @play_view.presentScene(@play_scene)
    @play_scene.paused = true
    actions.each do |action|
      case action[:effect_type]
        when :explosion
          @play_scene.add_explode_ref(action[:toy])
        when :create_new_toy
          uid = @play_scene.add_create_toy_ref(action[:effect_param], @state.toys.select {|s| s.identifier == action[:effect_param][:id]}.first)
          action[:uid] = uid
      end
    end
    @play_scene.paused = false
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  def setup_reset(view)
    image_name = "reset"
    position = [@bounds.size.width/2-37.5, 10]
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed(image_name + '_selected'), forState: UIControlStateSelected) rescue puts 'rescued'
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(button)
    view.addSubview(button)
    button
  end

  def reset
    update_play_scene
  end

  # The sides are left for user interactions to the running scenes
  def setup_sides
    left_panel = UIView.alloc.initWithFrame(CGRectMake(0, 0, 95, @bounds.size.height))
    left_panel.setBackgroundColor(UIColor.grayColor)
    @left_top_button = setup_button([LEFT, TOP], left_panel)
    @left_middle_button = setup_button([LEFT, MIDDLE], left_panel)
    @left_bottom_button = setup_button([LEFT, BOTTOM], left_panel,)
    view.addSubview(left_panel)
    right_panel = UIView.alloc.initWithFrame(CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height))
    right_panel.setBackgroundColor(UIColor.grayColor)
    @right_top_button = setup_button([LEFT, TOP], right_panel)
    @right_middle_button = setup_button([LEFT, MIDDLE], right_panel)
    @right_bottom_button = setup_button([LEFT, BOTTOM], right_panel)
    view.addSubview(right_panel)
  end

  def setup_button(position, panel)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed('side_button'), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed('side_button_selected'), forState: UIControlStateHighlighted)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    @button_actions[button] = []
    #button.tag = tag
    button.addTarget(self, action: 'button_action:', forControlEvents: UIControlEventTouchUpInside)
    button.enabled = false
    panel.addSubview(button)
    button
  end

  def disableButtons
    @left_bottom_button.enabled = false
    @left_middle_button.enabled = false
    @left_top_button.enabled = false
    @right_bottom_button.enabled = false
    @right_middle_button.enabled = false
    @right_top_button.enabled = false
  end

  # Makes the button work
  # Also returns the button.
  def enable_button(name)
    button = case name
               when :left_top, "left_top"
                 @left_top_button
               when :left_middle, "left_middle"
                 @left_middle_button
               when :left_bottom, "left_bottom"
                 @left_bottom_button
               when :right_top, "right_top"
                 @right_top_button
               when :right_middle, "right_middle"
                 @right_middle_button
               when :right_bottom, "right_bottom"
                 @right_bottom_button
             end
    button.enabled = true
    button
  end

  def button_action(sender)
    # find the correct action and submit it for firing
    #puts "button: #{sender}"
        # pass the actions through to the scene for its update method to use
        @play_scene.add_actions_for_update(@button_actions[sender])
                                                                                                                                                     end

    def perform_action(timer)
      puts(timer)
      puts(timer.userInfo)
      @play_scene.add_actions_for_update([timer.userInfo])
    end

  end
