module Helio
  # Helio's customers: companies on a monthly plan. Made up, from a fixed seed,
  # so every visitor sees the same numbers. The example has no database.
  Customer = Data.define(:id, :company, :contact, :email, :plan, :status, :seats, :country, :signed_up_on, :last_active_on) do
    def self.all = Helio::Customer::ALL

    def self.find(id) = Helio::Customer::ALL.find { |customer| customer.id == id.to_i }

    # Monthly revenue now: trials and cancelled accounts pay nothing.
    def mrr = paying? ? list_price : 0

    def list_price = Helio::Customer::PLANS.fetch(plan) * seats

    # Paying on a given day: past its 14-day trial, and not yet gone. A
    # cancelled account's last day is the last time it was used.
    def paying_on?(date)
      return false if status == "trialing" || signed_up_on + Helio::Customer::TRIAL_DAYS > date

      status != "cancelled" || last_active_on > date
    end

    def cancelled_between?(range) = status == "cancelled" && range.cover?(last_active_on)

    def paying? = %w[active past_due].include?(status)

    def initials = contact.split.map { |part| part[0] }.join
  end

  # Price per seat, per month, in dollars.
  Customer::PLANS = { "Starter" => 12, "Team" => 24, "Business" => 48 }.freeze
  Customer::STATUSES = %w[active trialing past_due cancelled].freeze
  Customer::TRIAL_DAYS = 14
  Customer::TODAY = Date.new(2026, 11, 14)

  Customer::ALL = begin
    random   = Random.new(20_261_114)
    prefixes = %w[North Blue Cedar Quiet Bright Paper Stone Copper Field Harbor Maple Silver Lantern Orchard Summit
                  River Atlas Juniper Pine Meadow Willow Comet Falcon Linden Ember]
    suffixes = [ "Labs", "Studio", "Works", "Co", "Collective", "Systems", "Partners", "Supply", "Health", "Logistics",
                 "Analytics", "Design", "Foods", "Robotics", "Media" ]
    firsts   = %w[Ava Liam Maya Noah Zoe Omar Iris Leo Nina Arjun Sofia Mateo Hana Kofi Elena Yuki Sam Priya Lucas Amara
                  Felix Chloe Ravi Ines Tomas]
    lasts    = %w[Patel Chen Okafor Novak Rossi Silva Kim Haddad Larsen Moreau Tanaka Mensah Garcia Byrne Ivanova Shah
                  Mueller Costa Nakamura Adeyemi]
    countries = [ "United States", "United Kingdom", "Germany", "Canada", "India", "Australia", "France", "Brazil",
                  "Japan", "Netherlands", "Nigeria", "Spain" ]
    today    = Customer::TODAY

    names = prefixes.product(suffixes).shuffle(random: random).first(140)
    names.each_with_index.map do |(prefix, suffix), index|
      first = firsts.sample(random: random)
      last  = lasts.sample(random: random)
      company = "#{prefix} #{suffix}"
      signed_up = today - (random.rand**1.6 * 540).round
      status = case random.rand
      when 0...0.72 then "active"
      when 0.72...0.84 then "trialing"
      when 0.84...0.91 then "past_due"
      else "cancelled"
      end
      status = "trialing" if signed_up > today - 14
      plan = case random.rand
      when 0...0.45 then "Starter"
      when 0.45...0.85 then "Team"
      else "Business"
      end
      seats = plan == "Business" ? random.rand(10..40) : random.rand(2..25)
      last_active = status == "cancelled" ? today - random.rand(20..120) : today - (random.rand**3 * 20).round
      Customer.new(1001 + index, company, "#{first} #{last}", "#{first.downcase}@#{company.downcase.delete(' ')}.example",
          plan, status, seats, countries.sample(random: random), signed_up, [ last_active, signed_up ].max)
    end.sort_by(&:signed_up_on).reverse.freeze
  end
end
