# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Product.destroy_all

[
  {
    name: "Small vinyl kisscut sticker",
    dimensions: "3x4” / 7.5x10cm",
    sku: "M-STI-3X4",
    price: 1.2
  }
].each.with_index do |attributes, order|
  Product.create(attributes.merge(order: order))
end
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?