describe "Convex Hull Test" do

  before do
    @app = UIApplication.sharedApplication
  end

  # Test Toy Convex Hull and make sure it returns 12 points or less
  it "Test Toy Convex Hull" do

    toyParts = []
    toyParts << ToyPart.new(UIColor.redColor)
    toyParts << ToyPart.new(UIColor.greenColor)
    toyParts << ToyPart.new(UIColor.blueColor)
    toyParts.size.should == 3

    toyPhysic = ToyPhysicsBody.new(toyParts)

    # test random 100 points and make convex hull,
    # after that the convex hull should only contain 12 points or less
    randomPoints = []
    (0..100).each do |i|
      randomPoints << CGPointMake(rand(1000), rand(1000))
    end
    returnPoints = toyPhysic.convex_hull(randomPoints)
    returnPoints.size.should <= 12
  end


end
