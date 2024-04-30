class DriverSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :home_address
end
