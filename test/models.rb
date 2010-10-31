require "callbacks_support"

class Person
  include MongoMapper::Document
  include CallbacksSupport

  key :name, String
  many :pets
  one :favorite_pet, :class_name=>'Pet'


end

class ValidatedPerson < Person
  validates_presence_of :name
  one :validated_pet
  many :validated_pets
end

class Pet
  include MongoMapper::EmbeddedDocument
  include CallbacksSupport
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

