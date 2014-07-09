class ActionListPopoverViewController < UIViewController

    attr_writer :delegate, :selected, :scene_creator_view_controller

    LITTLE_GAP = 10
    BIG_GAP = 40
    WIDTH = 300
    MAX_HEIGHT = 500

    def loadView
      # Do not call super.
      self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, 40]])
      view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

      #make array of actions that relate to the selected toy
      @toy_actions = []
      @state.scenes[@state.currentscene].actions.each do |action|
        if action[:toy] == @selected.template.identifier
          @toy_actions << action
        end
      end

      #back button
      @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
      @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
      @back_button.frame = [[5, 5], [20,20]]
      @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@back_button)

      @margin = @back_button.frame.size.width

      #title
      @title = UILabel.alloc.initWithFrame([[@margin+5,5],[WIDTH-@margin-5,20]])
      @title.setText('Actions')
      @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
      @title.setFont(UIFont.boldSystemFontOfSize(16))
      view.addSubview(@title)

      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 29.0, WIDTH, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      self.view.layer.addSublayer(separator)

      #make table view filled with all actions that have selected as the toy
      if @toy_actions.size > 3
        tvHeight = 280
      else
        tvHeight = 80 * @toy_actions.size
      end

      @table_view = UITableView.alloc.initWithFrame([[0, 35], [WIDTH, tvHeight]])
      @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
      @table_view.dataSource = self
      @table_view.delegate = self
      @table_view.rowHeight = 80
      view.addSubview(@table_view)

      #bottomSeparator?

      #setup new action button
      @action_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
      @action_button.frame = [ [0, @table_view.frame.size.height+40], [WIDTH/2,20]]
      @action_button.setTitle("New Action", forState: UIControlStateNormal)
      @action_button.addTarget(self, action: 'new_action:', forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@action_button)

      #setup edit button
      @edit_mode = false
      @edit_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
      @edit_button.frame = CGRectMake(WIDTH/2,@table_view.frame.size.height+40, WIDTH/2,20)
      @edit_button.setTitle("Edit", forState: UIControlStateNormal)
      @edit_button.addTarget(self, action: 'edit:', forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@edit_button)

      self.preferredContentSize = [WIDTH, @edit_button.frame.origin.y+@edit_button.frame.size.height+5]

    end

    # We need this to gain access to the toys.
    def state=(state)
      @state = state
    end

    # Back to the Select toy screen.
    def back(sender)
      @state.save
      @delegate.action_flow_back
    end

    def new_action(sender)
      puts "new action"
      @delegate.new_action
    end

    #activate edit mode
    def edit
      if @table_view.isEditing
        @table_view.setEditing(false, animated: true)
        @edit_button.setTitle("Edit", forState: UIControlStateNormal)
      else
        @table_view.setEditing(true, animated: true)
        @edit_button.setTitle("Done", forState: UIControlStateNormal)
      end
    end

    # The methods to implement the UICollectionViewDataSource protocol.

    def tableView(tv, commitEditingStyle: style, forRowAtIndexPath: index_path)
      tv.beginUpdates
      tv.deleteRowsAtIndexPaths([index_path], withRowAnimation: UITableViewRowAnimationAutomatic)
      #delete action
      item = index_path.row
      #remove from scene
      @state.scenes[@state.currentscene].actions.delete_if { |action|
        action == @toy_actions.at(item)
      }
      #remove from toy
      @selected.template.actions.delete_if { |action|
        action == @toy_actions.at(item)
      }
      @toy_actions.delete_at(item)
      tv.endUpdates
    end

    def tableView(tv, numberOfRowsInSection: section)
      @toy_actions.length
    end

    def drawText(text, inImage:image)
      font = UIFont.fontWithName('Courier New', size: 20)
      UIGraphicsBeginImageContext(image.size)
      image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
      rect = CGRectMake(image.size.width/9, image.size.height/2.75, image.size.width, image.size.height)
      UIColor.blackColor.set
      text.drawInRect(CGRectIntegral(rect), withFont:font)
      newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      newImage
    end

    def tableView(tv, cellForRowAtIndexPath: index_path)
      item = index_path.row # ignore section as only one

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
          action_cell.action_image = UIImage.imageNamed("timer.png")
          # action_cell.action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
          #show how often in object view
          textImage = drawText(action[:action_param][0].to_s.rjust(2, "0") + ':' + action[:action_param][1].to_s.rjust(2, "0"), inImage:UIImage.imageNamed("empty.png") )
          action_cell.object_image = textImage
        when :button
          action_cell.action_image = UIImage.imageNamed("touch.png")
          action_cell.object_image = UIImage.imageNamed(action[:action_param]+ ".png")
      end

      action_cell.effect_image = UIImage.imageNamed(action[:effect_type]+".png")

      action_cell

    end

    def tableView(tv, didSelectRowAtIndexPath: index_path)
      item = index_path.row
      puts "Selected row "
    end

    # def tableView(tableView, titleForHeaderInSection:section)
    #   return "   Trigger                        Object                          Effect"
    # end

end