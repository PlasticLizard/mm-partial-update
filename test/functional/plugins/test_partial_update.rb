require 'test_helper'
require "models"

Time.zone = "UTC"

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

    should "persist changes made during before_save" do
      person = Person.create! :name=>"Willard!"
      person.ensure_me = nil
      person.save_changes
      person.reload
      person.ensure_me.should == "here i am!"
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

  context "#save_changes!" do

    should "raise an exception if the document isn't valid" do
      person = ValidatedPerson.new
      assert_raise(MongoMapper::DocumentNotValid) { person.save_changes! }
    end

    should "not raise an exception if the document is valid" do
      person = ValidatedPerson.new :name=>"Willard"
      assert_nothing_thrown { person.save_changes! }
    end

    should "raise an exception when saving an embedded document that isn't valid" do
      person = ValidatedPerson.create! :name=>"Willard"
      pet = person.validated_pets.build
      assert_raise(MongoMapper::DocumentNotValid) {pet.save_changes!}
    end

    should "raise an exception when saving an embedded 'one' document that isn't valid" do
      person = ValidatedPerson.create! :name=>"Willard"
      pet = person.validated_pet.build
      assert_raise(MongoMapper::DocumentNotValid) {pet.save_changes!}
    end

  end

  context "callbacks" do

    should "happen for new top level documents" do
      p = Person.new :name=>"Willard"
      p.clear_history
      p.save_changes
      p.history.should == [:before_validation, :after_validation,
                           :before_save, :before_create, :after_create, :after_save]
    end

    should "happen for updated top level documents" do
      p = Person.create :name=>"Willard"
      p.clear_history
      p.name = "Timmy"
      p.save_changes
      p.history.should == [:before_validation, :after_validation,
                           :before_save, :before_update, :after_update, :after_save]
    end

    should "happen for new embedded documents" do
      p = Person.create :name=>"Willard"
      pet = p.pets.build :name=>"Magma"
      pet.clear_history
      pet.save_changes
      pet.history.should == [:before_validation, :after_validation,
                             :before_save, :before_create, :after_create, :after_save]
    end

    should "happen for updated embedded documents" do
      p = Person.new :name=>"Willard"
      pet = p.pets.build :name=>"Magma"
      p.save!
      pet.clear_history
      pet.name = "Debris"
      pet.save_changes
      pet.history.should == [:before_validation, :after_validation,
                             :before_save, :before_update, :after_update, :after_save]
    end
  end

  context "Non-embedded associations" do
    should 'be business as usual' do
      p = Person.new :name=>"Willard"
      p.happy_place = HappyPlace.new :description=>"A cool breeze rustles my hair as terradactyls glide gracefully overhead"
      p.save_changes!
      p.reload
      p.happy_place.should_not be_nil
    end
  end

  context "multiple save - load operations" do
    should "be business as usual" do
      hp = HappyPlace.create! :description=>"Hi there"
      hp1 = HappyPlace.find(hp.id)
      hp2 = HappyPlace.find(hp.id)
      hp1.description = "ho"
      hp2.description = "hi"
      hp2.save!
      hp1.save!
      hp.reload
      hp.description.should == "ho"
    end
  end

end
