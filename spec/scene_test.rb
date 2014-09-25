describe "Scene Test" do

  before do
    @app = UIApplication.sharedApplication

    delegate = @app.delegate

    tab_bar_controller = delegate.instance_variable_get('@tab_bar_controller')

    @controllers = delegate.instance_variable_get('@controllers')

    @controllers.each do |controller|
      if controller.instance_of? SceneCreatorViewController
        @sceneCreatorViewController = controller
        tab_bar_controller.selectedViewController = @sceneCreatorViewController
        @sceneView = @sceneCreatorViewController.instance_variable_get('@main_view')
      end
    end

  end

  it 'should have controller with size = 4' do
      @controllers.size.should == 4
  end

  it '@sceneCreatorViewController should be subclass of SceneCreatorViewController' do
    @sceneCreatorViewController.class.should.equal SceneCreatorViewController
  end

  it '@sceneView should be subclass of SceneCreatorView' do
    @sceneView.should.not == nil
    @sceneView.class.should.equal SceneCreatorView
  end

  it 'Test for set gravity' do
    @sceneView.setGravity(CGVectorMake(-10, +10))
    gravity = @sceneView.instance_variable_get('@gravity')
    gravity.dx.should == -10
    gravity.dy.should == +10

  end

  it 'Test for default boundaries' do
    # default should be [1,1,1,1]
    boundaries = @sceneView.instance_variable_get('@boundaries')
    boundaries[0].should == 1
    boundaries[1].should == 1
    boundaries[2].should == 1
    boundaries[3].should == 1
  end

  it 'Test for set new boundaries' do
    @sceneView.setBoundaries([1,0,1,0])
    boundaries = @sceneView.instance_variable_get('@boundaries')
    boundaries[0].should == 1
    boundaries[1].should == 0
    boundaries[2].should == 1
    boundaries[3].should == 0
  end

  it 'Test for default Background should be nil' do
    backgroundImage = @sceneView.instance_variable_get('@backgroundImage')
    backgroundImage.class.should == NilClass
    backgroundImage.should == nil
  end

  it 'Test for set nil Background, should be nil' do
    @sceneView.setBackground(nil)
    backgroundImage = @sceneView.instance_variable_get('@backgroundImage')
    backgroundImage.class.should == NilClass
    backgroundImage.should == nil
  end

  it 'Test for set UIImage Background, should be UIImage' do
    tempBG = 'bground.jpg'.uiimage
    @sceneView.setBackground(tempBG)
    backgroundImage = @sceneView.instance_variable_get('@backgroundImage')
    p "backgound image #{backgroundImage}"
    backgroundImage.class.should == UIImage
    backgroundImage.should.not == nil
  end

  it 'Test for set Background back to nil after an image is set, should be nil' do
    tempBG = 'bground.jpg'.uiimage
    @sceneView.setBackground(tempBG)
    @sceneView.setBackground(nil)

    backgroundImage = @sceneView.instance_variable_get('@backgroundImage')
    p "backgound image #{backgroundImage}"
    backgroundImage.class.should == NilClass
    backgroundImage.should == nil
  end

end