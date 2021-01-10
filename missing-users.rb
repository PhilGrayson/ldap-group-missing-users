# frozen_string_literal: true

require 'net/ldap'

def main
  validate_env_vars

  old_members = memberof_search(ldap, ENV['OLD_GROUP'])
  new_members = memberof_search(ldap, ENV['NEW_GROUP'])

  missing = old_members.reject do |old_member|
    old_member = old_member.first(:dn)
    new_members.find { |new_member| new_member.first(:dn) == old_member }
  end

  percent_missing = (missing.length.to_f / old_members.length) * 100
  fmt = "%d users in the original group(s), %d missing users (%0.f%% reduction)\n"
  puts format(fmt, old_members.length, missing.length, percent_missing)

  puts missing.collect { |it| it.first(:dn) }.join("\n")
end

def validate_env_vars
  required_env_vars = {
    LDAP_HOST: 'ldap server adddress',
    LDAP_USER: 'ldap auth name',
    LDAP_PASSWORD: 'ldap auth password',
    OLD_GROUP: 'The common name of the old group. Can be comma seperated',
    NEW_GROUP: 'The common name of the new group. Can be comma seperated'
  }

  missing_env_vars = required_env_vars.keys.reject { |env| ENV[env.to_s] }

  return if missing_env_vars.empty?

  warn 'The following environment variables are missing:'
  missing_env_vars.each do |env|
    warn "#{env} - #{required_env_vars[env]}"
  end
  warn 'Exiting...'
  exit 1
end

def ldap
  ldap = Net::LDAP.new(
    host: ENV['LDAP_HOST'],
    base: ENV['LDAP_BASE'],
    auth: {
      method: :simple,
      username: ENV['LDAP_USER'],
      password: ENV['LDAP_PASSWORD']
    },
    encryption: {
      method: :start_tls
    }
  )

  return ldap if ldap.bind

  warn ldap.get_operation_result.to_s
  warn 'Exiting...'
end

def group_cn_to_dn(ldap, groups)
  search  = groups.collect { |group| "(cn=#{group})" }.join('')
  search  = "(&(objectCategory=Group) (|#{search}))"
  results = ldap.search(
    filter: Net::LDAP::Filter.construct(search)
  )

  validate_cn_to_dn(groups, results)

  results.collect { |res| res.first(:dn) }
end

def validate_cn_to_dn(input, output)
  return if input.size == output.size

  found_cns = input.find_all do |cn|
    output.find { |res| res.first(:cn) == cn }
  end

  missing_cns = (input - found_cns).join(', ')
  warn "Could not find the following group(s): '#{missing_cns}'."
  warn 'Exiting...'
  exit 1
end

def memberof_search(ldap, group_cns)
  group_cns = group_cns.split(',')
  search = group_cn_to_dn(ldap, group_cns).collect do |dn|
    "(memberOf:1.2.840.113556.1.4.1941:=#{dn})"
  end
  search = search.join('')

  ldap.search(
    filter: Net::LDAP::Filter.construct("(&(objectCategory=User)(|#{search}))"),
    attributes: %i[dn cn memberof]
  )
end

# call the entry point
main
