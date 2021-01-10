Generate a list of users who belong to one LDAP group but not another.

This was written to report on the progress of a complicated group membership
migration.

This repo won't be maintained. It's published to share some code, maybe you can
use this as a starting point for your own reporting needs.

## Usage
1. Build the docker image
```
docker build -t missing-members .
```

2. Create a file called `env` with the following contents:
```
LDAP_HOST=<the ldap server address / hostname>
LDAP_USER=<ldap auth name, eg a samAccountName, cnommon name etc)
LDAP_PASSWORD=<ldap auth password>
OLD_GROUP=<The common name of the old group. Can be comma seperated>
NEW_GROUP=<The common name of the new group. Can be comma seperated>
```

3. Run the script
docker run --rm --env-file env missing-members

## Example

For the given `env` file:
```
LDAP_HOST=foo
LDAP_USER=foo
LDAP_PASSWORD=foo
OLD_GROUP=group-about-to-be-decomissioned
NEW_GROUP=Jenkins-User,Jenkins-Admin
```

running the script outputs:
```
92 users in the original group(s), 2 missing users (2% reduction)
  CN=John Smith,OU=Users,DC=example,DC=com
  CN=Jane Smith,OU=Users,DC=example,DC=com
```

Now you know that John and Jane do not belong to either Jenkins-User or
Jenkins-Admin group.
