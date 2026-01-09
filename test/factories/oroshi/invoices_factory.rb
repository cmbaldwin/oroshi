# frozen_string_literal: true

FactoryBot.define do
  factory :oroshi_invoice, class: 'Oroshi::Invoice' do
    start_date { Time.zone.today.beginning_of_month }
    end_date { Time.zone.today }
    send_email { [true, false].sample }
    send_at { Time.zone.now + 1.hour }
    sent_at { Time.zone.now + 2.hours }
    invoice_layout { Oroshi::Invoice.invoice_layouts.keys.sample }
    supplier_organizations do
      if Oroshi::SupplierOrganization.any?
        Oroshi::SupplierOrganization.active.by_supplier_count.sample(rand(1..3))
      else
        create_list(:oroshi_supplier_organization, rand(1..3))
      end
    end

    trait :with_supply_dates do
      after(:create) do |invoice|
        (1..rand(1..3)).each do
          date = FFaker::Time.between(invoice.start_date, invoice.end_date)
          next if Oroshi::SupplyDate.exists?(date: date)

          supply_date = create(:oroshi_supply_date, date: date)

          # Create supplies with suppliers from the invoice's supplier organizations
          invoice.supplier_organizations.each do |supplier_org|
            supplier = supplier_org.suppliers.sample || create(:oroshi_supplier, supplier_organization: supplier_org)
            create(:oroshi_supply, supply_date: supply_date, supplier: supplier)
          end

          invoice.supply_dates << supply_date
        end
      end
    end
  end
end
