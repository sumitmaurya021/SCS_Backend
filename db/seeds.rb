admin_role = Role.find_or_create_by!(name: 'admin')
user_role = Role.find_or_create_by!(name: 'customer')
devolog_role = Role.find_or_create_by!(name: 'devolog')


User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.username = 'admin'
  user.password = 'password'
  user.role = admin_role
end

User.find_or_create_by!(email: 'maurya@example.com') do |user|
  user.username = 'regular_user'
  user.password = 'password'
  user.role = user_role
end

User.find_or_create_by!(email: 'devolog@example.com') do |user|
  user.username = 'devolog'
  user.password = 'password'
  user.role = devolog_role
end
