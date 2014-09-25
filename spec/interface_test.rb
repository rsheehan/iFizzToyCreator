describe "Interface Test" do

  before do
    @app = UIApplication.sharedApplication
  end

  it 'should set rootviewcontroller as UITabBarControllerLandscape' do
    @app.keyWindow.rootViewController.class.should == UITabBarControllerLandscape
  end

  it 'should set selectedViewController as ToyCreatorViewController' do
    @app.keyWindow.rootViewController.selectedViewController.class.should == ToyCreatorViewController
  end


end
