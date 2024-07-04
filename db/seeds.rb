admin_role = Role.find_or_create_by!(name: 'admin')
user_role = Role.find_or_create_by!(name: 'customer')
