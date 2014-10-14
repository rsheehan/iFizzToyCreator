describe "Interface Test" do

  before do
    @app = UIApplication.sharedApplication
  end

  tests SceneCreatorViewController

  it 'test the whole game' do

    #rotate_device :to => :landscape
    #rotate_device :to => :portrait

    tap Language::MAKE_SCENES
    tap Language::MAKE_TOYS
    tap Language::MAKE_SCENES
    tap Language::ADD_ACTIONS
    tap Language::PLAY

    # Draw a scene
    # view(Language::MAKE_SCENES).should.not == nil
    # tap Language::MAKE_SCENES
    # # Choose squiggle tool
    # tap 'squiggle'
    #
    # view('sceneView').should.not == nil
    # # draw a line
    # #flick ('sceneView', :from => CGPointMake(400,400), :to => CGPointMake(500,500))
    #
    # tap 'toy'

  end


end
