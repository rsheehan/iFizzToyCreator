#require 'mac_bacon'

describe "Application 'untitledIfizz'" do

  before do
    @app = UIApplication.sharedApplication
    @ary = Array.new
  end

  # Test for having only one window
  it "App has one window" do
    @app.windows.size.should == 1
  end

  # Test for App supports Shake to Edit
  it "App supports Shake to Edit" do
    @app.applicationSupportsShakeToEdit.should == true
  end

  # Test App and its environment
  it "App and its environment" do
    delegate = @app.delegate
    state = delegate.instance_variable_get('@state')

    # state should not be nil
    state.nil?.should == false

    toys = state.instance_variable_get('@toys')
    toys.size.should >= 0

    scenes = state.instance_variable_get('@scenes')
    scenes.size.should >= 0

    #test to make sure height and width is correctly set
    view_bounds = delegate.instance_variable_get('@view_bounds')
    view_bounds.size.width.should > view_bounds.size.height

  end

  it 'should be empty' do
    @ary.size.should.equal 0
    @ary.size.should.be.close 0.1, 0.5

  end

  it 'should be less than 5' do
    [1,2,3,4].should.be shorter_than(5)
  end

  def shorter_than(max_size)
    lambda { |obj| obj.size < max_size}
  end
end
