# This file creates income and expense categories for all families

# Define the income categories to create
INCOME_CATEGORIES = [
  {
    name: "Salary",
    lucide_icon: "banknote",
    classification: "income",
    color: "#4da568"  # Green for salary
  },
  {
    name: "Other Income",
    lucide_icon: "coins",
    classification: "income",
    color: "#61c9ea"  # Light blue for other income
  }
]

# Define the expense categories to create
EXPENSE_CATEGORIES = [
  {
    name: "Housing & Utilities",
    lucide_icon: "home",
    classification: "expense",
    parent: nil,
    color: "#6471eb"  # Blue for housing & utilities
  },
  {
    name: "Home: Rent",
    lucide_icon: "key",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Property Tax",
    lucide_icon: "receipt",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Maintenance",
    lucide_icon: "wrench",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Communal services",
    lucide_icon: "building-2",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: HOA",
    lucide_icon: "fence",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Electric",
    lucide_icon: "zap",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Internet",
    lucide_icon: "wifi",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Phone",
    lucide_icon: "smartphone",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Home: Home Insurance",
    lucide_icon: "shield-check",
    classification: "expense",
    parent: "Housing & Utilities"
  },
  {
    name: "Food & Dining",
    lucide_icon: "utensils",
    classification: "expense",
    parent: nil,
    color: "#eb5429"  # Red-orange for food & dining
  },
  {
    name: "Food: Groceries",
    lucide_icon: "shopping-basket",
    classification: "expense",
    parent: "Food & Dining"
  },
  {
    name: "Food: Eating Out",
    lucide_icon: "chef-hat",
    classification: "expense",
    parent: "Food & Dining"
  },
  {
    name: "Car",
    lucide_icon: "car",
    classification: "expense",
    parent: nil,
    color: "#df4e92"  # Pink for Car
  },
  {
    name: "Car: Auto Insurance",
    lucide_icon: "shield",
    classification: "expense",
    parent: "Car"
  },
  {
    name: "Car: Gas",
    lucide_icon: "fuel",
    classification: "expense",
    parent: "Car"
  },
  {
    name: "Car: Auto Maintenance",
    lucide_icon: "wrench",
    classification: "expense",
    parent: "Car"
  },
  {
    name: "Car: Parking & Tolls",
    lucide_icon: "parking-circle",
    classification: "expense",
    parent: "Car"
  },
  {
    name: "Car: Wash",
    lucide_icon: "droplets",
    classification: "expense",
    parent: "Car"
  },
  {
    name: "Transportation",
    lucide_icon: "bus",
    classification: "expense",
    parent: nil,
    color: "#f59e0b"  # Yellow for Transportation
  },
  {
    name: "Transportation: Public Transit",
    lucide_icon: "bus",
    classification: "expense",
    parent: "Transportation"
  },
  {
    name: "Transportation: Taxi",
    lucide_icon: "car-taxi-front",
    classification: "expense",
    parent: "Transportation"
  },
  {
    name: "Health & Wellness",
    lucide_icon: "heart",
    classification: "expense",
    parent: nil,
    color: "#4da568"  # Green for health & wellness
  },
  {
    name: "Health: Healthcare & Medical",
    lucide_icon: "stethoscope",
    classification: "expense",
    parent: "Health & Wellness"
  },
  {
    name: "Health: Dentist",
    lucide_icon: "smile",
    classification: "expense",
    parent: "Health & Wellness"
  },
  {
    name: "Personal",
    lucide_icon: "user",
    classification: "expense",
    parent: nil,
    color: "#c44fe9"  # Purple for personal
  },
  {
    name: "Personal: Grooming & Haircuts",
    lucide_icon: "scissors",
    classification: "expense",
    parent: "Personal"
  },
  {
    name: "Personal: Skincare & Cosmetics",
    lucide_icon: "sparkles",
    classification: "expense",
    parent: "Personal"
  },
  {
    name: "Family",
    lucide_icon: "users",
    classification: "expense",
    parent: nil,
    color: "#805dee"  # Dark purple for family
  },
  {
    name: "Family: Dasha's Spending",
    lucide_icon: "heart-handshake",
    classification: "expense",
    parent: "Family"
  },
  {
    name: "Lifestyle & Entertainment",
    lucide_icon: "gamepad-2",
    classification: "expense",
    parent: nil,
    color: "#e99537"  # Orange for lifestyle & entertainment
  },
  {
    name: "Lifestyle: Subscriptions",
    lucide_icon: "repeat",
    classification: "expense",
    parent: "Lifestyle & Entertainment"
  },
  {
    name: "Lifestyle: Entertainment & Recreation",
    lucide_icon: "drama",
    classification: "expense",
    parent: "Lifestyle & Entertainment"
  },
  {
    name: "Lifestyle: Dog",
    lucide_icon: "dog",
    classification: "expense",
    parent: "Lifestyle & Entertainment"
  },
  {
    name: "Sport & Fitness",
    lucide_icon: "activity",
    classification: "expense",
    parent: nil,
    color: "#f43f5e"  # Pink for sport & fitness
  },
  {
    name: "Travel & Vacation",
    lucide_icon: "plane",
    classification: "expense",
    parent: nil,
    color: "#61c9ea"  # Light blue for travel & vacation
  },
  {
    name: "Travel: Booking & Transportation",
    lucide_icon: "ticket",
    classification: "expense",
    parent: "Travel & Vacation"
  },
  {
    name: "Travel: On-Trip Spending",
    lucide_icon: "map-pin",
    classification: "expense",
    parent: "Travel & Vacation"
  },
  {
    name: "Travel: Preparation & Other Costs",
    lucide_icon: "luggage",
    classification: "expense",
    parent: "Travel & Vacation"
  },
  {
    name: "Financial, Legal & Business",
    lucide_icon: "briefcase",
    classification: "expense",
    parent: nil,
    color: "#6ad28a"  # Light green for financial, legal & business
  },
  {
    name: "Financial: Bank & Card Fees",
    lucide_icon: "credit-card",
    classification: "expense",
    parent: "Financial, Legal & Business"
  },
  {
    name: "Shopping",
    lucide_icon: "shopping-bag",
    classification: "expense",
    parent: nil,
    color: "#db5a54"  # Red for shopping
  },
  {
    name: "Shopping: Clothing",
    lucide_icon: "shirt",
    classification: "expense",
    parent: "Shopping"
  },
  {
    name: "Shopping: Electronics",
    lucide_icon: "cable",
    classification: "expense",
    parent: "Shopping"
  },
  {
    name: "Gifts & Donations",
    lucide_icon: "gift",
    classification: "expense",
    parent: nil,
    color: "#61c9ea"  # Blue for gifts & donations
  }
]

def create_categories_for_family(family)
  puts "Creating categories for family: #{family.name || 'Unnamed Family'} (ID: #{family.id})"

  # Get available colors (cycle through them)
  available_colors = Category::COLORS.cycle
  created_count = 0

  # Create income categories first
  puts "📈 Creating Income Categories:"
  INCOME_CATEGORIES.each do |category_data|
    created_count += create_category(family, category_data, available_colors)
  end

  # Create expense categories (parent first, then subcategories)
  puts "💸 Creating Expense Categories:"

  # First create the parent categories
  parent_categories = EXPENSE_CATEGORIES.select { |cat| cat[:parent].nil? }
  parent_categories.each do |category_data|
    created_count += create_category(family, category_data, available_colors)
  end

  # Then create subcategories
  subcategories = EXPENSE_CATEGORIES.select { |cat| cat[:parent].present? }
  subcategories.each do |category_data|
    created_count += create_category(family, category_data, available_colors)
  end

  puts "✨ Created #{created_count} new categories for #{family.name || 'this family'}!"
  created_count
end

def create_category(family, category_data, available_colors)
  # Check if category already exists for this family
  existing_category = family.categories.find_by(name: category_data[:name])

  if existing_category
    puts "  ⚠️  Category '#{category_data[:name]}' already exists - skipping"
    return 0
  end

  # Find parent category if specified
  parent_category = nil
  if category_data[:parent]
    parent_category = family.categories.find_by(name: category_data[:parent])
    unless parent_category
      puts "  ❌ Parent category '#{category_data[:parent]}' not found for '#{category_data[:name]}' - skipping"
      return 0
    end
  end

  # Determine color: use specified color, inherit from parent, or use next available color
  color = if category_data[:color]
    category_data[:color]
  elsif parent_category
    parent_category.color
  else
    available_colors.next
  end

  # Create the category
  category = family.categories.create!(
    name: category_data[:name],
    color: color,
    lucide_icon: category_data[:lucide_icon],
    classification: category_data[:classification],
    parent: parent_category
  )

  indent = parent_category ? "    " : "  "
  puts "#{indent}✅ Created: #{category.name} (#{category.color})"
  1
rescue => e
  puts "  ❌ Error creating category '#{category_data[:name]}': #{e.message}"
  0
end

# Main seed execution
puts "🌱 Seeding categories for all families..."
puts "=" * 60

total_created = 0
families_with_categories = 0

Family.find_each do |family|
  created_count = create_categories_for_family(family)
  total_created += created_count
  families_with_categories += 1 if created_count > 0
  puts "-" * 40
end

puts "=" * 60
puts "🎉 Categories seeding completed!"
puts "📊 Summary:"
puts "  • Total families processed: #{Family.count}"
puts "  • Families with new categories: #{families_with_categories}"
puts "  • Total categories created: #{total_created}"
