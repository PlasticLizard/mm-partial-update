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

  end
end
