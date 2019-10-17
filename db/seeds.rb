# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Product.destroy_all

[
  { name: "Small vinyl kisscut sticker",        dimensions: "3x4” / 7.6x10.1cm",      sku: "M-STI-3X4" },
  { name: "Medium vinyl kisscut sticker",       dimensions: "5.5x5.5” / 14x14cm",     sku: "M-STI-5_5X5_5" },
  { name: "Large vinyl kisscut sticker",        dimensions: "8.5x8.5” / 21.6x21.6cm", sku: "M-STI-8_5X8_5" },
  { name: "Extra large vinyl kisscut sticker",  dimensions: "14x14” / 35.6x35.6cm",   sku: "M-STI-14X14" },
].each.with_index do |attributes, order|
  Product.create(attributes.merge(order: order))
end
