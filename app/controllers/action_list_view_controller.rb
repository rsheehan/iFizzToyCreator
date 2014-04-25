class ActionListViewController < UIViewController

    attr_writer :delegate, :selected, :scene_creator_view_controller

    LITTLE_GAP = 10
    BIG_GAP = 40
    WIDTH = 500

    def loadView
      # Do not call super.
      self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, WIDTH]])
      view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
      setup_button(:new, [LITTLE_GAP, LITTLE_GAP])

      #make array of actions that relate to the selected toy
      @toy_actions = []
      @state.scenes[0].actions.each do |action|
        if action[:toy] == @selected.template.identifier
          @toy_actions << action
        end
      end
      #make table view filled with all actions that have selected as the toy
      @table_view = UITableView.alloc.initWithFrame([[@current_xpos, 0], [WIDTH - @current_xpos, WIDTH]])
      @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
      @table_view.dataSource = self
      @table_view.delegate = self
      @table_view.rowHeight = 95
      view.addSubview(@table_view)
      #setup delete button

      @delete_mode = false
      @del_button = UIButton.buttonWithType(UIButtonTypeCustom)
      @del_button.setImage(UIImage.imageNamed(:delete), forState: UIControlStateNormal)
      @del_button.sizeToFit
      @del_button.frame = [ [LITTLE_GAP, LITTLE_GAP+BIG_GAP*2], @del_button.frame.size]
      @del_button.addTarget(self, action: :delete, forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@del_button)
    end

    def setup_button(image_name, position)
      button = UIButton.buttonWithType(UIButtonTypeCustom)
      button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
      button.sizeToFit
      button.frame = [position, button.frame.size]
      button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(button)
      frame = button.frame
      @current_xpos = @left_margin = frame.origin.x + frame.size.width + BIG_GAP
      @right_margin = WIDTH - LITTLE_GAP
      @next_ypos = @current_ypos = LITTLE_GAP
    end

    # We need this to gain access to the toys.
    def state=(state)
      @state = state
    end

    # Back to the Select toy screen.
    def new
      @delegate.close_modal_view
    end


    #activate delete mode
    def delete
      # if @delete_mode
      #   @delete_mode = false
      #   #set image
      #   @del_button.setImage(UIImage.imageNamed(:delete), forState: UIControlStateNormal)
      # else
      #   @delete_mode = true
      #   #set image
      #   @del_button.setImage(UIImage.imageNamed(:done), forState: UIControlStateNormal)
      # end
      #
      # #update cells
      # @table_view.reloadData()

    end
    # The methods to implement the UICollectionViewDataSource protocol.


    def tableView(tv, numberOfRowsInSection: section)
      @toy_actions.length
    end

    def tableView(tv, cellForRowAtIndexPath: index_path)
      item = index_path.row # ignore section as only one
      # if @delete_mode
      #   toy_button = cv.dequeueReusableCellWithReuseIdentifier(DELETETOYBUTTON, forIndexPath: index_path)
      #   toy_button.layer.removeAllAnimations
      #   animateToyButton(toy_button,0,false)
      # else
      #   toy_button = tv.dequeueReusableCellWithReuseIdentifier("ActionCell", forIndexPath: index_path)
      # end

      @reuseIdentifier ||= "cell"
      action_cell = @table_view.dequeueReusableCellWithIdentifier(@reuseIdentifier)
      action_cell ||= ActionCell.alloc.initWithStyle(UITableViewCellStyleValue1, reuseIdentifier: @reuseIdentifier)

      action = @toy_actions[item]
      #action image
      case action[:action_type]
        when :collision
          action_cell.action_image = UIImage.imageNamed("collision.png")
          #set object to be the toy image of the identifier in actionparam
          @state.toys.each do |toy|
            if toy.identifier == action[:action_param]
              action_cell.object_image = toy.image
              break
            end
          end

        when :timer
          action_cell.action_image = UIImage.imageNamed("repeat.png")
          # action_cell.action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
          #show how often in object view
          # action_cell.object_image_view = UILabel.alloc.init
          # action_cell.object_image_view.text = action[:action_param][0] + ':' + action[:action_param][1]
        when :button
          action_cell.action_image = UIImage.imageNamed("touch.png")
          action_cell.object_image = UIImage.imageNamed(action[:action_param]+ ".png")
          # action_cell.action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
          # action_cell.object_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed(action[:action_param]+ ".png"))
      end

      #effect image

      action_cell

    end

    def animateToyButton(button,rotation,decreasing)
      if not(@delete_mode)
        return
      end
      if decreasing
        rotation -= 0.01
        if rotation <= -3.14/128
          decreasing = false
        end
      else
        rotation += 0.01
        if rotation >= 3.14/128
          decreasing = true
        end
      end

      UIView.animateWithDuration(0.00001,
                                 delay: 0,
                                 options: UIViewAnimationOptionAllowUserInteraction,
                                 animations: lambda {
                                   button.transform = CGAffineTransformMakeRotation(rotation)
                                 },
                                 completion:lambda {|finished|
                                   animateToyButton(button,rotation,decreasing)
                                 }
      )
    end

    # And the methods for the UICollectionViewDelegateFlowLayout protocol.
    # Without this the size of the cells are the default.
    # def collectionView(cv, layout: layout, sizeForItemAtIndexPath: index_path)
    #   item = index_path.row
    #   @state.toys[item].image.size
    # end
    #
    # def collectionView(cv, layout: layout, insetForSectionAtIndex: section)
    #   UIEdgeInsetsMake(5, 5, 5, 5)
    # end

    # And the methods for the UICollectionViewDelegate protocol.
    def tableView(tv, didSelectRowAtIndexPath: index_path)
      item = index_path.row
      # if @delete_mode
      #   delete_toy(index_path)
      # else
      #   @delegate.drop_toy(item)
      # end
      puts "Selected row "
    end

    def tableView(tableView, titleForHeaderInSection:section)
      return "Action        Object        Effect"
    end
end