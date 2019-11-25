namespace :products do
  task refresh_prices: :environment do
    Product.find_each do |product|
      begin
        price = Pwinty.prices(country_code: "US", skus: [product.sku])["prices"].first
        usd_price = Money.new(price["price"], price["currency"]).exchange_to("USD")
        price = [(usd_price.fractional * 1.2 / 10).round * 10 - 0.01, 1.89].min
        product.update(price: price * 100)
      rescue => error
        puts error
      end
    end
  end
end