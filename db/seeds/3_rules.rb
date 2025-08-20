# Rules seed file for Maybe Finance
# This file creates transaction categorization rules based on merchant names

# Define the merchant to category mappings from go.md
MERCHANT_CATEGORY_MAPPINGS = [
  # Food: Groceries
  [ "BRUTTO", "Food: Groceries" ],
  [ "EVROOPT", "Food: Groceries" ],
  [ "EUROOPT", "Food: Groceries" ],
  [ "SOSEDI", "Food: Groceries" ],
  [ "SANTA", "Food: Groceries" ],
  [ "Gipermarket Gippo", "Food: Groceries" ],
  [ "MINSK GIPPO", "Food: Groceries" ],
  [ "GIPERMARKET \"KORONA\"", "Food: Groceries" ],
  [ "SEM PYATNITS", "Food: Groceries" ],
  [ "OOO Mir vody", "Food: Groceries" ],
  [ "BARANOVICHI UNIVERSAM", "Food: Groceries" ],
  [ "VINO AND VINO", "Food: Groceries" ],
  [ "BELMARKET", "Food: Groceries" ],
  [ "SUPERMARKET \"GREEN\" BAPB", "Food: Groceries" ],
  [ "Retail BLR MINSK UNIVERSAM", "Food: Groceries" ],
  [ "Fankafe", "Food: Groceries" ],
  [ "MINSK SHOP \"KRASN.PISCHEVIK\" N", "Food: Groceries" ],
  [ "MINSK SHOP \"GROSHYK\"", "Food: Groceries" ],
  [ "Minsk OOO Dzhon Dori", "Food: Groceries" ],
  [ "ZABKA", "Food: Groceries" ],

  # Food: Eating Out
  [ "COFIX", "Food: Eating Out" ],
  [ "BURGER KING", "Food: Eating Out" ],
  [ "KFC", "Food: Eating Out" ],
  [ "NEORESTOR", "Food: Eating Out" ],
  [ "DOMINO'SPIZZA", "Food: Eating Out" ],
  [ "WWW.PZZ.BY", "Food: Eating Out" ],
  [ "PIT-STOP TTS KORONA", "Food: Eating Out" ],
  [ "ZOLOTOY GREBESH", "Food: Eating Out" ],
  [ "WWW.DODOPIZZA.BY", "Food: Eating Out" ],
  [ "RAKOVSKIY BROVA", "Food: Eating Out" ],
  [ "SALATEIRA", "Food: Eating Out" ],
  [ "KOKOS", "Food: Eating Out" ],
  [ "WWW.GODZILLA.BY", "Food: Eating Out" ],
  [ "KINOTEATR \"MOOON PALAZZO\"", "Food: Eating Out" ],
  [ "ALORFALI VAEL", "Food: Eating Out" ],
  [ "RESTORAN \"MONEMANE\"", "Food: Eating Out" ],
  [ "KAFE TERRA BSB", "Food: Eating Out" ],
  [ "MINI-KAFE KAFE 2", "Food: Eating Out" ],
  [ "FEELS", "Food: Eating Out" ],
  [ "BRADERFUD", "Food: Eating Out" ],
  [ "TRDLO", "Food: Eating Out" ],
  [ "PAPARATS-KVETKA", "Food: Eating Out" ],
  [ "DARLING", "Food: Eating Out" ],
  [ "Red Pill", "Food: Eating Out" ],
  [ "KITCHEN KOFE", "Food: Eating Out" ],
  [ "Restoran FABRIQ", "Food: Eating Out" ],
  [ "WOMENS ROOM", "Food: Eating Out" ],
  [ "KAFE D", "Food: Eating Out" ],
  [ "INTERNET-RESURS GARAGE", "Food: Eating Out" ],
  [ "RESTORAN FIORI", "Food: Eating Out" ],
  [ "KSB Viktori Restorany", "Food: Eating Out" ],
  [ "RESTORAN BISTRO 12", "Food: Eating Out" ],
  [ "RESTORAN RONIN", "Food: Eating Out" ],
  [ "KAFETERIY \"TERRI\" BAPB", "Food: Eating Out" ],
  [ "LET IT BE", "Food: Eating Out" ],
  [ "PON PUSHKA", "Food: Eating Out" ],
  [ "PON-PUSHKA", "Food: Eating Out" ],
  [ "BLUR", "Food: Eating Out" ],
  [ "PENA DNEY", "Food: Eating Out" ],
  [ "RESTORAN HINKALNYA", "Food: Eating Out" ],
  [ "SHI CIYA", "Food: Eating Out" ],
  [ "KARTOFFEL - PASTA BA", "Food: Eating Out" ],
  [ "Panskiy Dranik", "Food: Eating Out" ],
  [ "RESTORAN \"CONTRAST\" BAPB", "Food: Eating Out" ],
  [ "RESTORAN MELOGRANO", "Food: Eating Out" ],
  [ "Kinza", "Food: Eating Out" ],
  [ "ZEFIRKIBEL", "Food: Eating Out" ],
  [ "GRAND CAFE", "Food: Eating Out" ],
  [ "KOFEYNYA DVOYNOY", "Food: Eating Out" ],
  [ "Unitarnoe predpriyatie", "Food: Eating Out" ],
  [ "PAPADONER ", "Food: Eating Out" ],
  [ "TEHASSK.KUROCHKA ", "Food: Eating Out" ],
  [ "KAFE MISHELY", "Food: Eating Out" ],
  [ "MINSK MILANOCAFE ", "Food: Eating Out" ],
  [ "VASILKI", "Food: Eating Out" ],
  [ "BAR REST.OTEL\"NA ZAMKOVOY ", "Food: Eating Out" ],
  [ "G.MINSK BISTRO BENEDICT", "Food: Eating Out" ],
  [ "OOO Kafe Smetana", "Food: Eating Out" ],
  [ "MINSK LUNA-PRODZHEKT3", "Food: Eating Out" ],
  [ "MINSK PIZZERIYA BSB", "Food: Eating Out" ],
  [ "G.MINSK KOFEYNYA", "Food: Eating Out" ],
  [ "MINSK PIZZERIYA PIZZA YOLO", "Food: Eating Out" ],
  [ "MINSK RESTORAN SAKAGUCHI BSB", "Food: Eating Out" ],
  [ "MINSK MINI-KAFE PADTAY-GRUPP", "Food: Eating Out" ],
  [ "MINSK RESTORAN VAFEEL PARITET", "Food: Eating Out" ],
  [ "G.MINSK SMALL HEATH BAR", "Food: Eating Out" ],
  [ "MINSK KAFE \"GRIL-KEBAB\"", "Food: Eating Out" ],
  [ "MINSK WWW.GRILLKEBAB.BY", "Food: Eating Out" ],
  [ "BRO BAKERY", "Food: Eating Out" ],
  [ "MOBY DICK CAFFE", "Food: Eating Out" ],
  [ "Minsk Restoran Ramiz", "Food: Eating Out" ],
  [ "Minsk Mini-kafe Godzilla", "Food: Eating Out" ],
  [ "Coffee Embassy", "Food: Eating Out" ],
  [ "RESTORAN LICHI", "Food: Eating Out" ],
  [ "Minsk Kafe News Cafe", "Food: Eating Out" ],

  # Lifestyle: Subscriptions
  [ "Patreon", "Lifestyle: Subscriptions" ],
  [ "YouTubePremium", "Lifestyle: Subscriptions" ],
  [ "Netflix.com", "Lifestyle: Subscriptions" ],

  # Lifestyle & Entertainment
  [ "SILVERSCREEN", "Lifestyle & Entertainment" ],
  [ "HOBBY GAMES", "Lifestyle & Entertainment" ],
  [ "Steam ", "Lifestyle & Entertainment" ],
  [ "STEAMGAMES.COM", "Lifestyle & Entertainment" ],
  [ "PP K-R \"MOOON DANA MALL\"", "Lifestyle & Entertainment" ],
  [ "INTERNET-RESURS MOOON.BY", "Lifestyle & Entertainment" ],

  # Shopping
  [ "WILDBERRIES", "Shopping" ],

  # Salary (Income)
  [ "Поступление на контракт клиента", "Salary" ],

  # Car: Gas
  [ "AZS", "Car: Gas" ],

  # Car: Auto Maintenance
  [ "ARMTEK", "Car: Auto Maintenance" ],
  [ "OOO LARSKI GRUPP", "Car: Wash" ],

  # Car: Parking & Tolls
  [ "Avtomobilnyy parking TRK", "Car: Parking & Tolls" ],

  # Transportation: Taxi
  [ "YANDEX.GO", "Transportation: Taxi" ],

  # Transportation
  [ "HELLO ", "Transportation" ],
  [ "MINSK HELLO", "Transportation" ],
  [ "MINSK WHOOSH.BIKE", "Transportation" ],

  # Personal: Grooming & Haircuts
  [ "MUZHSKOY SALON GENTS", "Personal: Grooming & Haircuts" ],
  [ "MINSK BARBERSHOP BROCK", "Personal: Grooming & Haircuts" ],

  # Health: Healthcare & Medical
  [ "APTEKA", "Health: Healthcare & Medical" ],

  # Sport & Fitness
  [ "LOGOYSKIY R-N PUNKT PROKATA", "Sport & Fitness" ],
  [ "OOO Yoga Pleys", "Sport & Fitness" ],
  [ "MINSK WAKEFAMILY", "Sport & Fitness" ],

  # Financial: Bank & Card Fees
  [ "Отправка SMS Monthly (CMC.PRO)", "Financial: Bank & Card Fees" ]
]

def create_rules_for_family(family)
  puts "Creating rules for family: #{family.name || 'Unnamed Family'} (ID: #{family.id})"

  created_count = 0
  skipped_count = 0

  MERCHANT_CATEGORY_MAPPINGS.each do |merchant_name, category_name|
    # Find the category
    category = family.categories.find_by(name: category_name)
    unless category
      puts "  ⚠️  Category '#{category_name}' not found for merchant '#{merchant_name}' - skipping"
      skipped_count += 1
      next
    end

    # Check if rule already exists for this merchant
    existing_rule = family.rules.joins(:conditions)
                           .where(resource_type: "transaction")
                           .where(conditions: { condition_type: "transaction_name", operator: "like", value: merchant_name })
                           .first

    if existing_rule
      puts "  ⚠️  Rule for merchant '#{merchant_name}' already exists - skipping"
      skipped_count += 1
      next
    end

    # Create the rule with conditions and actions in one transaction
    family.rules.create!(
      name: "Prior auto-categorize #{merchant_name}",
      resource_type: "transaction",
      active: true,
      conditions_attributes: [
        {
          condition_type: "transaction_name",
          operator: "like",
          value: merchant_name
        }
      ],
      actions_attributes: [
        {
          action_type: "set_transaction_category",
          value: category.id.to_s
        }
      ]
    )

    puts "  ✅ Created rule for '#{merchant_name}' → '#{category_name}'"
    created_count += 1
  rescue => e
    puts "  ❌ Error creating rule for '#{merchant_name}': #{e.message}"
    skipped_count += 1
  end

  puts "✨ Created #{created_count} new rules, skipped #{skipped_count} for #{family.name || 'this family'}!"
  { created: created_count, skipped: skipped_count }
end

# Main seed execution
puts "🌱 Seeding rules for all families..."
puts "=" * 60

total_created = 0
total_skipped = 0
families_with_rules = 0

Family.find_each do |family|
  result = create_rules_for_family(family)
  total_created += result[:created]
  total_skipped += result[:skipped]
  families_with_rules += 1 if result[:created] > 0
  puts "-" * 40
end

puts "=" * 60
puts "🎉 Rules seeding completed!"
puts "📊 Summary:"
puts "  • Total families processed: #{Family.count}"
puts "  • Families with new rules: #{families_with_rules}"
puts "  • Total rules created: #{total_created}"
puts "  • Total rules skipped: #{total_skipped}"
puts ""
puts "💡 Note: Rules will automatically categorize transactions based on merchant names."
puts "   Run 'Rule.find_each(&:apply)' to apply rules to existing transactions."
