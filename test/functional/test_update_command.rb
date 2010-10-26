require "test_helper"
require "models"

class TestUpdateCommand < Test::Unit::TestCase

  context "#execute" do
    setup do
      @person = Person.new
      @command = MmPartialUpdate::UpdateCommand.new(@person)
    end

    context "with no commands" do
      should "do nothing" do
        @command.execute
        Person.find(@person.id).should be_nil
      end
    end

    context "on a new document" do
      should "create a document if it doesn't previouly exist" do
        @command.set nil,"a_value"=>"for you"
        @command.execute
        (person = Person.find(@person.id)).should_not be_nil
        person.a_value.should == "for you"
      end
    end

    context "on an existing document" do
      should "update the existing document" do
        @person.save!
        @command.set nil, "another_value"=>"in the house"
        @command.execute
        (person = Person.find(@person.id)).should_not be_nil
      end

      should "preserve previous values" do
        @person["a_value"] = "was here"
        @person.save!
        @command.set nil, "another_value"=>"in the house"
        @command.execute
        (person = Person.find(@person.id)).should_not be_nil
        person.a_value.should == "was here"
      end

      context "#set" do
        should "set a variety of direct keys on the document" do
          @command.set nil, "a"=>"b", "c"=>1, "d"=>[1,2,3]
          @command.execute
          person = Person.find(@person.id)
          person.a.should == "b"
          person.c.should == 1
          person.d.should == [1,2,3]
        end

        should "create sub-objects" do
          @command.set "favorite_pet", Pet.new(:name=>"Magma", :age=>3).to_mongo
          @command.execute
          @person.reload
          @person.favorite_pet.should_not be_nil
          @person.favorite_pet.name.should == "Magma"
          @person.favorite_pet.age.should == 3
        end

        should "update sub-objects" do
          pet = @person.favorite_pet.build :name=>"Magma"
          @person.save!
          @command.set "favorite_pet", {:name=>"Timmy"}
          @command.execute
          @person.reload
          @person.favorite_pet.name.should == "Timmy"
        end

        should "expand sub-objects" do
          pet = @person.favorite_pet.build :name=>"Magma"
          @person.save!
          @command.set "favorite_pet", {:age=>9}
          @command.execute
          @person.reload
          @person.favorite_pet.age.should == 9
        end

        should "create deep objects" do
          pet = @person.favorite_pet.build :name=>"Magma"
          @person.save!
          @command.set "favorite_pet.favorite_flea", Flea.new(:name=>"Fleatus").to_mongo, :replace=>true
          @command.execute
          @person.reload
          @person.favorite_pet.favorite_flea.should_not be_nil
          @person.favorite_pet.favorite_flea.name.should == "Fleatus"
        end

        should "update deep objects" do
          pet = @person.favorite_pet.build :name=>"Magma"
          flea = pet.favorite_flea.build :name=>"Fleatus"
          @person.save!
          @command.set "favorite_pet.favorite_flea", {:name=>"Fleatasia"}
          @command.execute
          @person.reload
          @person.favorite_pet.favorite_flea.name.should == "Fleatasia"
        end

        should "update objects in arrays" do
          @person.pets.build(:name=>"Magma")
          @person.save!
          @command.set "pets.0", {:name=>"Timmy"}
          @command.execute
          @person.reload
          @person.pets[0].name.should == "Timmy"
        end


      end


    end


  end

end
