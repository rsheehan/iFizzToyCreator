# The controller of the PlayScene.
class PlayViewController < UIViewController

  TOP = 10
  MIDDLE = 281
  BOTTOM = 552
  LEFT = 10
  #RIGHT = 939
  EMPTY_ICON_INSET = UIScreen.mainScreen.scale != 1.0 ? 20 : 10

  attr_writer :state

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    play_over_view = UIView.alloc.init
    self.view = play_over_view

    location_of_play = [95, 0]
    @size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @play_view = SKView.alloc.initWithFrame([location_of_play, @size_of_play])
    if Constants::DEBUG
      @play_view.showsDrawCount = true
      @play_view.showsNodeCount = true
      @play_view.showsFPS = true
      @play_view.showsPhysics = true
    end
    view.addSubview(@play_view)

    @button_actions = {} # keys = buttons, values = list of actions for that button
    setup_sides
    @timers = []
    @shake_actions = []
    @noise_actions = []
    setup_reset(view)
    @listening = false
    @lowPassResults = 0
    @play_view.alpha = 0.0
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
    url = NSURL.fileURLWithPath("/dev/null")

    val_a = NSNumber.numberWithFloat(44100.0)
    key_a = AVSampleRateKey
    val_b = NSNumber.numberWithInt(KAudioFormatAppleLossless)
    key_b = AVFormatIDKey
    val_c = NSNumber.numberWithInt(2)
    key_c = AVNumberOfChannelsKey
    val_d = NSNumber.numberWithInt(AVAudioQualityMax)
    key_d = AVEncoderAudioQualityKey

    settings = NSDictionary.dictionaryWithObjects([val_a, val_b, val_c, val_d], forKeys: [key_a, key_b, key_c, key_d])

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
    if @state.scenes.size > 0
      loadingView = LoadingScene.alloc.initWithSize(@bounds.size)
      loadingView.game_name = @state.game_info.name
      loadingView.game_description = @state.game_info.description
      @play_view.alpha = 1.0
      @play_view.presentScene(loadingView)
      self.becomeFirstResponder
      #loadGame
      NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "loadGame", userInfo: nil, repeats: false)
    end
  end

  def loadGame
    @play_view.presentScene(@play_scene, transition: Constants::TRANSITION_EFFECT)
    #add_play_scene_actions
    update_play_scene
  end

  def viewWillAppear(animated)
    p "will appear now"
    setup_sides
  end


  def viewWillDisappear(animated)
    p 'play view just disappear'

    remove_actions
    @play_view.alpha = 0.0
    @play_view.presentScene(nil)
    @state.save
  end

  def remove_actions
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

  def scene_id
    @curret_scene_id
  end

  def update_play_scene(scene=@state.scenes[@state.currentscene])
    if scene == nil
      scene=@state.scenes[0]
    end

    if scene != nil
      return unless @play_view # this is because of the orientation bug being worked around in app_delegate
      @play_scene = PlayScene.alloc.initWithSize(@play_view.frame.size)
      @play_scene.physicsWorld.contactDelegate = @play_scene
      @play_scene.delegate = self

      @curret_scene_id = scene.identifier

      # set scene gravity
      @play_scene.setGravity(CGVectorMake(scene.gravityX, scene.gravityY))
      @play_scene.setBoundaries(scene.boundaries)
      @play_scene.setAllowSceneAction(scene.boundaries[4] == 1)

      # this is purely for development only uses the first scene
      @state.load_scene_actions(scene)

      # add background image
      @play_scene.background = scene.background
      if scene.backgroundURL != nil
        @play_scene.backgroundImageURL = scene.backgroundURL
      end

      # add the toys to the scene
      @play_scene.toys = scene.toyInPlayScene
      # Minh has changed, only add if toy is not ghost
      # add the edges to the scene
      @play_scene.edges = scene.edges #@state.scenes[@state.currentscene].edges
      # also go through the actions checking for button actions and enabling the buttons
      @button_actions.each_key do |button|
        @button_actions[button] = []
      end
      refresh_side_buttons
      if not @label.nil?
        @label.dismissPopoverAnimated(true)
        @label = nil
      end
      remove_actions
      disableButtons
      actions = @state.get_actions_from_toys(scene.toys)

      copied_actions = []
      actions.each do |action|
        if action[:toy] == Constants::SCENE_TOY_IDENTIFIER && action[:scene] != @curret_scene_id.to_s
          #copied_actions << action
        else
          copied_actions << action
        end
      end

      actions = copied_actions

      actions.each do |action|
        case action[:action_type]
          when :button
            button = enable_button(action[:action_param])
            @button_actions[button] << action
            button.setImage(get_btn_image_with_actions(@button_actions[button],false), forState: UIControlStateNormal)
            button.setImage(get_btn_image_with_actions(@button_actions[button],true), forState: UIControlStateSelected) rescue puts 'rescued'

          when :timer
            @timers << NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "perform_action:", userInfo: action, repeats: true)
          when :collision
            @play_scene.add_collision(action)
          when :shake
            @shake_actions << action
          when :loud_noise
            @noise_actions << action
            if not @listening
              listen_to_mic
            end
          when :when_created
            afterSeconds = action[:action_param][0].to_i
            if afterSeconds < 0
              afterSeconds = rand(-1*afterSeconds)*2
            end
            @play_scene.add_create_action(action)
            #p "action = #{action}"
          when :score_reaches
            @play_scene.add_score_action(action)
          when :toy_touch
            @play_scene.add_toy_touch_action(action)
        end
      end

      @play_view.presentScene(@play_scene, transition: Constants::TRANSITION_EFFECT)
      @play_scene.view.paused = true
      actions.each do |action|
        case action[:effect_type]
          when :explosion
            # For each toy with exploded ref, verify exploded array is populated
            toy = @state.toys.select {|s| s.identifier == action[:toy]}.first
            if toy.exploded.size == 0
              toy.populate_exploded
            end
          when :create_new_toy
            uid = @play_scene.add_create_toy_ref(action[:effect_param], @state.toys.select {|s| s.identifier == action[:effect_param][:id]}.first)
            action[:uid] = uid
          when :score
            @play_scene.scores[action[:toy]] = action[:effect_param]
        end
      end
      resumeGame
      #NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "resumeGame", userInfo: nil, repeats: false)
    end
  end

  def resumeGame
    @play_scene.view.paused = false
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
    loadingView = LoadingScene.alloc.initWithSize(@bounds.size)
    loadingView.game_name = @state.game_info.name
    loadingView.game_description = @state.game_info.description
    @play_view.alpha = 1.0
    @play_view.presentScene(loadingView)
    self.becomeFirstResponder
    loadGame
    #NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: "loadGame", userInfo: nil, repeats: false)

  end

  # The sides are left for user interactions to the running scenes
  def setup_sides
    @left_panel = UIView.alloc.initWithFrame(CGRectMake(0, 0, 95, @bounds.size.height))
    @left_panel.setBackgroundColor(UIColor.grayColor)
    @left_top_button = setup_button([LEFT, TOP], @left_panel)
    @left_middle_button = setup_button([LEFT, MIDDLE], @left_panel)
    @left_bottom_button = setup_button([LEFT, BOTTOM], @left_panel,)
    view.addSubview(@left_panel)
    @right_panel = UIView.alloc.initWithFrame(CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height))
    @right_panel.setBackgroundColor(UIColor.grayColor)
    @right_top_button = setup_button([LEFT, TOP], @right_panel)
    @right_middle_button = setup_button([LEFT, MIDDLE], @right_panel)
    @right_bottom_button = setup_button([LEFT, BOTTOM], @right_panel)
    view.addSubview(@right_panel)
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

  def refresh_side_buttons
    all_buttons = [@left_panel.subviews, @right_panel.subviews].flatten
    all_buttons.each do |button|
      button.setImage(UIImage.imageNamed('side_button'), forState: UIControlStateNormal)
      button.setImage(UIImage.imageNamed('side_button_selected'), forState: UIControlStateHighlighted)
    end

  end

  def get_btn_image_with_actions(actions, selected)
    if selected
      image = UIImage.imageNamed('side_button_selected')
    else
      image = UIImage.imageNamed('side_button')
    end

    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    #show all toys equally spaced
    actions.each_with_index { |action, index|
      toy = nil
      @state.toys.each do |t|
        if t.identifier == action[:toy]
          toy = t
        end
      end

      if index < 2 or (index == 2 and actions.size == 3)
        rect = CGRectMake(EMPTY_ICON_INSET, EMPTY_ICON_INSET+index*(image.size.height-2*EMPTY_ICON_INSET)/[actions.size,3].min, image.size.width-2*EMPTY_ICON_INSET, (image.size.height-2*EMPTY_ICON_INSET)/[actions.size,3].min)
        aspect = toy.image.size.width / toy.image.size.height
        if (rect.size.width / aspect <= rect.size.height)
          offset = rect.size.height
          rect.size = CGSizeMake(rect.size.width, rect.size.width/aspect)
          #make sure image is centered in height
          offset = (offset - rect.size.width/aspect)/2
          rect.origin = CGPointMake(rect.origin.x, rect.origin.y+offset)
        else
          offset = rect.size.width
          rect.size = CGSizeMake(rect.size.height * aspect, rect.size.height)
          #make sure image is centered in width
          offset = (offset - rect.size.height*aspect)/2
          rect.origin = CGPointMake(rect.origin.x+offset, rect.origin.y)
        end
        toy.image.drawInRect(rect)

      elsif index ==  2 and actions.size > 3
        #draw ... in third rect?
        rect = CGRectMake(0, 2*image.size.height/[actions.size,3].min, image.size.width, image.size.height/[actions.size,3].min)
        puts 'img size = '+image.size.width.to_s+ ", "+image.size.height.to_s
        puts 'draw dots in - 0,'+ (2*image.size.height/[actions.size,3].min).to_s+',' +image.size.width.to_s+','+ (image.size.height/[actions.size,3].min).to_s
        draw_dots_in_rect(context, rect)
      end
    }
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    newImage
  end

  def draw_dots_in_rect(context, rect)
    height = rect.size.height
    width = rect.size.width
    x = rect.origin.x
    y = rect.origin.y
    centers = [ CGPointMake(x+width/4,y+height/2),CGPointMake(x+2*width/4,y+height/2),CGPointMake(x+3*width/4,y+height/2)]
    radius = [height/4, width/16].min

    centers.each do |center|
      rectangle = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2)
      CGContextSetFillColorWithColor(context,UIColor.blackColor.CGColor)
      CGContextAddEllipseInRect(context, rectangle)
      CGContextFillPath(context)
    end
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
    @play_scene.add_actions_for_update(@button_actions[sender])
  end

  # this will run every second, if random then using if rand(1000) % 5 == 1 to fire for example
  def perform_action(timer)
    timeInterval = timer.userInfo[:action_param][0].to_i
    if timeInterval > 0
      time = Time.new
      if (time.sec + 60*time.min) % timeInterval == (timeInterval-1)
        @play_scene.add_actions_for_update([timer.userInfo])
      end
    else
      #p "random = #{timeInterval}"
      if rand(1000) % (-timeInterval+1) == 0
        @play_scene.add_actions_for_update([timer.userInfo])
      end
    end
  end

  def add_after_created_action(timer)
    @play_scene.add_actions_for_update([timer.userInfo])
    #p "creat action = #{timer.userInfo}"
  end

  def scene_shift(scene_id)
    scenes = @state.scenes.select {|scene| scene.identifier == scene_id}
    if not scenes.empty?
      update_play_scene(scenes.first)
    end
  end

  def create_label(string, frame)
    if not @label.nil?
      if @label.contentViewController.getInstruction == string
        return
      end
      @label.dismissPopoverAnimated(true)
      #remove label first
    end
    textpopover = PlayPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    textpopover.delegate = self
    textpopover.setInstruction(string)
    @label = UIPopoverController.alloc.initWithContentViewController(textpopover)
    @label.passthroughViews = [@play_view, @left_panel, @right_panel] #not working? should allow dragging while popover open
    @label.delegate = self
    @label.presentPopoverFromRect(frame , inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionDown, animated:true)
  end

end
