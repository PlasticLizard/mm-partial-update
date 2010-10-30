require 'test_helper'
require "models"

class TestPartialUpdate < Test::Unit::TestCase
  context "#save_changes" do
    should "create unsaved entities" do
      person = Person.new :name=>"Willard"
      person.save_changes
      person.reload
      person.name.should == "Willard"
      person.new?.should be_false
    end

    should "update a saved entity" do
      person = Person.create! :name=>"Willard"
      person.name = "Esteban"
      person.save_changes
      person.reload
      person.name.should == "Esteban"
    end

    should "update changes to a saved entity, preserving unchanged values" do
      person = Person.new :name=>"Willard"
      person.pets.build :name=>"Magma", :age=>2
      person.save!
      person.name = "Esteban"
      person.save_changes
      person.reload
      person.name.should == "Esteban"
      person.pets.count.should == 1
      person.pets[0].name.should == "Magma"
      person.pets[0].age.should == 2
    end

    should "apply a variety of changes to a document graph" do
      person = Person.new :name=>"Willard"
      person.pets.build :name=>"Magma", :age=>3
      person.pets.build :name=>"Debris"
      person.pets.build :name=>"Timmy"
      person.pets[0].favorite_flea.build :name=>"Fleatus"
      person.pets[1].fleas.build :name=>"Fleatasia"
      person.pets[1].fleas.build :name=>"Dogen Zenji"
      person.favorite_pet.build :name=>"Soto", :age=>10_000
      person.save!

      person.pets.reject! {|p|p.name=="Timmy"}
      person.name = "Fydor"
      person.favorite_pet.age = 100_000
      person.pets[0].favorite_flea = nil
      person.pets[1].fleas[0].name = "The Horse Master"
      person.pets[1].fleas.build :name=>"Raskolnikov", :age=>80
      person.save_changes

      person.reload

      person.name.should == "Fydor"
      person.pets.count.should == 2
      person.pets[0].name.should == "Magma"
      person.pets[1].name.should == "Debris"
      person.pets[0].favorite_flea.should be_nil
      person.pets[1].fleas[0].name.should == "The Horse Master"
      person.favorite_pet.age.should == 100_000
      person.pets[1].fleas.count.should == 3
      person.pets[1].fleas[-1].name.should == "Raskolnikov"
      person.pets[1].fleas[-1].age.should == 80
    end

    context "with dirty tracking" do
      setup do
        @person = Person.new :name=>"Willard"
        @person.pets.build :name=>"Magma"
        @person.save_changes
      end

      should "clear new flags when changes are saved" do
        @person.new?.should be_false
      end

      should "clear new flags on descentends when changes are saved" do
        @person.pets[0].new?.should be_false
      end


      should "clear dirty tracking when changes are saved" do
        @person.changed?.should be_false
      end

      should "clear dirty tracking on descendents when changes are saved" do
        @person.pets[0].changed?.should be_false
      end
    end

  end
end
