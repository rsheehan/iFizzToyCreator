# Create here to allow landscape only but still be able to use image picker
class UITabBarControllerLandscape < UITabBarController
  def viewDidLoad
    @controllers = []
    icons = []

    # Make Home view
    home_page_view_controller = HomePageViewController.alloc.initWithNibName(nil, bundle: nil)
    home_page_view_controller.tab_bar = self
    @controllers << home_page_view_controller
    icons << icon_and_title(home_page_view_controller, Language::HOME, 'home_for_tab_bar')

    # Make Toys view
    @toy_creator_view_controller = ToyCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    @toy_creator_view_controller.tab_bar = self
    @controllers << @toy_creator_view_controller
    icons << icon_and_title(@toy_creator_view_controller, Language::MAKE_TOYS, 'toy_for_tab_bar')

    # Make Scene view
    @scene_creator_view_controller = SceneCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    @scene_creator_view_controller.tab_bar = self
    @controllers << @scene_creator_view_controller
    icons << icon_and_title(@scene_creator_view_controller, Language::MAKE_SCENES, 'scene_for_tab_bar')

    # Add Actions View
    actionView = action_creator_view_controller = ActionAdderViewController.alloc.initWithNibName(nil, bundle: nil)
    actionView.tab_bar = self
    @controllers << actionView
    icons << icon_and_title(action_creator_view_controller, Language::ADD_ACTIONS, 'action_for_tab_bar')
    action_creator_view_controller.scene_creator_view_controller = @scene_creator_view_controller

    # Play View
    play_view_controller = PlayViewController.alloc.initWithNibName(nil, bundle: nil)
    @controllers << play_view_controller
    icons << icon_and_title(play_view_controller, Language::PLAY, 'play_for_tab_bar')

    origin = CGPointMake(0,0)
    size = view.frame.size

    #@tab_bar_controller = UITabBarControllerLandscape.alloc.init
    tabBarHeight = self.tabBar.frame.size.height;

    # solve problem of rubymotion 2.33 vs previous version problems
    if size.height < size.width
      @view_bounds = CGRectMake(origin.x, origin.y, size.width, size.height - tabBarHeight)
    else
      @view_bounds = CGRectMake(origin.x, origin.y, size.height, size.width - tabBarHeight)
    end

    @controllers.each { 
      |controller| 
        controller.bounds_for_view = @view_bounds 
    }
    # Now set up my models
    @state = State.new
    @controllers.each { |controller| controller.state = @state }

    self.setViewControllers(@controllers, animated: true)

    # The following line is to remove a warning message about two-stage animation in iOS 7.
    # If the tab_bar_controller selected view controller is set to toy_creator_view_controller
    # first up then the buttons on the rhs are not active because it acts as if it is in portrait mode.
    self.selectedIndex = 0
    # CAN CHANGE TO scene_creator_view_controller
    tab_bar = self.tabBar
    icons.each_with_index { |icon, i| tab_bar.items[i].image = icon }    
  end

  def resetViews
    p "reset views"
    @toy_creator_view_controller.clear
    @scene_creator_view_controller.clear
  end

  def supportedInterfaceOrientations
    return UIInterfaceOrientationMaskLandscape
  end

  def shouldAutorotate
    return true
  end

  # Saving after the app has closed
  def applicationWillResignActive(application)
    @state.save
    while(@state.is_saving)
    end
  end
  # returns with the icon image
  def icon_and_title(controller, title, icon_name)
    controller.title = title
    imageIcon = UIImage.imageNamed(icon_name)
    imageIcon
  end
end