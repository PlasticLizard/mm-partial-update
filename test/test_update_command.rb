require "test_helper"

class TestUpdateCommand < Test::Unit::TestCase

  context "UpdateCommand" do
    setup do
      @edoc = EDoc { key :name, String }
      @doc = Doc { key :name, String }
      @doc.many :children, :class=>@edoc

      @command = MmPartialUpdate::UpdateCommand.new(@doc.new)
      @defaults = {"a_field"=>2, "another_field"=>2}
      @command.set nil, @defaults
    end

    context "#document_selector" do
      should "be derived from the id of the root document" do
        doc = @doc.new
        edoc = doc.children.build
        MmPartialUpdate::UpdateCommand.new(doc).document_selector.should == {:_id=>doc._id}
        MmPartialUpdate::UpdateCommand.new(edoc).document_selector.should == {:_id=>doc._id}
      end
    end

    context "#set" do

      context "with a blank selector and replace = true" do
        should "set the fields hash directly onto $set" do
          @command.set(nil, {"a_different_field"=>3}, :replace=>{})
          @command.to_h["$set"].should == {"a_different_field"=>3}
        end
      end

      context "with a blank selector" do
        should "merge the fields hash directly into $set" do
          @command.set nil, {"a_different_field"=>3}
          @command.to_h["$set"].should == {"a_different_field"=>3}.merge(@defaults)
        end
      end

      context "with replace = true" do
        should "replace the key at 'selector' with the fields hash" do
          @command.set "sel", {"this"=>:that}
          @command.set "sel", {"that"=>:this}, :replace=>true
          @command.to_h["$set"]["sel"].should == {"that"=>:this}
        end
      end

      context "with a selector and replace = false" do
        should "merge each key of fields into $set, namespaced with the selector" do
          @command.set "sel", {"that"=>:this, "the"=>:other}
          @command.to_h["$set"].should == {"sel.that"=>:this, "sel.the"=>:other}.merge(@defaults)
          @command.set "sel", {"that"=>:not_this, "b"=>:c}
          @command.to_h["$set"].should == {"sel.that" => :not_this, "sel.the"=>:other,"sel.b"=>:c}.merge(@defaults)
        end
      end

    end

    context "#unset" do
      should "add the selector to the $unset hash" do
        @command.unset "a_field"
        @command.to_h["$unset"].should == {"a_field"=>true}
      end

      should "nullify a field when :nullify=>true" do
        @command.unset "a_field", :nullify=>true
        @command.to_h["$set"].should == @defaults.merge("a_field"=>nil)
      end

    end

    context "#push" do
      should "add the field hash to the $pushAll array for the selector" do
        @command.push "a_collection", {"a"=>:b, "c"=>:d}
        @command.to_h[:pushes].should == {"a_collection" => [{"a"=>:b, "c"=>:d}]}
      end

      should "append the field hash to the$pushAll array for the selector" do
        @command.push "a_collection", {"a"=>:b, "c"=>:d}
        @command.push "a_collection", {"a"=>:e, "f"=>:g}
        @command.to_h[:pushes].should == {"a_collection" => [{"a"=>:b, "c"=>:d},
                                                                {"a"=>:e, "f"=>:g}]}
        end
    end

    context "#pull" do
      should "add the document id to the $pull array for the selector" do
        @command.pull "a_collection", "123"
        @command.to_h[:pulls].should == {"a_collection" => ["123"]}
      end

      should "append the doc id to the $pull array for the selector" do
        @command.pull "a_collection", "123"
        @command.pull "a_collection", "456"
        @command.to_h[:pulls].should == {"a_collection" => ["123","456"]}
      end
    end

    context "#merge" do
      should "merge the commands hash with an incoming UpdateCommand" do
        another = MmPartialUpdate::UpdateCommand.new(@doc.new)
        another.set "this", {"that"=>"the other"}
        another.unset "me"
        another.push "a", {"a"=>:b}
        another.pull "b", "c"
        @command.merge(another).should == @command.to_h.merge(another.to_h)
      end
    end

    context "#prepare_mongodb_commands" do
      should "separate operations into sets, pulls and pushes" do
        @command.set "a", {:b=>2}
        @command.set "a.c", {"c"=>"d"}
        @command.push "hi", {:ho=>true}
        @command.push "hi", {:snack=>"yummy"}
        @command.push "ho", {:cheeri=>0}
        @command.pull "zig", "zag"
        db_commands = @command.send(:prepare_mongodb_commands)
        db_commands.length.should == 4

        db_commands[0].should == {"$set"=>{"a.b"=>2, "a.c.c"=>"d"}.merge(@defaults)}
        db_commands[1].should == {"$pull"=>{"zig"=>{"_id"=>{"$in"=>["zag"]}}}}
        db_commands[2].should == {"$pushAll"=>{"hi"=>[{:ho=>true},{:snack=>"yummy"}]}}
        db_commands[3].should == {"$pushAll"=>{"ho"=>[{:cheeri=>0}]}}
      end

    end


  end
end

