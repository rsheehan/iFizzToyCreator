describe "Interface Test" do

  tests UITabBarControllerLandscape

  it 'test the whole game' do

    # Draw a toy
    view(Language::MAKE_TOYS).should.not == nil
    tap Language::MAKE_TOYS
    flick ('toyView', :from => CGPointMake(400,400), :to => CGPointMake(500,500))

    # Draw a scene
    view(Language::MAKE_SCENES).should.not == nil
    tap Language::MAKE_SCENES
    # Choose squiggle tool
    tap 'squiggle'

    view('sceneView').should.not == nil
    # draw a line
    flick ('sceneView', :from => CGPointMake(400,400), :to => CGPointMake(500,500))

    tap 'toy'

    # view(Language::ADD_ACTIONS).should.not == nil
    # tap Language::ADD_ACTIONS
    #
    # view(Language::PLAY).should.not == nil
    # tap Language::PLAY

  end




  # it 'test when sceneCreatorViewController is selected' do
  #   @tab_bar_controller.selectedViewController = @sceneCreatorViewController
  #   @app.keyWindow.rootViewController.selectedViewController.class.should == SceneCreatorViewController
  # end
  #
  # it 'test when actionAdderViewController is selected' do
  #   @tab_bar_controller.selectedViewController = @actionAdderViewController
  #   @app.keyWindow.rootViewController.selectedViewController.class.should == ActionAdderViewController
  # end
  #
  # it 'test when playViewController is selected' do
  #   @tab_bar_controller.selectedViewController = @playViewController
  #   @app.keyWindow.rootViewController.selectedViewController.class.should == PlayViewController
  # end

end
