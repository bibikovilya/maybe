puts "🌱 Seeding family data..."
puts "=" * 60

# Create or find the family
puts "👨‍👩‍👧‍👦 Creating/finding family: Bibikov&Stoliar"
family = Family.find_or_create_by(
  name: "Bibikov&Stoliar",
  currency: "USD",
  locale: "en",
  country: "US",
  timezone: "Europe/Minsk",
  date_format: "%d.%m.%Y"
)

if family.persisted?
  puts "  ✅ Family created/found successfully (ID: #{family.id})"
else
  puts "  ❌ Error creating family"
  exit 1
end

# Start subscription if not already active
puts "💳 Setting up subscription..."
if family.has_active_subscription?
  puts "  ⚠️  Subscription already active - skipping"
else
  family.start_subscription!("local_subscription")
  puts "  ✅ Local subscription activated"
end

# Create or find the admin user
puts "👤 Creating/finding admin user: Ilya Bibikov"
user = family.users.find_or_initialize_by(email: "ilya023@gmail.com") do |u|
  u.first_name = "Ilya"
  u.last_name = "Bibikov"
  u.role = "admin"
  u.password = "password"
  u.onboarded_at = Time.current
  u.show_ai_sidebar = false
end

# Check if user already exists
if user.persisted?
  puts "  ✅ User found (ID: #{user.id})"
else
  puts "  🆕 Creating new user..."
end

# Ensure the user is saved
unless user.save
  puts "  ❌ Error creating user: #{user.errors.full_messages.join(', ')}"
  exit 1
end

puts "=" * 60
puts "🎉 Family seeding completed!"
puts "📊 Summary:"
puts "  • Family: #{family.name} (#{family.currency})"
puts "  • Admin User: #{user.first_name} #{user.last_name} (#{user.email})"
puts "  • Subscription: #{family.has_active_subscription? ? 'Active' : 'Inactive'}"
