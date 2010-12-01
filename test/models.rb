require "callbacks_support"

class Person
  include MongoMapper::Document
  include CallbacksSupport
  key :name, String
  many :pets
  one :happy_place
  one :favorite_pet, :class_name=>'Pet'

  timestamps!
end

class HappyPlace #Test non-embedded proxies
  include MongoMapper::Document

  persistence_strategy :changes_only

  key :description, String
  key :person_id, ObjectId
  belongs_to :person

  timestamps!
end

class ValidatedPerson < Person
  validates_presence_of :name
  one :validated_pet
  many :validated_pets
end

class Pet
  include MongoMapper::EmbeddedDocument
  include CallbacksSupport
  plugin MongoMapper::Plugins::Timestamps
  key :name, String
  key :age, Integer
  many :fleas
  one :favorite_flea, :class_name=>'Flea'
end

class ValidatedPet < Pet
  validates_presence_of :name
end

class Flea
  include MongoMapper::EmbeddedDocument
  key :name, String
end

