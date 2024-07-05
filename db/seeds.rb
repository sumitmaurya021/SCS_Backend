admin_role = Role.find_or_create_by!(name: 'admin')
user_role = Role.find_or_create_by!(name: 'customer')


User.create!(email: 'admin@gmail.com', username: 'adminscs123', password: 'password', role: admin_role)
